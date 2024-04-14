// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {APETH} from "../src/APETH.sol";
import {APETHV2} from "../src/APETHV2.sol";
import {APEthStorage} from "../src/APEthStorage.sol";
import {DeployStorageContract} from "../script/deployStorage.s.sol";
import {DeployTokenImplementation} from "../script/deployToken.s.sol";
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

    //set bool to 1 when fresh keys are added, set to 0 to kill "reconstructed DepositData does not match supplied deposit_data_root"
    bool workingKeys = false;

    bytes _pubKey =
        hex"aed26c6b7e0e2cc2efeae9c96611c3de6b982610e3be4bda9ac26fe8aea53276201b3e45dbc242bb24af7fb10fc12196";
    bytes _signature =
        hex"a0696aefce9cd401fab9641e66799bd7af8b338fabac11aa42e6a6036a4cb03e80364a17ba0aa97182077aa3ab9b3f5611f4e99d1e96baad569f34960425e13991c661ee957475c14e8dc1e77d3deb29f2fabca34c20332598cf43e4fd95ef5b";
    bytes32 _deposit_data_root = 0x0e88949943ac2da1b17b16e680a7d385f1e8598eb6ce434a6dcd992ef2bd4822;

    bytes _pubKey2 =
        hex"91bebd77cd834b056ff242331dfcd3baecf3b89fcba6d866860a7ace128fb204af9b892cc84dd2d4eb933f6f8d0499b1";
    bytes _signature2 =
        hex"b62e860ebdd5fa85e9a0c79fe8f9abcd4cdd58af4f05f0525a0c15ddb243946afac6a18528d2d226e75d957a9b7d5b99024d3976f1f2b7b482f86fcec9009a00ca03c7b253a7045280be2ab016b5e778805306299b5a370e6c63652010a3336a";
    bytes32 _deposit_data_root2 = 0xfdf0ad0bae5f3d8d4cd6f14323b00f535a82a6598699f1a088c2b114bae3e5a3;

    bytes _pubKey3 =
        hex"b6ee6088e5b1dca8a7013f702140ab1f4825d349b20f8c4ba8436af36814dfb3309c13d7423898f60c5e332655a54f17";
    bytes _signature3 =
        hex"9413c7e260ae520c4554eca2bb8fa646ea8661e907ad8cbe1dbf480ac5c8c5c8fc542af2fbc96bba57a07ed694c4a71506c4baf5333c31d4cf4cac3854083412496ac66d6cd9d0406e8fd955db0cc3fee6237970bb5a44044e706231a3cc562c";
    bytes32 _deposit_data_root3 = 0x2bd142f6d9de4e22badefcd5b350b78c93a8dd25552eb3a39b0381de1ec97c51;

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
        DeployTokenImplementation deployImplementation = new DeployTokenImplementation();

        storageContract = deployStorage.run(owner);
        (implementation, APEth) = deployImplementation.run(owner);
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
        vm.expectRevert(0xad5111f6); // "APEthStorage__MUST_SET_TO_0X0_FIRST()"
        storageContract.burnKeys();
        storageContract.setGuardian(address(0));
        storageContract.burnKeys();
        vm.expectRevert(0x7783a63d); // "APEthStorage__ACCOUNT_IS_NOT_GUARDIAN_OR_APETH()"
        storageContract.setUint(keccak256(abi.encodePacked("test.uint256")), 69);
    }

}
