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

// TODO: refactor test to stasrt with a contract upgrade

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

    function test_changeWithdrawalDelay() public {
        vm.prank(upgrader);
        APEth.setWithdrawalDelay(2 weeks);
        test_multipleWithdrawalsWithTicket();
        vm.deal(address(APEth), 15 ether);
        //advance block.timestamp by one week
        skip(1 weeks);
        // alice claim
        uint256 aliceEthBalanceBefore = alice.balance;
        vm.expectRevert(0x72bf9c5a); //"APETH__TOO_EARLY()"
        vm.prank(alice);
        APEth.redeemWithdrawQueueTicket(1);
        skip(1 weeks);
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

    function test_fuzz_partialWithdrawal(uint128 a, uint128 b, uint128 c, uint256 d)
        public
        setWQT
        mintAlice(a)
        mintBob(b)
    {
        uint256 a256 = uint256(a);
        uint256 b256 = uint256(b);
        uint256 c256 = uint256(c);
        uint256 d256 = uint256(d);
        // Send eth to contract to increase balance
        vm.deal(address(this), c256);
        payable(address(APEth)).transfer(c256);
        uint256 cap = proxyConfig.initialCap;
        uint256 balance = a256 + b256 + c256;
        if (a256 > cap && b256 > cap) {
            balance = c256;
        } else if (a256 > cap) {
            balance = b256 + c256;
        } else if (b256 > cap || a256 + b256 > cap) {
            balance = a256 + c256;
        }
        assertEq(address(APEth).balance, balance, "contract balance does not match calculated");
        //check eth per apeth
        uint256 ethPerAPEth;
        if (a256 == 0 && b256 == 0) {
            ethPerAPEth = 1 ether;
        } else if (a256 > cap && b256 > cap) {
            ethPerAPEth = 1 ether;
        } else if (a256 > cap) {
            if (b256 == 0) {
                ethPerAPEth = 1 ether;
            } else {
                ethPerAPEth = (b256 + c256) * 1 ether / b256;
            }
        } else if (b256 > cap || a256 + b256 > cap) {
            if (a256 == 0) {
                ethPerAPEth = 1 ether;
            } else {
                ethPerAPEth = (a256 + c256) * 1 ether / a256;
            }
        } else {
            ethPerAPEth = (a256 + b256 + c256) * 1 ether / (a256 + b256);
        }
        assertEq(APEth.ethPerAPEth(), ethPerAPEth, "ethPerAPEth not correct");
        uint256 ethInValidators;
        if (balance >= 32 ether) {
            if (!workingKeys && block.chainid != 31337) {
                APEth.fakeStake(); // TODO: remove this line when we have working keys aslo un-comment the line below
                vm.expectRevert(
                    /*"DepositContract: reconstructed DepositData does not match supplied deposit_data_root"*/
                );
            }
            vm.prank(staker);
            APEth.stake(_pubKey, _signature, _deposit_data_root);
            /*if (workingKeys) {*/
            assertEq(address(APEth).balance, balance - 32 ether, "contract balance after staking");
            ethInValidators += 32 ether;
            balance -= 32 ether;
            //}
        }
        uint256 aliceEthBalanceBefore = alice.balance;
        if (APEth.balanceOf(alice) > 0) {
            d256 = d256 % APEth.balanceOf(alice);
            uint256 expectedWithdrawal = d256 * ethPerAPEth / 1 ether;
            vm.prank(alice);
            APEth.withdraw(d256);
            if (expectedWithdrawal > balance) {
                assertEq(alice.balance - aliceEthBalanceBefore, balance, "alice  partial balance");
                assertEq(APEth.withdrawalQueue(), expectedWithdrawal - balance);
                assertEq(withdrawalQueueTicket.ownerOf(1), alice);
                assertEq(withdrawalQueueTicket.tokenIdToExitQueueExitAmount(1), expectedWithdrawal - balance);
                assertGt(withdrawalQueueTicket.tokenIdToExitQueueTimestamp(1), block.timestamp);
            } else {
                assertEq(alice.balance - aliceEthBalanceBefore, expectedWithdrawal, "alice balance");
            }
        }
    }

    function test_fuzz_multipleWithdrawalsWithTicket(uint128 a, uint128 b, uint128 c, uint128 d, uint128 e) public {
        test_fuzz_partialWithdrawal(a, b, c, d);
        uint256 e256 = uint256(e);
        // bob withdrawal
        uint256 bobEthBalanceBefore = bob.balance;
        uint256 bobApethBalance = APEth.balanceOf(bob);
        uint256 withdrawalQueue = APEth.withdrawalQueue();
        uint256 contractBalance = address(APEth).balance;
        if (bobApethBalance > 0 && e256 > 0) {
            e256 = e256 % bobApethBalance;
            uint256 expectedWithdrawal = e256 * APEth.ethPerAPEth() / 1 ether;
            vm.prank(bob);
            APEth.withdraw(e256);
            if (withdrawalQueue > 0) {
                assertEq(bob.balance, bobEthBalanceBefore);
                assertEq(APEth.withdrawalQueue(), withdrawalQueue + expectedWithdrawal);
                assertEq(withdrawalQueueTicket.ownerOf(2), bob);
                assertEq(withdrawalQueueTicket.tokenIdToExitQueueExitAmount(2), expectedWithdrawal);
                assertGt(withdrawalQueueTicket.tokenIdToExitQueueTimestamp(2), block.timestamp);
            } else if (expectedWithdrawal > contractBalance) {
                assertEq(bob.balance - bobEthBalanceBefore, contractBalance);
                assertEq(APEth.withdrawalQueue(), expectedWithdrawal - contractBalance);
                assertEq(withdrawalQueueTicket.ownerOf(1), bob);
                assertEq(withdrawalQueueTicket.tokenIdToExitQueueExitAmount(1), expectedWithdrawal - contractBalance);
                assertGt(withdrawalQueueTicket.tokenIdToExitQueueTimestamp(1), block.timestamp);
            } else {
                assertEq(bob.balance - bobEthBalanceBefore, expectedWithdrawal);
            }
        }
    }

    function test_fuzz_ticketClaim(uint128 a, uint128 b, uint128 c, uint128 d, uint128 e) public {
        test_fuzz_multipleWithdrawalsWithTicket(a, b, c, d, e);
        if (APEth.withdrawalQueue() > 0) {
            vm.deal(address(this), 32 ether);
            payable(address(APEth)).transfer(32 ether);
            //advance block.timestamp by one week
            skip(1 weeks);
            if (withdrawalQueueTicket.ownerOf(1) == alice) {
                uint256 aliceEthBalanceBefore = alice.balance;
                uint256 expectedWithdrawal = withdrawalQueueTicket.tokenIdToExitQueueExitAmount(1);
                vm.prank(alice);
                APEth.redeemWithdrawQueueTicket(1);
                assertEq(alice.balance - aliceEthBalanceBefore, expectedWithdrawal, "alice balance");
            } else if (withdrawalQueueTicket.ownerOf(1) == bob) {
                uint256 bobEthBalanceBefore = bob.balance;
                uint256 expectedWithdrawal = withdrawalQueueTicket.tokenIdToExitQueueExitAmount(1);
                vm.prank(bob);
                APEth.redeemWithdrawQueueTicket(1);
                assertEq(bob.balance - bobEthBalanceBefore, expectedWithdrawal, "bob balance");
            }
            if (APEth.withdrawalQueue() > 0) {
                uint256 bobEthBalanceBefore = bob.balance;
                uint256 expectedWithdrawal = withdrawalQueueTicket.tokenIdToExitQueueExitAmount(2);
                vm.prank(bob);
                APEth.redeemWithdrawQueueTicket(2);
                assertEq(bob.balance - bobEthBalanceBefore, expectedWithdrawal, "bob balance");
            }
        }
    }

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

    function test_revert_redeemWithdrawlsNotEnabled() public {
        vm.expectRevert(0x1ba990d1); //"APETH__WITHDRAWALS_NOT_ENABLED()"
        APEth.redeemWithdrawQueueTicket(1);
    }

    function test_revert_redeemTooEarly() public {
        test_multipleWithdrawalsWithTicket();
        vm.deal(address(APEth), 15 ether);
        // alice claim
        vm.expectRevert(0x72bf9c5a); //"APETH__TOO_EARLY()"
        vm.prank(alice);
        APEth.redeemWithdrawQueueTicket(1);
    }

    function test_revert_redeemNotEnoughEth() public {
        test_multipleWithdrawalsWithTicket();
        //advance block.timestamp by one week
        skip(1 weeks);
        // alice claim
        vm.expectRevert(0x57b43b8f); //"APETH__NOT_ENOUGH_ETH_FOR_WITHDRAWAL()"
        vm.prank(alice);
        APEth.redeemWithdrawQueueTicket(1);
    }

    function test_revert_redeemNotOwner() public {
        test_multipleWithdrawalsWithTicket();
        vm.deal(address(APEth), 15 ether);
        //advance block.timestamp by one week
        skip(1 weeks);
        vm.expectRevert(0x4b63d80d); // APETH__NOT_OWNER()
        vm.prank(vm.addr(69));
        APEth.redeemWithdrawQueueTicket(1);
    }
}
