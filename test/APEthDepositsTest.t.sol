// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
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
import {APETH__CONTRACT_LOCKED} from "../src/APETHV2.sol";
import {
    APETH_DEPOSITS__SENDER_MUST_BE_DEPOSITOR,
    APETH_DEPOSITS__DEPOSIT_WITHDRAWN,
    APETH_DEPOSITS__NUMBER_OF_DEPOSITS_TOO_HIGH,
    APETH_DEPOSITS__LESS_THAN_MINIMUM_DEPOSIT
} from "../src/APEthDeposits.sol";

contract APEthDepositsTest is APEthTestSetup {
    function test_mintAPEthBulk() public mintAlice(30 ether) mintBob(2 ether) {
        assertEq(address(APEth).balance, 32 ether);
        console.log("eth per apeth", APEth.ethPerAPEth());
        _stake1();
        mintBob2(64 ether);
        console.log("eth per apeth (after bob's second mint)", APEth.ethPerAPEth());
        _stake2();
        _stake3();
        assertEq(address(APEth).balance, 0);
        uint256 aliceApethBalance = APEth.balanceOf(alice);
        vm.prank(alice);
        APEth.withdraw(aliceApethBalance);
        assertEq(APEth.withdrawalQueueAPETH(), aliceApethBalance);
        assertEq(withdrawalQueueTicket.ownerOf(1), alice);
        assertEq(withdrawalQueueTicket.tokenIdToExitQueueExitAmount(1), aliceApethBalance);
        assertGt(withdrawalQueueTicket.tokenIdToExitQueueTimestamp(1), block.timestamp);
        assertEq(APEth.balanceOf(alice), 0);
        console.log("eth per apeth (after alice's withdrawal)", APEth.ethPerAPEth());
        // bob withdrawal
        uint256 bobEthBalanceBefore = bob.balance;
        uint256 bobApethBalance = APEth.balanceOf(bob);
        uint256 withdrawalQueueAPETH = APEth.withdrawalQueueAPETH();
        uint256 contractBalance = address(APEth).balance;
        console.log("contract balance", contractBalance);
        vm.prank(bob);
        APEth.withdraw(bobApethBalance);
        assertEq(bob.balance, bobEthBalanceBefore);
        assertEq(APEth.withdrawalQueueAPETH(), withdrawalQueueAPETH + bobApethBalance);
        assertEq(withdrawalQueueTicket.ownerOf(2), bob);
        assertEq(withdrawalQueueTicket.tokenIdToExitQueueExitAmount(2), bobApethBalance);
        assertGt(withdrawalQueueTicket.tokenIdToExitQueueTimestamp(2), block.timestamp);
        console.log("eth per apeth (after bob's withdrawal)", APEth.ethPerAPEth());
        //check revert on mint()
        vm.expectRevert(APETH__CONTRACT_LOCKED.selector);
        hoax(charlie);
        APEth.mint();
        // deposit into APEthDeposits
        vm.prank(charlie);
        apEthDeposits.deposit{value: 10 ether}();
        hoax(david);
        apEthDeposits.deposit{value: 5 ether}();
        vm.deal(address(APEth), 98 ether);
        vm.prank(staker);
        APEth.setWithdrawalTickets(3, ticBoth, 2);
        assertApproxEqAbs(9 ether, APEth.balanceOf(charlie), 1 ether, "charlie's apeth balance");
        assertApproxEqAbs(APEth.balanceOf(charlie) / 2, APEth.balanceOf(david), 1, "david's apeth balance");
        console.log("eth per apeth (after setWithdrawalTickets)", APEth.ethPerAPEth());
        console.log("charlie's apeth balance", APEth.balanceOf(charlie));
        console.log("david's apeth balance", APEth.balanceOf(david));
    }

    function test_withdrawal() public {
        hoax(charlie);
        apEthDeposits.deposit{value: 1 ether}();
        uint256 charlieBalance = charlie.balance;
        vm.prank(charlie);
        apEthDeposits.withdraw(1);
        assertEq(charlie.balance, charlieBalance + 1 ether);
    }

    function test_revert_mintAPEthBulk_wrongCaller() public {
        hoax(alice);
        vm.expectRevert(); //accesscontrol
        apEthDeposits.mintAPEthBulk(1);
    }

    function test_revert_withdrawal_wrongCaller() public {
        hoax(alice);
        apEthDeposits.deposit{value: 1 ether}();
        vm.expectRevert(APETH_DEPOSITS__SENDER_MUST_BE_DEPOSITOR.selector);
        vm.prank(bob);
        apEthDeposits.withdraw(1);
    }

    function test_revert_withdrawal_alreadyWithdrawn() public {
        hoax(alice);
        apEthDeposits.deposit{value: 1 ether}();
        vm.prank(alice);
        apEthDeposits.withdraw(1);
        vm.expectRevert(APETH_DEPOSITS__DEPOSIT_WITHDRAWN.selector);
        vm.prank(alice);
        apEthDeposits.withdraw(1);
    }

    function test_revert_mintAPEthBulk_wrongNumberOfDeposits() public {
        hoax(address(APEth));
        vm.expectRevert(APETH_DEPOSITS__NUMBER_OF_DEPOSITS_TOO_HIGH.selector);
        apEthDeposits.mintAPEthBulk(1);
    }

    function test_revert_deposit_lessThanMinDeposit() public {
        hoax(alice);
        vm.expectRevert(APETH_DEPOSITS__LESS_THAN_MINIMUM_DEPOSIT.selector);
        apEthDeposits.deposit{value: 1}();
    }

    function test_ReceiveFunction() public {
        uint256 minDeposit = apEthDeposits.minDeposit();
        hoax(alice);
        (bool success,) = address(apEthDeposits).call{value: minDeposit}("");
        require(success, "transfer failed");

        // Verify deposit was recorded
        (address depositor, uint256 amount,) = apEthDeposits.deposits(1);
        assertEq(depositor, alice);
        assertEq(amount, minDeposit);
    }

    function test_Revert_ReceiveFunction_BelowMinimum() public {
        uint256 minDeposit = apEthDeposits.minDeposit();
        hoax(alice);
        vm.expectRevert(APETH_DEPOSITS__LESS_THAN_MINIMUM_DEPOSIT.selector);
        (bool success,) = address(apEthDeposits).call{value: minDeposit - 1}("");
        require(success, "transfer failed");
    }
}
