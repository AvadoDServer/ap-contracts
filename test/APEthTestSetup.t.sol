// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/* solhint-disable func-name-mixedcase */

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {APETH} from "../src/APETH.sol";
import {APETHV2} from "../src/APETHV2.sol";
import {APEthStorage} from "../src/APEthStorage.sol";
import {APEthEarlyDeposits} from "../src/APEthEarlyDeposits.sol";
import {DeployStorageContract} from "../script/deployStorage.s.sol";
import {DeployProxy} from "../script/deployToken.s.sol";
import {UpgradeProxy} from "../script/upgradeProxy.s.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {MockSsvNetwork} from "./mocks/MockSsvNetwork.sol";
import {IMockEigenPodManager} from "./mocks/MockEigenPodManager.sol";
import {IMockEigenPod} from "./mocks/MockEigenPod.sol";
import {IAPEthPodWrapper} from "../src/interfaces/IAPEthPodWrapper.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Create2} from "@openzeppelin-contracts/utils/Create2.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "@eigenlayer-contracts/interfaces/IEigenPodManager.sol";

contract APEthTestSetup is Test {
    APETH APEth;
    APETH implementation;
    APEthStorage storageContract;
    APEthEarlyDeposits earlyDeposits;
    address owner;
    address newOwner;

    address alice;
    address bob;

    address staker;
    address upgrader;
    address admin;

    bytes32 public constant UPGRADER = keccak256("UPGRADER");
    bytes32 public constant ETH_STAKER = keccak256("ETH_STAKER");
    bytes32 public constant EARLY_ACCESS = keccak256("EARLY_ACCESS");
    bytes32 public constant ADMIN = keccak256("ADMIN");

    //set bool to "true" when fresh keys are added, set to "false" to kill "reconstructed DepositData does not match supplied deposit_data_root"
    bool workingKeys = false;

    bytes _pubKey =
        hex"aed26c6b7e0e2cc2efeae9c96611c3de6b982610e3be4bda9ac26fe8aea53276201b3e45dbc242bb24af7fb10fc12196";
    bytes _signature =
        hex"896a621b4e4fad8d14108111c45141370572882362f40b4a6c4c9bce3f1b13c9e59774a270198448b4e535638916d71d0edbe18a74bc9b087972dbf60c14ef214f77fac423848d75f377ae1214cc0dcb09e2b1f3d2da60e74ac9540d8c6b62c7";
    bytes32 _deposit_data_root = 0x955de0af387a6cc447bb8f2b5554c51245e2239426c7a251381f3175bf99769a;

    bytes _pubKey2 =
        hex"91bebd77cd834b056ff242331dfcd3baecf3b89fcba6d866860a7ace128fb204af9b892cc84dd2d4eb933f6f8d0499b1";
    bytes _signature2 =
        hex"b00761c3426f8df64b5f048edc547b6478e947261ca9a9fbd88afdbbb7463f430fbf46a276d392c39113bd05b034f21905958415f561ca842a3b094a52d8d5651c8866b6ac4a6a37b3ac1fd5bcc1a483966127a30e41eafed621d9aa48734553";
    bytes32 _deposit_data_root2 = 0x657fe2c0d7a9ea7cc56cdad00edd249f4bf7a9f48f845b4f2d4bbcd5f241ca46;

    bytes _pubKey3 =
        hex"b6ee6088e5b1dca8a7013f702140ab1f4825d349b20f8c4ba8436af36814dfb3309c13d7423898f60c5e332655a54f17";
    bytes _signature3 =
        hex"96dcbfd6aa228d56f81cc2ebb0145db72c12a295d531c37f955bb1ab6dfcd0f8fe8ecb0f134cd026fa32520d0fd6ef100e375f697eb0ee441d47a54cdd0a5fcd5598eab5f8d35fd8fdd812a6f3897a8dd972183f1b5a5fc9aa000051e6106376";
    bytes32 _deposit_data_root3 = 0x02d2bd6e36896af49cebf39e52e6a0ae926dfaa8dfbd70cad4188e3aa12e3bae;

    // Set up the test environment before running tests
    function setUp() public {
        console.log("chain ID: ", block.chainid);
        // Define the owner and alice addresses
        owner = vm.addr(1);
        console.log("owner", owner);
        alice = vm.addr(2);
        bob = vm.addr(3);
        staker = vm.addr(4);
        upgrader = vm.addr(5);
        admin = vm.addr(6);
        // Define a new owner address for upgrade tests
        newOwner = address(1);

        DeployStorageContract deployStorage = new DeployStorageContract();
        DeployProxy deployProxy = new DeployProxy();

        (storageContract, implementation) = deployStorage.run(owner);
        (APEth) = deployProxy.run(owner, address(storageContract), address(implementation));
        vm.startPrank(owner);
        APEth.grantRole(ETH_STAKER, staker);
        APEth.grantRole(UPGRADER, upgrader);
        APEth.grantRole(ADMIN, admin);
        vm.stopPrank();
    }

    modifier mintAlice(uint256 amount) {
        vm.prank(owner);
        APEth.grantRole(EARLY_ACCESS, alice);
        uint256 cap = storageContract.getUint(keccak256(abi.encodePacked("cap.Amount")));
        uint256 aliceBalance = _calculateAmountLessFee(amount);
        if (amount > cap) {
            aliceBalance = 0;
            vm.expectRevert(); //APETH__CAP_REACHED()
        }
        hoax(alice);
        APEth.mint{value: amount}();
        assertEq(APEth.balanceOf(alice), aliceBalance);
        if (amount > cap) {
            vm.expectRevert(); //APETH__CAP_REACHED()
        }
        assertEq(address(APEth).balance, amount);
        _;
    }

    //internal functions
    function _calculateFee(uint256 amount) internal view returns (uint256) {
        uint256 fee = amount * storageContract.getUint(keccak256(abi.encodePacked("fee.Amount"))) / 100000;
        return fee;
    }

    function _calculateAmountLessFee(uint256 amount) internal view returns (uint256) {
        return (amount - _calculateFee(amount));
    }
}
