// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
/* solhint-disable func-name-mixedcase */

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Deploy, APETHV2} from "../script/Deploy.s.sol";

import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {MockSsvNetwork} from "./mocks/MockSsvNetwork.sol";
import {IMockEigenPodManager} from "./mocks/MockEigenPodManager.sol";
import {IMockEigenPod} from "./mocks/MockEigenPod.sol";
import {IMockDelegationManager} from "./mocks/MockDelegationManager.sol";

contract APEthTestSetup is Test, Deploy {
    address public newOwner;

    address public alice;
    address public bob;
    address public charlie;
    address public david;
    uint256 cap = type(uint256).max; // assuming no cap for this version
    uint256 startingApethBalance;
    uint256 startingTotalSupply;
    uint256 startingEthPerApeth;

    uint256[] ticOne = new uint256[](1);
    uint256[] ticTwo = new uint256[](1);
    uint256[] ticBoth = new uint256[](2);

    //set bool to "true" when fresh keys are added, set to "false" to kill "reconstructed DepositData does not match supplied deposit_data_root"
    bool public workingKeys = true;

    bytes _pubKey =
        hex"aed26c6b7e0e2cc2efeae9c96611c3de6b982610e3be4bda9ac26fe8aea53276201b3e45dbc242bb24af7fb10fc12196";
    bytes _signature =
        hex"ace9b7dada19911900abee07477915ffd922af490b34d479f70bd8fe163c2d9616f047e1edad2901b1b75801d4b4cfbf15d7ca425cd5877d24ac45e6d1c7378d00bf1d921ba99c4fc4f0b8b1c506e75c57c1876884ffec3e46bb7408ddb26adc";
    bytes32 _deposit_data_root = 0x15320abc0a129b6a3c64357142261f337aad9ddf1d6028e6bb2374e30c2d1b88;

    bytes _pubKey2 =
        hex"91bebd77cd834b056ff242331dfcd3baecf3b89fcba6d866860a7ace128fb204af9b892cc84dd2d4eb933f6f8d0499b1";
    bytes _signature2 =
        hex"afbef8c11a7cbd09234a305809317e647041cf318a75b4effda7ea7656872d2cf88076ddbc86baedfe1aa9a85ef73b270351f3b61f2fd337c421fbc3e67d95bf13ce8c4dc410f66540af059f1b659913ae5744ae3d22b51316bbaf90b0c4d093";
    bytes32 _deposit_data_root2 = 0x39e092c8596cef2689b2f9f2ceec43dddcdec6f07bd8fa488f42dd8a50e0efca;

    bytes _pubKey3 =
        hex"b6ee6088e5b1dca8a7013f702140ab1f4825d349b20f8c4ba8436af36814dfb3309c13d7423898f60c5e332655a54f17";
    bytes _signature3 =
        hex"906ba542cceac07cec2b67918b5bc0203fe10d9d673edf384ed7811ef8afcd6fec8a05fe421b28d612e2986afe0b1c1f0eb5597ca8e275e4b3ae867c398f0a0e05b632ff715820b653002af62c9a843dfa674357a10e4c915373cacaf284eebd";
    bytes32 _deposit_data_root3 = 0x054c04b2dc91b1859166cda618f6ec0665c867afd2d8299291b4f884319558b1;

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
        if (block.chainid != 1) {
            revert("RUN ON FORKED MAINNET ONLY: forge test -f mainnet");
        }
        alice = vm.addr(1);
        bob = vm.addr(2);
        charlie = vm.addr(4);
        david = vm.addr(5);
        newOwner = vm.addr(3);
        run();
        vm.deal(address(APEth), 0); // set balance to 0 for testing

        startingApethBalance = address(APEth).balance;
        startingTotalSupply = APEth.totalSupply();
        startingEthPerApeth = APEth.ethPerAPEth();
        ticOne[0] = 1;
        ticTwo[0] = 2;
        ticBoth[0] = 1;
        ticBoth[1] = 2;
    }

    modifier mintAlice(uint256 amount) {
        uint256 aliceBalance = _calculateAmountLessFee(amount);
        if (amount > cap) {
            aliceBalance = 0;
            vm.expectRevert(); //APETH__CAP_REACHED()
        }
        hoax(alice);
        APEth.mint{value: amount}();
        assertApproxEqAbs(APEth.balanceOf(alice), aliceBalance, 3);
        if (amount > cap) {
            vm.expectRevert(); //APETH__CAP_REACHED()
        }
        if (APEth.balanceOf(bob) == 0) assertEq(address(APEth).balance, amount + startingApethBalance);
        _;
    }

    modifier mintBob(uint256 amount) {
        uint256 bobBalance = _calculateAmountLessFee(amount) + APEth.balanceOf(bob);
        if (amount > cap) {
            bobBalance = 0;
            vm.expectRevert(); //APETH__CAP_REACHED()
        }
        hoax(bob);
        APEth.mint{value: amount}();
        assertApproxEqAbs(APEth.balanceOf(bob), bobBalance, 3);
        _;
    }

    function mintBob2(uint256 amount) public mintBob(amount) {}

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
        return (amount * feeAmount) / 1e6;
    }

    function _calculateAmountLessFee(uint256 amount) internal view returns (uint256) {
        uint256 ethPerAPEth = APEth.ethPerAPEth();
        return ((amount - _calculateFee(amount)) * 1 ether / ethPerAPEth);
    }

    function _stake1() internal {
        if (!workingKeys && block.chainid != 31337) {
            vm.expectRevert("DepositContract: reconstructed DepositData does not match supplied deposit_data_root");
        }
        vm.prank(staker);
        APEth.stake(_pubKey, _signature, _deposit_data_root);
    }

    function _stake2() internal {
        if (!workingKeys && block.chainid != 31337) {
            vm.expectRevert("DepositContract: reconstructed DepositData does not match supplied deposit_data_root");
        }
        vm.prank(staker);
        APEth.stake(_pubKey2, _signature2, _deposit_data_root2);
    }

    function _stake3() internal {
        if (!workingKeys && block.chainid != 31337) {
            vm.expectRevert("DepositContract: reconstructed DepositData does not match supplied deposit_data_root");
        }
        vm.prank(staker);
        APEth.stake(_pubKey3, _signature3, _deposit_data_root3);
    }
}
