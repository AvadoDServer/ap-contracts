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
    IMockDelegationManager
} from "./APEthTestSetup.t.sol";

contract APETHTestRevert is APEthTestSetup {
    function test_Revert_Stake_NotEnoughEth() public mintAlice(5) {
        vm.prank(staker);
        vm.expectRevert(0x82deecdf); //"APETH__NOT_ENOUGH_ETH()"
        APEth.stake(  _pubKey, _signature, _deposit_data_root);
    }

    function test_Revert_Stake_NotOwner() public mintAlice(32 ether) {
        vm.prank(vm.addr(69));
        vm.expectRevert(); // "OwnableUnauthorizedAccount(0x1326324f5A9fb193409E10006e4EA41b970Df321)"
        APEth.stake(_pubKey, _signature, _deposit_data_root);
    }

    function test_Revert_ERC20Call_NotOwner() public {
        ERC20Mock mockCoin = new ERC20Mock();
        mockCoin.mint(address(APEth), 1 ether);
        vm.prank(vm.addr(69));
        vm.expectRevert(); // "OwnableUnauthorizedAccount(0x1326324f5A9fb193409E10006e4EA41b970Df321)"
        APEth.transferToken(address(mockCoin), alice, 1 ether);
    }

    function test_Revert_SSVCall_NotOwner() public {
        vm.prank(vm.addr(69));
        vm.expectRevert(); // "OwnableUnauthorizedAccount(0x1326324f5A9fb193409E10006e4EA41b970Df321)"
        APEth.callSSVNetwork(
            abi.encodeWithSelector(bytes4(keccak256("setFeeRecipientAddress(address)")), address(APEth))
        );
    }

    function test_Revert_SSVCall_BadCall() public {
        vm.prank(admin);
        vm.expectRevert("Call failed");
        APEth.callSSVNetwork(
            abi.encodeWithSelector(bytes4(keccak256("someFunctionThatDoesNotExist(address)")), address(APEth))
        );
    }

    function test_Revert_EigenPodManagerCall_NotOwner() public {
        vm.prank(vm.addr(69));
        vm.expectRevert(); // "OwnableUnauthorizedAccount(0x1326324f5A9fb193409E10006e4EA41b970Df321)"
        APEth.callEigenPodManager(abi.encodeWithSelector(IMockEigenPodManager.getPod.selector, address(APEth)));
    }

    function test_Revert_EigenPodManagerCall_BadCall() public {
        vm.prank(admin);
        vm.expectRevert("Call failed");
        APEth.callEigenPodManager(
            abi.encodeWithSelector(bytes4(keccak256("someFunctionThatDoesNotExist(address)")), address(APEth))
        );
    }

    function test_Revert_DelegationManagerCall_NotOwner() public {
        vm.prank(vm.addr(69));
        vm.expectRevert(); // "OwnableUnauthorizedAccount(0x1326324f5A9fb193409E10006e4EA41b970Df321)"
        APEth.callDelegationManager(abi.encodeWithSelector(IMockDelegationManager.undelegate.selector, address(APEth)),0);
    }

    function test_Revert_DelegationManagerCall_BadCall() public {
        vm.prank(admin);
        vm.expectRevert("Call failed");
        APEth.callDelegationManager(
            abi.encodeWithSelector(bytes4(keccak256("someFunctionThatDoesNotExist(address)")), address(APEth)),0
        );
    }

    function test_Revert_EigenPodCall_NotOwner() public {
        vm.prank(vm.addr(69));
        vm.expectRevert(); // "OwnableUnauthorizedAccount(0x1326324f5A9fb193409E10006e4EA41b970Df321)"
        APEth.callEigenPod(abi.encodeWithSelector(IMockEigenPod.podOwner.selector));
    }

    function test_Revert_EigenPodCall_BadCall() public {
        vm.prank(admin);
        vm.expectRevert("Call failed");
        APEth.callEigenPod(abi.encodeWithSelector(bytes4(keccak256("someFunctionThatDoesNotExist()"))));
    }
}