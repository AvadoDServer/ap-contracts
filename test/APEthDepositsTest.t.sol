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
        vm.deal(address(APEth), 98 ether);
        vm.prank(staker);
        APEth.setWithdrawalTickets(3, ticBoth, 1);
        assertApproxEqAbs(9 ether, APEth.balanceOf(charlie), 1 ether, "charlie's apeth balance");
        console.log("eth per apeth (after setWithdrawalTickets)", APEth.ethPerAPEth());
        console.log("charlie's apeth balance", APEth.balanceOf(charlie));
    }
}
