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

contract WithdrawalTicketTest is APEthTestSetup {
    function test_SimpleWithdrawal() public mintAlice(10 ether) {
        // Send eth to contract to increase balance
        payable(address(APEth)).transfer(1 ether);
        assertEq(address(APEth).balance, 11 ether + startingApethBalance);
        uint256 aliceApethBalance = APEth.balanceOf(alice);
        uint256 aliceEthWithdrawalAmountExpected = aliceApethBalance * APEth.ethPerAPEth() / 1 ether;
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
        assertEq(address(APEth).balance, 21 ether + startingApethBalance);
        //check eth per apeth
        // uint256 ethPerAPEth = 21 ether / 20;
        // assertEq(APEth.ethPerAPEth(), ethPerAPEth);
        // alice withdrawal
        uint256 aliceApethBalance = APEth.balanceOf(alice);
        uint256 aliceEthWithdrawalAmountExpected = aliceApethBalance * APEth.ethPerAPEth() / 1 ether;
        uint256 aliceEthBalanceBefore = alice.balance;
        vm.prank(alice);
        APEth.withdraw(aliceApethBalance);
        uint256 aliceEthBalanceAfter = alice.balance;
        uint256 aliceEthWithdrawalAmount = aliceEthBalanceAfter - aliceEthBalanceBefore;
        assertEq(APEth.balanceOf(alice), 0);
        assertEq(aliceEthWithdrawalAmount, aliceEthWithdrawalAmountExpected);
        // bob withdrawal
        uint256 bobApethBalance = APEth.balanceOf(bob);
        uint256 bobEthWithdrawalAmountExpected = bobApethBalance * APEth.ethPerAPEth() / 1 ether;
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
        console.log("eth per apeth", APEth.ethPerAPEth());
        _stake1();
        if (workingKeys) {
            assertEq(address(APEth).balance, 0);
            uint256 aliceApethBalance = APEth.balanceOf(alice);
            uint256 aliceEthBalance = alice.balance;
            vm.prank(alice);
            APEth.withdraw(aliceApethBalance);
            assertEq(APEth.withdrawalQueueAPETH(), aliceApethBalance);
            assertEq(withdrawalQueueTicket.ownerOf(1), alice);
            assertEq(withdrawalQueueTicket.tokenIdToExitQueueExitAmount(1), aliceApethBalance);
            assertGt(withdrawalQueueTicket.tokenIdToExitQueueTimestamp(1), block.timestamp);
            assertEq(APEth.balanceOf(alice), 0);
        }
    }

    function test_multipleWithdrawalsWithTicket() public {
        test_withdrawalWithTicket();
        mintBob2(64 ether);
        console.log("eth per apeth (after bob's second mint)", APEth.ethPerAPEth());
        _stake2();
        _stake3();
        // bob withdrawal
        uint256 bobEthBalanceBefore = bob.balance;
        uint256 bobApethBalance = APEth.balanceOf(bob);
        uint256 withdrawalQueueAPETH = APEth.withdrawalQueueAPETH();
        uint256 ethPerAPEth = APEth.ethPerAPEth();
        uint256 contractBalance = address(APEth).balance;
        console.log("contract balance", contractBalance);
        vm.prank(bob);
        APEth.withdraw(bobApethBalance);
        assertEq(bob.balance, bobEthBalanceBefore);
        assertEq(APEth.withdrawalQueueAPETH(), withdrawalQueueAPETH + bobApethBalance);
        assertEq(withdrawalQueueTicket.ownerOf(2), bob);
        assertEq(withdrawalQueueTicket.tokenIdToExitQueueExitAmount(2), bobApethBalance);
        assertGt(withdrawalQueueTicket.tokenIdToExitQueueTimestamp(2), block.timestamp);
    }

    function test_ticketClaim() public {
        test_multipleWithdrawalsWithTicket();
        vm.deal(address(apVault), 100 ether); 
        vm.prank(staker);
        APEth.withdrawFromVault(1, ticOne, 34 ether);
        console.log("eth per apeth (after withdrawFromVault 1)", APEth.ethPerAPEth());
        vm.prank(staker);
        APEth.withdrawFromVault(2, ticTwo, 66 ether);
        console.log("eth per apeth (after withdrawFromVault 2)", APEth.ethPerAPEth());
        // alice claim
        uint256 aliceEthBalanceBefore = alice.balance;
        uint256 aliceExpectedWithdrawal = withdrawalQueueTicket.tokenIdToExitQueueExitAmount(1);
        uint256 withdrawalQueueETH = APEth.withdrawalQueueETH();
        vm.prank(alice);
        console.log("contract balance before redeemWithdrawQueueTicket 1", address(APEth).balance);
        APEth.redeemWithdrawQueueTicket(1);
        console.log("eth per apeth (after redeemWithdrawQueueTicket 1)", APEth.ethPerAPEth());
        console.log("contract balance after redeemWithdrawQueueTicket 1", address(APEth).balance);
        assertEq(alice.balance - aliceEthBalanceBefore, aliceExpectedWithdrawal, "alice balance");
        assertEq(APEth.withdrawalQueueETH(), withdrawalQueueETH - aliceExpectedWithdrawal);
        // bob claim
        uint256 bobEthBalanceBefore = bob.balance;
        uint256 bobExpectedWithdrawal = withdrawalQueueTicket.tokenIdToExitQueueExitAmount(2);
        vm.prank(bob);
        APEth.redeemWithdrawQueueTicket(2);
        console.log("contract balance after redeemWithdrawQueueTicket 2", address(APEth).balance);
        console.log("eth per apeth (after redeemWithdrawQueueTicket 2)", APEth.ethPerAPEth());
        assertEq(bob.balance - bobEthBalanceBefore, bobExpectedWithdrawal, "bob balance");
        assertEq(APEth.withdrawalQueueETH(), 0 ether);
    }

    function test_ticketClaimJointWithdrawFromVault() public {
        test_multipleWithdrawalsWithTicket();
        vm.deal(address(apVault), 100 ether); 
        console.log("eth per apeth (before withdrawFromVault)", APEth.ethPerAPEth());
        vm.prank(staker);
        APEth.withdrawFromVault(3, ticBoth, 100 ether);
        console.log("eth per apeth (after withdrawFromVault)", APEth.ethPerAPEth());
        // alice claim
        uint256 aliceEthBalanceBefore = alice.balance;
        uint256 aliceExpectedWithdrawal = withdrawalQueueTicket.tokenIdToExitQueueExitAmount(1);
        uint256 withdrawalQueueETH = APEth.withdrawalQueueETH();
        vm.prank(alice);
        APEth.redeemWithdrawQueueTicket(1);
        console.log("eth per apeth (after redeemWithdrawQueueTicket 1)", APEth.ethPerAPEth());
        console.log("contract balance after redeemWithdrawQueueTicket 1", address(APEth).balance);
        assertEq(alice.balance - aliceEthBalanceBefore, aliceExpectedWithdrawal, "alice balance");
        assertEq(APEth.withdrawalQueueETH(), withdrawalQueueETH - aliceExpectedWithdrawal);
        // bob claim
        uint256 bobEthBalanceBefore = bob.balance;
        uint256 bobExpectedWithdrawal = withdrawalQueueTicket.tokenIdToExitQueueExitAmount(2);
        vm.prank(bob);
        APEth.redeemWithdrawQueueTicket(2);
        console.log("contract balance after redeemWithdrawQueueTicket 2", address(APEth).balance);
        console.log("eth per apeth (after redeemWithdrawQueueTicket 2)", APEth.ethPerAPEth());
        assertEq(bob.balance - bobEthBalanceBefore, bobExpectedWithdrawal, "bob balance");
        assertEq(APEth.withdrawalQueueETH(), 0 ether);
    }

    function test_fuzz_partialWithdrawal(uint128 a, uint128 b, uint64 c, uint128 d)
        public
        mintAlice(a)
        mintBob(b)
        returns (uint256)
    {
        uint256 a256 = uint256(a);
        uint256 b256 = uint256(b);
        uint256 c256 = uint256(c);
        uint256 d256 = uint256(d);
        // Send eth to contract to increase balance
        vm.deal(address(this), c256);
        payable(address(APEth)).transfer(c256);
        uint256 balance = a256 + b256 + c256 + startingApethBalance;
        assertEq(address(APEth).balance, balance, "contract balance does not match calculated");
        //check eth per apeth
        // this will not work if cap is set to something less than type(uint128).max
        uint256 ethPerAPEth =
            (a256 + b256 + c256 + (startingEthPerApeth * startingTotalSupply / 1 ether)) * 1 ether / APEth.totalSupply();
        assertApproxEqAbs(APEth.ethPerAPEth(), ethPerAPEth, 1, "ethPerAPEth not correct");
        uint256 ethInValidators;
        if (balance >= 32 ether) {
            _stake1();
            if (workingKeys) {
                assertEq(address(APEth).balance, balance - 32 ether, "contract balance after staking");
                ethInValidators += 32 ether;
                balance -= 32 ether;
            }
        }
        uint256 aliceEthBalanceBefore = alice.balance;
        if (APEth.balanceOf(alice) > 0) {
            d256 = d256 % APEth.balanceOf(alice);
            uint256 expectedWithdrawal = d256 * APEth.ethPerAPEth() / 1 ether;
            vm.prank(alice);
            APEth.withdraw(d256);
            if (expectedWithdrawal > balance) {
                assertEq(alice.balance, aliceEthBalanceBefore, "alice balance 1");
                assertEq(APEth.withdrawalQueueAPETH(), d256);
                assertEq(withdrawalQueueTicket.ownerOf(1), alice);
                assertEq(withdrawalQueueTicket.tokenIdToExitQueueExitAmount(1), d256);
                assertGt(withdrawalQueueTicket.tokenIdToExitQueueTimestamp(1), block.timestamp);
            } else {
                assertApproxEqAbs(alice.balance - aliceEthBalanceBefore, expectedWithdrawal, 1, "alice balance 2");
            }
        }
        return (ethInValidators);
    }

    function test_fuzz_multipleWithdrawalsWithTicket(uint128 a, uint128 b, uint64 c, uint128 d, uint128 e)
        public
        returns (uint256)
    {
        uint256 ethInValidators = test_fuzz_partialWithdrawal(a, b, c, d);
        uint256 e256 = uint256(e);
        // bob withdrawal
        uint256 bobEthBalanceBefore = bob.balance;
        uint256 bobApethBalance = APEth.balanceOf(bob);
        uint256 withdrawalQueueAPETH = APEth.withdrawalQueueAPETH();
        uint256 contractBalance = address(APEth).balance;
        if (bobApethBalance > 0 && e256 > 0) {
            e256 = e256 % bobApethBalance;
            uint256 expectedWithdrawal = e256 * APEth.ethPerAPEth() / 1 ether;
            vm.prank(bob);
            APEth.withdraw(e256);
            if (withdrawalQueueAPETH > 0) {
                assertEq(bob.balance, bobEthBalanceBefore);
                assertEq(APEth.withdrawalQueueAPETH(), withdrawalQueueAPETH + e256);
                assertEq(withdrawalQueueTicket.ownerOf(2), bob);
                assertEq(withdrawalQueueTicket.tokenIdToExitQueueExitAmount(2), e256);
                assertGt(withdrawalQueueTicket.tokenIdToExitQueueTimestamp(2), block.timestamp);
            } else if (expectedWithdrawal > contractBalance) {
                assertEq(bob.balance, bobEthBalanceBefore);
                assertEq(APEth.withdrawalQueueAPETH(), e256);
                assertEq(withdrawalQueueTicket.ownerOf(1), bob);
                assertEq(withdrawalQueueTicket.tokenIdToExitQueueExitAmount(1), e256);
                assertGt(withdrawalQueueTicket.tokenIdToExitQueueTimestamp(1), block.timestamp);
            } else {
                assertEq(bob.balance - bobEthBalanceBefore, expectedWithdrawal);
            }
        }
        return (ethInValidators);
    }

    function test_fuzz_ticketClaim(uint128 a, uint128 b, uint64 c, uint128 d, uint128 e) public {
        uint256 ethInValidators = test_fuzz_multipleWithdrawalsWithTicket(a, b, c, d, e);
        if (APEth.withdrawalQueueAPETH() > 0) {
            vm.deal(address(apVault), ethInValidators);
            vm.prank(staker);
            APEth.withdrawFromVault(1, ticOne, ethInValidators);
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
            if (APEth.withdrawalQueueAPETH() > 0) {
                vm.prank(staker);
                APEth.withdrawFromVault(0, ticTwo, 0);
                uint256 bobEthBalanceBefore = bob.balance;
                uint256 expectedWithdrawal = withdrawalQueueTicket.tokenIdToExitQueueExitAmount(2);
                vm.prank(bob);
                APEth.redeemWithdrawQueueTicket(2);
                assertEq(bob.balance - bobEthBalanceBefore, expectedWithdrawal, "bob balance");
            }
        }
    }

    function test_Z_art() public {
        test_withdrawalWithTicket();
        string memory uri = withdrawalQueueTicket.tokenURI(1);
        console.log("uri", uri);
    }

    function test_revert_directMint() public {
        vm.expectRevert(); //AccessControl...
        withdrawalQueueTicket.mint(alice, 1000 ether, block.timestamp);
    }

    function test_revert_withdraw_amountTooHigh() public mintAlice(5 ether) {
        vm.expectRevert(); // APETH__WITHDRAWAL_TOO_LARGE
        APEth.withdraw(6 ether);
    }

    function test_revert_redeemnonexistantToken() public {
        vm.expectRevert(); //"ERC721NonexistentToken(1)"
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
        vm.prank(staker);
        APEth.withdrawFromVault(0, ticOne, 0); //Alice should be pissed!!!
        // alice claim
        vm.expectRevert(0x57b43b8f); //"APETH__NOT_ENOUGH_ETH_FOR_WITHDRAWAL()"
        vm.prank(alice);
        APEth.redeemWithdrawQueueTicket(1);
    }

    function test_revert_redeemNotOwner() public {
        test_multipleWithdrawalsWithTicket();
        vm.deal(address(apVault), 33 ether);
        vm.prank(staker);
        APEth.withdrawFromVault(1, ticOne, 33);
        vm.expectRevert(0x4b63d80d); // APETH__NOT_OWNER()
        vm.prank(vm.addr(69));
        APEth.redeemWithdrawQueueTicket(1);
    }
}
