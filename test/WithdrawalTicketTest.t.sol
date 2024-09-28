// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/* solhint-disable func-name-mixedcase */

import {
    APEthTestSetup,
    // UpgradeProxy,
    // APETHV2,
    // ERC20Mock,
    // MockSsvNetwork,
    // IMockEigenPodManager,
    // IMockEigenPod,
    // IMockDelegationManager,
    console
} from "./APEthTestSetup.t.sol";

contract WithdrawalTicketTest is APEthTestSetup {
    function test_SimpleWithdrawal() public mintAlice(10 ether) {
        // Send eth to contract to increase balance
        payable(address(APEth)).transfer(1 ether);
        assertEq(address(APEth).balance, 11 ether);
        //check eth per apeth
        uint256 ethPerAPEth = 11 ether / 10;
        assertEq(APEth.ethPerAPEth(), ethPerAPEth);
        uint256 aliceApethBalance = APEth.balanceOf(alice);
        uint256 aliceEthWithdrawalAmountExpected = aliceApethBalance * ethPerAPEth / 1 ether;
        uint256 aliceEthBalanceBefore = alice.balance;
        vm.prank(alice);
        APEth.withdraw(aliceApethBalance);
        uint256 aliceEthBalanceAfter = alice.balance;
        uint256 aliceEthWithdrawalAmount = aliceEthBalanceAfter - aliceEthBalanceBefore;

        assertEq(APEth.balanceOf(alice), 0);
        assertEq(aliceEthWithdrawalAmount, aliceEthWithdrawalAmountExpected);
    }

    function test_multipleWithdrawals() public mintAlice(10 ether) mintBob(10 ether) {
        // Send eth to contract to increase balance
        payable(address(APEth)).transfer(1 ether);
        assertEq(address(APEth).balance, 21 ether);
        //check eth per apeth
        uint256 ethPerAPEth = 21 ether / 20;
        assertEq(APEth.ethPerAPEth(), ethPerAPEth);
        // alice withdrawal
        uint256 aliceApethBalance = APEth.balanceOf(alice);
        uint256 aliceEthWithdrawalAmountExpected = aliceApethBalance * ethPerAPEth / 1 ether;
        uint256 aliceEthBalanceBefore = alice.balance;
        vm.prank(alice);
        APEth.withdraw(aliceApethBalance);
        uint256 aliceEthBalanceAfter = alice.balance;
        uint256 aliceEthWithdrawalAmount = aliceEthBalanceAfter - aliceEthBalanceBefore;
        assertEq(APEth.balanceOf(alice), 0);
        assertEq(aliceEthWithdrawalAmount, aliceEthWithdrawalAmountExpected);
        // bob withdrawal
        uint256 bobApethBalance = APEth.balanceOf(bob);
        uint256 bobEthWithdrawalAmountExpected = bobApethBalance * ethPerAPEth / 1 ether;
        uint256 bobEthBalanceBefore = bob.balance;
        vm.prank(bob);
        APEth.withdraw(bobApethBalance);
        uint256 bobEthBalanceAfter = bob.balance;
        uint256 bobEthWithdrawalAmount = bobEthBalanceAfter - bobEthBalanceBefore;
        assertEq(APEth.balanceOf(bob), 0);
        assertEq(bobEthWithdrawalAmount, bobEthWithdrawalAmountExpected);
    }

    function test_withdrawalWithTicket() public mintAlice(30 ether) mintBob(2 ether) {
        assertEq(address(APEth).balance, 32 ether);
        if (!workingKeys && block.chainid != 31337) {
            APEth.fakeStake(); // TODO: remove this line when we have working keys aslo un-comment the line below
            vm.expectRevert(
                /*"DepositContract: reconstructed DepositData does not match supplied deposit_data_root"*/
            );
        }
        vm.prank(staker);
        APEth.stake(_pubKey, _signature, _deposit_data_root);
        /*if (workingKeys) {*/
        assertEq(address(APEth).balance, 0 ether);
        uint256 aliceApethBalance = APEth.balanceOf(alice);
        vm.prank(alice);
        APEth.withdraw(15 ether);
        assertEq(APEth.withdrawalQueue(), 15 ether);
        assertEq(aliceApethBalance - 15 ether, APEth.balanceOf(alice));
        assertEq(withdrawalQueueTicket.ownerOf(1), alice);
        assertEq(withdrawalQueueTicket.tokenIdToExitQueueExitAmount(1), 15 ether);
        assertGt(withdrawalQueueTicket.tokenIdToExitQueueTimestamp(1), block.timestamp);
        // }
    }

    function test_partialWithdrawal() public mintAlice(30 ether) mintBob(12 ether) {
        assertEq(address(APEth).balance, 42 ether);
        if (!workingKeys && block.chainid != 31337) {
            APEth.fakeStake(); // TODO: remove this line when we have working keys aslo un-comment the line below
            vm.expectRevert(
                /*"DepositContract: reconstructed DepositData does not match supplied deposit_data_root"*/
            );
        }
        vm.prank(staker);
        APEth.stake(_pubKey, _signature, _deposit_data_root);
        /*if (workingKeys) {*/
        assertEq(address(APEth).balance, 10 ether);
        uint256 aliceEthBalanceBefore = alice.balance;
        vm.prank(alice);
        APEth.withdraw(15 ether);
        assertEq(alice.balance - aliceEthBalanceBefore, 10 ether);
        assertEq(APEth.withdrawalQueue(), 5 ether);
        assertEq(withdrawalQueueTicket.ownerOf(1), alice);
        assertEq(withdrawalQueueTicket.tokenIdToExitQueueExitAmount(1), 5 ether);
        assertGt(withdrawalQueueTicket.tokenIdToExitQueueTimestamp(1), block.timestamp);
        // }
    }

    function test_revert_withdraw_amountTooHigh() public mintAlice(5 ether) {
        vm.expectRevert(); //APETH__WITHDRAW_AMOUNT_TOO_HIGH
        APEth.withdraw(6 ether);
    }
}
