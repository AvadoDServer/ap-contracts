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
    APETH public APEth;
    APETH public implementation;
    APEthStorage public storageContract;
    APEthEarlyDeposits public earlyDeposits;
    IAPEthPodWrapper public wrapper;

    address public owner;
    address public newOwner;

    address public alice;
    address public bob;

    address public staker;
    address public upgrader;
    address public admin;

    address public podWrapper;

    bytes32 public constant UPGRADER = keccak256("UPGRADER");
    bytes32 public constant ETH_STAKER = keccak256("ETH_STAKER");
    bytes32 public constant EARLY_ACCESS = keccak256("EARLY_ACCESS");
    bytes32 public constant ADMIN = keccak256("ADMIN");

    //set bool to "true" when fresh keys are added, set to "false" to kill "reconstructed DepositData does not match supplied deposit_data_root"
    bool public workingKeys = true;

    bytes _pubKey =
        hex"aed26c6b7e0e2cc2efeae9c96611c3de6b982610e3be4bda9ac26fe8aea53276201b3e45dbc242bb24af7fb10fc12196";
    bytes _signature =
        hex"b2268f33589dc5de5288c0f641ad0779ea2496d4f51eb35ee32987f5d06c02dcc6b3d71c1716fe58b42ae84f25ddfe9b13e5c4d61901d83990578064f0bc2b90a6cd797bb8e61bab5cd72b1931a5d4a7316562fd21f0c9f44c21f9823338557f";
    bytes32 _deposit_data_root = 0x88f65a4327907948ae8aa737bbdb7525a331592738462b347b8a859f79c7e765;

    bytes _pubKey2 =
        hex"91bebd77cd834b056ff242331dfcd3baecf3b89fcba6d866860a7ace128fb204af9b892cc84dd2d4eb933f6f8d0499b1";
    bytes _signature2 =
        hex"a64eddbbe678042bd68c0785718298a7aac21702446ec34dba7809d10586d5119c849f6932467828eff1a7734d83eacf03fef186215392d8ef3aa936717b138e2e02b36f7faf7ebb91e7e3f26e50fbc9f923a9daaa5e856423fc3f2d3ea88b46";
    bytes32 _deposit_data_root2 = 0x3bee4479fb00b4376f05148a85a2a1a38f1c4d104e51e35d9e1b95e7ecb5d3a9;

    bytes _pubKey3 =
        hex"b6ee6088e5b1dca8a7013f702140ab1f4825d349b20f8c4ba8436af36814dfb3309c13d7423898f60c5e332655a54f17";
    bytes _signature3 =
        hex"8f138d8c32323105736215da1f22387e666efd0f06d52abc06aee2fddab1294d7babb7ebd25a0411ba627d367faeb754060c6d6efe13ca2ff7901becaba277902f5351421b8b22d16558424ba0764ce2c239f56ce8f1f3cc81ca5e937521a19c";
    bytes32 _deposit_data_root3 = 0xa430705a6267c0349b80e65ae2fa6aeb7c9a195e4e7a68c08f0258c536a5e14f;

    // for multi pods
    bytes _signature_M =
        hex"a5fa0a709aa6608e8fe1c49e1e178469cb24917dbd22883bb53f8d3a5165c8d8fc7177b20300a97c3044412b4f5783d10bab81aa6ae31893300282f8c37a47fb8f1cd7071847e999efc9ffcdbf15ebaf08ac104aabe22333e1dfb7cfc4ae170d";
    bytes32 _deposit_data_root_M = 0x532a5a41046a0e94b60e99acb6bf01f16083d1e88b9c0c9a280c30a07b9257eb;

    bytes _signature2_M =
        hex"a5263ec8a183a0e27e8dcdd97fdc9993dde376289cc8b7ce6eef2d8fb66bf9ef27287ddcb0fb6bb57ed256755036b80f0b07a53afba56fdce4c9c9f70e95a14d1c41e65f44af1263305e70aafe0459c1ee05343588af6229da6c3d622d50cb92";
    bytes32 _deposit_data_root2_M = 0x8d8c04ce2bdfbc54f7d7d1b902af5429b52756521704dc4fd1edb2acceba2be6;

    bytes _signature3_M =
        hex"b6cb0629967dd138deb2b7bb5d52672284e52f3c6108eaf491f1985263e92c6fcf0b71bda31234a70f7bb0e0bcf8f9e31725069f14c1671935909f55dbe3e8c33dfe61428b02fb42c6675a10a3df704146e0a14e427ab28b54bfd79807afecd0";
    bytes32 _deposit_data_root3_M = 0x89f8bd52168c950246bbe20828feaf222b6a16eb2fa64cc1980e567919dda5e3;

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

    modifier deployPods(uint256 numberOfPods) {
        vm.startPrank(staker);
        for(uint256 i; i < numberOfPods; i++) {
            APEth.deployPod();
            // (address podAddy,) = APEth.getPodAddress(i + 1);
            // console.log("pod number: ", i + 1);
            // console.log("pod address: ", podAddy);
        }
        vm.stopPrank();
        (, podWrapper) = APEth.getPodAddress(numberOfPods);
        wrapper = IAPEthPodWrapper(podWrapper);
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
