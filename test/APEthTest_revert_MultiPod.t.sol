// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/* solhint-disable func-name-mixedcase */

import {
    APEthTestSetup,
    UpgradeProxy,
    APETHV2,
    ERC20Mock,
    MockSsvNetwork,
    IMockEigenPodManager,
    IMockEigenPod,
    IAPEthPodWrapper
} from "./APEthTestSetup.t.sol";

contract APETHTestRevertMultiPod is APEthTestSetup {
    function test_Revert_DeployPod_notStaker() public {
        vm.expectRevert();
        APEth.deployPod();
    }

    function test_Revert_Stake_NotEnoughEth_MultiPod() public mintAlice(5) deployPods(1) {
        vm.expectRevert(0x82deecdf); //"APETH__NOT_ENOUGH_ETH()"
        vm.prank(staker);
        APEth.stake(1, _pubKey, _signature, _deposit_data_root);
    }

    function test_Revert_Stake_NotOwner_MultiPod() public mintAlice(32 ether) deployPods(1) {
        vm.prank(vm.addr(69));
        vm.expectRevert(); // "OwnableUnauthorizedAccount(0x1326324f5A9fb193409E10006e4EA41b970Df321)"
        wrapper.stake(_pubKey, _signature, _deposit_data_root);
    }

    function test_Revert_ERC20Call_NotOwner_MultiPod() public deployPods(1) {
        ERC20Mock mockCoin = new ERC20Mock();
        mockCoin.mint(address(APEth), 1 ether);
        vm.prank(vm.addr(69));
        vm.expectRevert(); // "OwnableUnauthorizedAccount(0x1326324f5A9fb193409E10006e4EA41b970Df321)"
        APEth.transferToken(0, address(mockCoin), alice, 1 ether);
    }

    /* TODO: make these multiPod Tests
    function test_Revert_SSVCall_NotOwner() public {
        vm.prank(vm.addr(69));
        vm.expectRevert(); // "OwnableUnauthorizedAccount(0x1326324f5A9fb193409E10006e4EA41b970Df321)"
        APEth.callSSVNetwork(
            0, abi.encodeWithSelector(bytes4(keccak256("setFeeRecipientAddress(address)")), address(APEth))
        );
    }

    function test_Revert_SSVCall_BadCall() public {
        vm.prank(owner);
        APEth.grantRole(ADMIN, admin);
        vm.prank(admin);
        vm.expectRevert("Call failed");
        APEth.callSSVNetwork(
            0, abi.encodeWithSelector(bytes4(keccak256("someFunctionThatDoesNotExist(address)")), address(APEth))
        );
    }

    function test_Revert_EigenPodManagerCall_NotOwner() public {
        vm.prank(vm.addr(69));
        vm.expectRevert(); // "OwnableUnauthorizedAccount(0x1326324f5A9fb193409E10006e4EA41b970Df321)"
        APEth.callEigenPodManager(0, abi.encodeWithSelector(IMockEigenPodManager.getPod.selector, address(APEth)));
    }

    function test_Revert_EigenPodManagerCall_BadCall() public {
        vm.prank(owner);
        APEth.grantRole(ADMIN, admin);
        vm.prank(admin);
        vm.expectRevert("Call failed");
        APEth.callEigenPodManager(
            0, abi.encodeWithSelector(bytes4(keccak256("someFunctionThatDoesNotExist(address)")), address(APEth))
        );
    }

    function test_Revert_EigenPodCall_NotOwner() public {
        vm.prank(vm.addr(69));
        vm.expectRevert(); // "OwnableUnauthorizedAccount(0x1326324f5A9fb193409E10006e4EA41b970Df321)"
        APEth.callEigenPod(0, abi.encodeWithSelector(IMockEigenPod.podOwner.selector));
    }

    function test_Revert_EigenPodCall_BadCall() public {
        vm.prank(owner);
        APEth.grantRole(ADMIN, admin);
        vm.prank(admin);
        vm.expectRevert("Call failed");
        APEth.callEigenPod(0, abi.encodeWithSelector(bytes4(keccak256("someFunctionThatDoesNotExist()"))));
    }

    */
}
