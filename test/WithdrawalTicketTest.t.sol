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
    function test_SimpleWithdrawal() public setWQT mintAlice(10 ether) {
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

    function test_multipleWithdrawals() public setWQT mintAlice(10 ether) mintBob(10 ether) {
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

    function test_withdrawalWithTicket() public setWQT mintAlice(30 ether) mintBob(2 ether) {
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

    function test_partialWithdrawal() public setWQT mintAlice(30 ether) mintBob(12 ether) {
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

    function test_multipleWithdrawalsWithTicket() public {
        test_partialWithdrawal();
        // bob withdrawal
        uint256 bobEthBalanceBefore = bob.balance;
        vm.prank(bob);
        APEth.withdraw(5 ether);
        assertEq(bob.balance, bobEthBalanceBefore);
        assertEq(APEth.withdrawalQueue(), 10 ether);
        assertEq(withdrawalQueueTicket.ownerOf(2), bob);
        assertEq(withdrawalQueueTicket.tokenIdToExitQueueExitAmount(2), 5 ether);
        assertGt(withdrawalQueueTicket.tokenIdToExitQueueTimestamp(2), block.timestamp);
        // }
    }

    function test_ticketClaim() public {
        test_multipleWithdrawalsWithTicket();
        vm.deal(address(APEth), 15 ether);
        //advance block.timestamp by one week
        skip(1 weeks);
        // alice claim
        uint256 aliceEthBalanceBefore = alice.balance;
        vm.prank(alice);
        APEth.redeemWithdrawQueueTicket(1);
        assertEq(alice.balance - aliceEthBalanceBefore, 5 ether, "alice balance");
        assertEq(APEth.withdrawalQueue(), 5 ether);
        // bob claim
        uint256 bobEthBalanceBefore = bob.balance;
        vm.prank(bob);
        APEth.redeemWithdrawQueueTicket(2);
        assertEq(bob.balance - bobEthBalanceBefore, 5 ether);
        assertEq(APEth.withdrawalQueue(), 0 ether);
    }

    //TODO: test more complicated withdrawal scenarios (maybe with fuzzing)
    //TODO: test claiming ticket

    function test_revert_directMint() public setWQT {
        vm.expectRevert(); //AccessControl...
        withdrawalQueueTicket.mint(alice, 1000 ether, block.timestamp);
    }

    function test_revert_withdraw_amountTooHigh() public setWQT mintAlice(5 ether) {
        vm.expectRevert(); // APETH__WITHDRAWAL_TOO_LARGE
        APEth.withdraw(6 ether);
    }

    function test_revert_cannotResetWithdrawalQueue() public setWQT {
        vm.expectRevert(0x7406e92a); //"APETH__WITHDRAWAL_QUEUE_ALREADY_SET()"
        vm.prank(upgrader);
        APEth.setWithdrawalQueueTicket(address(0));
    }

    function test_revert_withdrawalsNotEnabled() public mintAlice(10 ether) {
        vm.expectRevert(0x1ba990d1); //"APETH__WITHDRAWALS_NOT_ENABLED()"
        APEth.withdraw(5 ether);
    }
}
