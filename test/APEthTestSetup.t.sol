// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
/* solhint-disable func-name-mixedcase */

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {APETH} from "../src/APETH.sol";
import {APETHV2} from "../src/APETHV2.sol";
import {APEthEarlyDeposits} from "../src/APEthEarlyDeposits.sol";
import {APETHWithdrawalQueueTicket} from "../src/APETHWithdrawalQueueTicket.sol";
import {DeployProxy} from "../script/deployToken.s.sol";
import {UpgradeProxy} from "../script/upgradeProxy.s.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {MockSsvNetwork} from "./mocks/MockSsvNetwork.sol";
import {IMockEigenPodManager} from "./mocks/MockEigenPodManager.sol";
import {IMockEigenPod} from "./mocks/MockEigenPod.sol";
import {IMockDelegationManager} from "./mocks/MockDelegationManager.sol";
// import {IAPEthPodWrapper} from "../src/interfaces/IAPEthPodWrapper.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Create2} from "@openzeppelin-contracts/utils/Create2.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "@eigenlayer-contracts/interfaces/IEigenPodManager.sol";
import {ProxyConfig, ScriptBase} from "../script/scriptBase.s.sol";
import {DeployWithdrawalQueue} from "../script/deployWithdrawalQueue.s.sol";
import {IAPETHWithdrawalQueueTicket} from "../src/interfaces/IAPETHWithdrawalQueueTicket.sol";
import {UpgradeProxy} from "../script/upgradeProxy.s.sol";

