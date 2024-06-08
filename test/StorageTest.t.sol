// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {APETH} from "../src/APETH.sol";
import {APETHV2} from "../src/APETHV2.sol";
import {APEthStorage} from "../src/APEthStorage.sol";
import {DeployStorageContract} from "../script/deployStorage.s.sol";
import {DeployProxy} from "../script/deployToken.s.sol";
import {UpgradeProxy} from "../script/upgradeProxy.s.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {MockSsvNetwork} from "./mocks/MockSsvNetwork.sol";
import {IMockEigenPodManager} from "./mocks/MockEigenPodManager.sol";
import {IMockEigenPod} from "./mocks/MockEigenPod.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Create2} from "@openzeppelin-contracts/utils/Create2.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "@eigenlayer-contracts/interfaces/IEigenPodManager.sol";

contract StorageTest is Test {
    APETH APEth;
    APETH implementation;
    APEthStorage storageContract;
    address owner;
    address newOwner;

    address alice;
    address bob;

    // Set up the test environment before running tests
    function setUp() public {
        // Define the owner and alice addresses
        owner = vm.addr(1);
        console.log("owner", owner);
        alice = vm.addr(2);
        bob = vm.addr(3);
        // Define a new owner address for upgrade tests
        newOwner = address(1);

        DeployStorageContract deployStorage = new DeployStorageContract();
        DeployProxy deployProxy = new DeployProxy();

        (storageContract, implementation) = deployStorage.run(owner);
        (APEth,) = deployProxy.run(owner, address(storageContract), address(implementation));
    }

    //this is mainly to get the coverage for the contract o 100%
    function testStorage() public {
        vm.startPrank(storageContract.getGuardian());
        //uint
        storageContract.setUint(keccak256(abi.encodePacked("test.uint256")), 69);
        assertEq(storageContract.getUint(keccak256(abi.encodePacked("test.uint256"))), 69);
        storageContract.subUint(keccak256(abi.encodePacked("test.uint256")), 1);
        assertEq(storageContract.getUint(keccak256(abi.encodePacked("test.uint256"))), 68);
        storageContract.addUint(keccak256(abi.encodePacked("test.uint256")), 1);
        assertEq(storageContract.getUint(keccak256(abi.encodePacked("test.uint256"))), 69);
        storageContract.deleteUint(keccak256(abi.encodePacked("test.uint256")));
        assertEq(storageContract.getUint(keccak256(abi.encodePacked("test.uint256"))), 0);
        //bool
        storageContract.setBool(keccak256(abi.encodePacked("test.bool")), true);
        assertEq(storageContract.getBool(keccak256(abi.encodePacked("test.bool"))), true);
        storageContract.deleteBool(keccak256(abi.encodePacked("test.bool")));
        assertEq(storageContract.getBool(keccak256(abi.encodePacked("test.bool"))), false);
        //address
        storageContract.setAddress(keccak256(abi.encodePacked("test.address")), alice);
        assertEq(storageContract.getAddress(keccak256(abi.encodePacked("test.address"))), alice);
        storageContract.deleteAddress(keccak256(abi.encodePacked("test.address")));
        assertEq(storageContract.getAddress(keccak256(abi.encodePacked("test.address"))), address(0));
        //apEth
        assertEq(address(APEth), storageContract.getAPEth());
        vm.expectRevert(); // "APEthStorage__CAN_ONLY_BE_SET_ONCE()"
        storageContract.setAPEth(alice);
        //guardian
        storageContract.setGuardian(alice);
        vm.expectRevert(0xe3c402fb); // "APEthStorage__MUST_COME_FROM_NEW_GUARDIAN()"
        storageContract.confirmGuardian();
        vm.stopPrank();
        vm.startPrank(alice);
        storageContract.confirmGuardian();
        assertEq(storageContract.getGuardian(), alice);
        vm.expectRevert(0x840d41b1); // "APEthStorage__MUST_SET_TO_0Xdead_FIRST()"
        storageContract.burnKeys();
        storageContract.setGuardian(address(0xdead));
        storageContract.burnKeys();
        vm.expectRevert(0x7783a63d); // "APEthStorage__ACCOUNT_IS_NOT_GUARDIAN_OR_APETH()"
        storageContract.setUint(keccak256(abi.encodePacked("test.uint256")), 69);
    }
}