contract APEthTestSetup is Test {
    APETH public APEthV1;
    APETHV2 public APEth;
    APEthEarlyDeposits public earlyDeposits;
    APETHWithdrawalQueueTicket public withdrawalQueueTicket;
    // IAPEthPodWrapper public wrapper;

    address public owner;
    address public newOwner;

    address public alice;
    address public bob;

    address public staker;
    address public upgrader;

    ProxyConfig public proxyConfig;

    // address public podWrapper;

    bytes32 public constant ETH_STAKER = keccak256("ETH_STAKER");
    bytes32 public constant EARLY_ACCESS = keccak256("EARLY_ACCESS");
    bytes32 public constant UPGRADER = keccak256("UPGRADER");
    bytes32 public constant MISCELLANEOUS = keccak256("MISCELLANEOUS");
    bytes32 public constant SSV_NETWORK_ADMIN = keccak256("SSV_NETWORK_ADMIN");
    bytes32 public constant DELEGATION_MANAGER_ADMIN = keccak256("DELEGATION_MANAGER_ADMIN");
    bytes32 public constant EIGEN_POD_ADMIN = keccak256("EIGEN_POD_ADMIN");
    bytes32 public constant EIGEN_POD_MANAGER_ADMIN = keccak256("EIGEN_POD_MANAGER_ADMIN");

    //set bool to "true" when fresh keys are added, set to "false" to kill "reconstructed DepositData does not match supplied deposit_data_root"
    bool public workingKeys = false;

    bytes _pubKey =
        hex"aed26c6b7e0e2cc2efeae9c96611c3de6b982610e3be4bda9ac26fe8aea53276201b3e45dbc242bb24af7fb10fc12196";
    bytes _signature =
        hex"b45314f927f2344883a59b2a4c50af9260cb0c716e11b8954d1e00225bdd71a9dfc2bb6ad3d2e71159fa994ab1c3f49f0f78754ed94bd959457072bf4efbf4ff6b36456037d922c6173fb3ed24d21970ed61160b1605ecc7d6e35685cdd1aeaa";
    bytes32 _deposit_data_root = 0x7a71bc4430915cd6308a2b0e8bd18c91b8f8b9db13fd6d70101e1b53a4018dd0;

    bytes _pubKey2 =
        hex"91bebd77cd834b056ff242331dfcd3baecf3b89fcba6d866860a7ace128fb204af9b892cc84dd2d4eb933f6f8d0499b1";
    bytes _signature2 =
        hex"8c0422c68f58930b12082da0bf2b72372a2092e4be42c461cb7a686d7969093240929c6313846409d2a8c481fd3513ec042da0ed7ffeedb98d0ee611aff2bd304214c5edb2d5f064ef7d3b282612eb1a083ecee5054f7d209ad86773aeab140a";
    bytes32 _deposit_data_root2 = 0x79c26a0095560c824e3ba2674f788ef32f3deaf4dab89ee8040eab31855a25f9;

    bytes _pubKey3 =
        hex"b6ee6088e5b1dca8a7013f702140ab1f4825d349b20f8c4ba8436af36814dfb3309c13d7423898f60c5e332655a54f17";
    bytes _signature3 =
        hex"a96e640ffdc0173ce037297440449d261621d2fe247e863d0cac73af879b99ed52944ddda74282326f5579ff6cdf6cb8041e0c0c1d1f722b6021a227958171b4168924f1efa955f12ae4072359b45406c3a1867424179b8e8812e5a9f478dfd5";
    bytes32 _deposit_data_root3 = 0xa1b2ae2fcef94c75295b822eafadd7a38ebeaf30cfd9fc048f52ab281c4401b8;

    // // for multi pods
    // bytes _signature_M =
    //     hex"b52516870e1885a3601dd55af8dca27acd38524e504fab886ea9f95130fc9192e8280caf29176e64618ad880025f24ff1533899ef872e812beeb7f53206a35e46cff846b0af42516c0461a8390cdecd1410cb4518addce68f059e951943852a1";
    // bytes32 _deposit_data_root_M = 0x47e8c33776fa9aff7ea0df006918cf9447052bebd6bcabe458ae62dd45fc7b1c;

    // bytes _signature2_M =
    //     hex"b77c47461ff4d461213ccaaffdb0c89f478ff0e3c282fccbd048fc8ff01b16d1dc6b8860f1804780a686efcd09ab29d60a127cd371fc755a0245d4769b3de68c624c9f0676954aa348dbae89e7d585b20a88deeb347f8f8a23208595cbed8c1b";
    // bytes32 _deposit_data_root2_M = 0xc9d6958d532b2f485239dcc1f4136a108fe216aa7b5d7b0d1a383bc816865877;

    // bytes _signature3_M =
    //     hex"b6a2fb523cb9f95de16b50ceff622b09e67a26475a30ec660094f43b6b12fbd7a364d72e2507344ec39c4152d5bff8080b6cbaf1c9bbd71d5d0e8b4608658866ff2f51ea5ef2413a8c76e8da73544a2a8c505f4aaa15c7ef9e10c72ac5cf84d7";
    // bytes32 _deposit_data_root3_M = 0xf866ff75b93b664479a458297e95c9834c75c26275d46dd0953932a9fb4e5d32;

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
        // Define a new owner address for upgrade tests
        newOwner = address(1);

        DeployProxy deployProxy = new DeployProxy();
        DeployWithdrawalQueue deployWithdrawalQueue = new DeployWithdrawalQueue();
        proxyConfig.admin = owner;
        proxyConfig = new ScriptBase().getConfig(proxyConfig);
        APEthV1 = deployProxy.run(proxyConfig);
        UpgradeProxy upgradeProxy = new UpgradeProxy();

        vm.startPrank(owner);
        APEthV1.grantRole(ETH_STAKER, staker);
        APEthV1.grantRole(UPGRADER, upgrader);
        withdrawalQueueTicket = deployWithdrawalQueue.run(proxyConfig);

        vm.stopPrank();
        upgradeProxy.run(address(APEthV1), upgrader, IAPETHWithdrawalQueueTicket(address(withdrawalQueueTicket)));
        APEth = APETHV2(payable(address(APEthV1)));
    }

    modifier mintAlice(uint256 amount) {
        vm.prank(owner);
        APEth.grantRole(EARLY_ACCESS, alice);
        uint256 cap = proxyConfig.initialCap;
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

    modifier mintBob(uint256 amount) {
        vm.prank(owner);
        APEth.grantRole(EARLY_ACCESS, bob);
        uint256 cap = proxyConfig.initialCap - address(APEth).balance;
        uint256 bobBalance = _calculateAmountLessFee(amount);
        if (amount > cap) {
            bobBalance = 0;
            vm.expectRevert(); //APETH__CAP_REACHED()
        }
        hoax(bob);
        APEth.mint{value: amount}();
        assertEq(APEth.balanceOf(bob), bobBalance);
        _;
    }

    // modifier deployPods(uint256 numberOfPods) {
    //     vm.startPrank(staker);
    //     for(uint256 i; i < numberOfPods; i++) {
    //         APEth.deployPod();
    //         (address podAddy,) = APEth.getPodAddress(i + 1);
    //         console.log("pod number: ", i + 1);
    //         console.log("pod address: ", podAddy);
    //     }
    //     vm.stopPrank();
    //     (, podWrapper) = APEth.getPodAddress(numberOfPods);
    //     wrapper = IAPEthPodWrapper(podWrapper);
    //     _;
    // }

    //internal functions
    function _calculateFee(uint256 amount) internal view returns (uint256) {
        return (amount * proxyConfig.feeAmount) / 1e6;
    }

    function _calculateAmountLessFee(uint256 amount) internal view returns (uint256) {
        return (amount - _calculateFee(amount));
    }
}
