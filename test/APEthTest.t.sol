// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
/* solhint-disable func-name-mixedcase */

import {
    APEthTestSetup,
    APETHV2,
    ERC20Mock,
    MockSsvNetwork,
    IMockEigenPodManager,
    IMockEigenPod,
    IMockDelegationManager,
    console
} from "./APEthTestSetup.t.sol";

contract APETHTest is APEthTestSetup {
    function test_Mint() public {
        //Alice should not be able to mint w/o Early Access
        hoax(alice);
        // Mint 10 eth of tokens and assert the balance
        uint256 aliceBalance = _calculateAmountLessFee(10 ether);
        vm.prank(alice);
        APEth.mint{value: 10 ether}();
        assertApproxEqAbs(APEth.balanceOf(alice), aliceBalance, 1);
        assertEq(address(APEth).balance, 10 ether + startingApethBalance);
    }

    // function test_Cap() public mintAlice(100000 ether) {
    //     uint256 aliceBalance = APEth.balanceOf(alice);
    //     vm.expectRevert(); //APETH__CAP_REACHED()
    //     hoax(alice);
    //     APEth.mint{value: 1}();
    //     assertEq(APEth.balanceOf(alice), aliceBalance);
    // }

    // Test the basic ERC20 functionality of the APETH contract
    function test_ERC20Functionality() public mintAlice(10 ether) {
        uint256 aliceBalance = _calculateAmountLessFee(10 ether);
        //transfer to bob
        vm.prank(alice);
        APEth.transfer(bob, 5 ether);
        assertApproxEqAbs(APEth.balanceOf(bob), 5 ether, 1);
        assertApproxEqAbs(APEth.balanceOf(alice), aliceBalance - 5 ether, 1);
        assertEq(address(APEth).balance, 10 ether + startingApethBalance);
    }

    // // Test the upgradeability of the APETH contract
    // function test_Upgradeability() public {
    //     //deploy upgrade script
    //     vm.prank(owner);
    //     APEth.grantRole(UPGRADER, upgrader);
    //     // Upgrade the proxy to a new version; APETHV2
    //     new UpgradeProxy().run(address(APEth), upgrader);
    //     uint256 two = APETHV2(address(APEth)).version();
    //     assertEq(2, two, "APEth did not upgrade");
    // }

    // Test staking (requires using a forked chain with a deposit contract to test.)
    function test_Stake() public {
        //branch test for case where totalsupply is 0
        // assertEq(APEth.ethPerAPEth(), 1 ether);
        //Grant Alice Early Access
        vm.prank(owner);
        APEth.grantRole(EARLY_ACCESS, alice);
        // Impersonate the alice to call mint function
        hoax(alice);
        // Mint 33 eth of tokens and assert the balance
        APEth.mint{value: 33 ether}();
        assertEq(address(APEth).balance, 33 ether + startingApethBalance, "contract balance not correct");
        _stake1();
        if (workingKeys) assertEq(address(APEth).balance, 1 ether + startingApethBalance);
    }

    // test the accounting. the price should change predictibly when the contract recieves rewards
    function test_BasicAccounting() public mintAlice(10 ether) {
        payable(address(APEth)).transfer(1 ether);
        assertEq(address(APEth).balance, 11 ether + startingApethBalance);
        //check eth per apeth
        uint256 ethPerAPEth =
            (11 ether + (startingEthPerApeth * startingTotalSupply / 1 ether)) * 1 ether / APEth.totalSupply();
        assertApproxEqAbs(APEth.ethPerAPEth(), ethPerAPEth, 1, "ethPerAPEth not correct");
        vm.prank(owner);
        APEth.grantRole(EARLY_ACCESS, bob);
        uint256 expected = _calculateAmountLessFee(10 ether);
        hoax(bob);
        // Mint 10 eth of tokens and assert the balance
        APEth.mint{value: 10 ether}();
        assertApproxEqAbs(APEth.balanceOf(bob), expected, 1, "bob balance not correct");
        assertEq(address(APEth).balance, 21 ether + startingApethBalance);
    }

    function test_BasicAccountingWithStaking() public mintAlice(50 ether) {
        // Send eth to contract to increase balance
        payable(address(APEth)).transfer(1 ether);
        assertEq(address(APEth).balance, 51 ether + startingApethBalance, "contract balance not correct");
        //check eth per apeth
        uint256 ethPerAPEth =
            (51 ether + (startingEthPerApeth * startingTotalSupply / 1 ether)) * 1 ether / APEth.totalSupply();
        assertApproxEqAbs(APEth.ethPerAPEth(), ethPerAPEth, 1, "ethPerAPEth not correct");
        _stake1();
        if (workingKeys) assertEq(address(APEth).balance, 19 ether + startingApethBalance);
        assertApproxEqAbs(APEth.ethPerAPEth(), ethPerAPEth, 1, "ethperAPEth not correct after staking");
        vm.prank(owner);
        APEth.grantRole(EARLY_ACCESS, bob);
        uint256 expected = _calculateAmountLessFee(10 ether);
        hoax(bob);
        // Mint 10 eth of tokens and assert the balance
        APEth.mint{value: 10 ether}();
        assertApproxEqAbs(APEth.balanceOf(bob), expected, 1, "bob balance not correct");
        if (workingKeys) assertEq(address(APEth).balance, 29 ether + startingApethBalance);
    }

    function test_BasicAccountingWithStakingAndFuzzing(uint128 x, uint128 y, uint128 z) public mintAlice(x) {
        // Send eth to contract to increase balance
        vm.deal(address(this), y);
        payable(address(APEth)).transfer(y);
        uint256 balance = uint256(x) + uint256(y);
        if (uint256(x) > cap) {
            balance = uint256(y);
        }
        assertEq(address(APEth).balance, balance + startingApethBalance);
        //check eth per apeth
        // uint256 ethPerAPEth;
        // if (x == 0) {
        //     ethPerAPEth = 1 ether;
        // } else {
        //     ethPerAPEth = (balance * 1 ether) / uint256(x);
        // }
        // assertEq(APEth.ethPerAPEth(), ethPerAPEth, "ethPerAPEth not correct");
        uint256 ethInValidators;
        if (balance >= 32 ether) {
            _stake1();
            ethInValidators += 32 ether;
        }
        if (balance >= 64 ether) {
            _stake2();
            ethInValidators += 32 ether;
        }
        if (balance >= 96 ether) {
            _stake3();
            ethInValidators += 32 ether;
        }
        uint256 newBalance = balance;
        if (workingKeys || block.chainid == 31337) {
            newBalance = balance - ethInValidators;
        }
        assertEq(
            address(APEth).balance, newBalance + startingApethBalance, "contract balance does not match calculated"
        );
        // assertEq(APEth.ethPerAPEth(), ethPerAPEth, "ethperAPEth not correct after staking");
        uint256 amount = uint256(x) + ((uint256(z) * 1 ether) / APEth.ethPerAPEth());
        vm.prank(owner);
        APEth.grantRole(EARLY_ACCESS, bob);
        if (amount > cap) vm.expectRevert(); //APETH__CAP_REACHED()
        uint256 expected = _calculateAmountLessFee(uint256(z));
        hoax(bob);
        // Mint z eth of tokens and assert the balance
        APEth.mint{value: z}();
        if (amount <= cap) {
            assertApproxEqAbs(APEth.balanceOf(bob), expected, 1, "bob balance not correct");
            assertEq(address(APEth).balance, newBalance + z + startingApethBalance, "contract balance not correct");
        }
    }

    function test_ERC20Call() public {
        ERC20Mock mockCoin = new ERC20Mock();
        mockCoin.mint(address(APEth), 1 ether);
        assertEq(mockCoin.balanceOf(address(APEth)), 1 ether);
        vm.prank(owner);
        APEth.grantRole(MISCELLANEOUS, alice);
        vm.prank(alice);
        APEth.transferToken(address(mockCoin), alice, 1 ether);
        assertEq(mockCoin.balanceOf(alice), 1 ether);
        assertEq(mockCoin.balanceOf(address(APEth)), 0);
    }

    function test_SSVCall() public {
        vm.prank(owner);
        APEth.grantRole(SSV_NETWORK_ADMIN, alice);
        vm.prank(alice);
        APEth.callSSVNetwork(
            abi.encodeWithSelector(bytes4(keccak256("setFeeRecipientAddress(address)")), address(APEth))
        );
        if (block.chainid == 31337) {
            MockSsvNetwork ssvNetwork = MockSsvNetwork(ssvNetwork);
            address feeRecip = ssvNetwork.feeRecipient(address(APEth));
            assertEq(feeRecip, address(APEth), "feeRecip not set in ssv contract");
        }
    }

    function test_EigenPodManagerCall() public {
        vm.prank(owner);
        APEth.grantRole(EIGEN_POD_MANAGER_ADMIN, alice);
        vm.prank(alice);
        APEth.callEigenPodManager(abi.encodeWithSelector(IMockEigenPodManager.getPod.selector, address(APEth)));
    }

    function test_DelegationManagerCall() public {
        vm.prank(owner);
        APEth.grantRole(DELEGATION_MANAGER_ADMIN, alice);
        vm.prank(alice);
        if (block.chainid != 31337) vm.expectRevert("Call failed");
        APEth.callDelegationManager(
            abi.encodeWithSelector(IMockDelegationManager.undelegate.selector, address(APEth)), 0
        );
    }

    function test_EigenPodCall() public {
        vm.prank(owner);
        APEth.grantRole(EIGEN_POD_ADMIN, alice);
        vm.prank(alice);
        APEth.callEigenPod(abi.encodeWithSelector(IMockEigenPod.podOwner.selector));
    }

    function test_SetFeeRecipient() public {
        assertEq(APEth.balanceOf(alice), 0, "alice starts with non-zero balance");
        vm.prank(owner);
        APEth.setFeeRecipient(alice);
        // Verify fee recipient was set by making a mint and checking where fees went
        hoax(bob);
        APEth.mint{value: 1 ether}();
        assertGt(APEth.balanceOf(alice), 0, "alice did not recieve fee");
    }

    function test_SetWithdrawalDelay() public {
        vm.prank(owner);
        APEth.setWithdrawalDelay(2 days);
        // since the delay is really just an indication, real testing here is not necessary
    }

    /*
    function test_FeeChange() public {
        vm.prank(storageContract.getGuardian());
        storageContract.setUint(
            keccak256(abi.encodePacked("fee.Amount")),
            10000
        );
        assertEq(APEth.feeAmount(), 10000);
        vm.prank(owner);
        APEth.grantRole(EARLY_ACCESS, alice);
        hoax(alice);
        APEth.mint{value: 10 ether}();
        uint256 aliceBalance = _calculateAmountLessFee(10 ether);
        assertEq(APEth.balanceOf(alice), aliceBalance);
        assertEq(address(APEth).balance, 10 ether + startingApethBalance);
    }


    function test_DoubleStake() public {
        // Grant Alice Early Access
        vm.prank(owner);
        APEth.grantRole(EARLY_ACCESS, alice);

        // Impersonate the alice to call mint function
        hoax(alice);

        // Mint 64 eth of tokens and assert the balance
        APEth.mint{value: 64 ether}();
        
        // Impersonate staker to call stake()
        vm.prank(staker);
        APEth.stake(_pubKey, _signature, _deposit_data_root);
        assertEq(address(APEth).balance, 32 ether + startingApethBalance);

        // Do a second stake
        vm.prank(staker);
        vm.expectRevert(abi.encodeWithSelector(APETH__PUBKEY_ALREADY_USED.selector, _pubKey));
        APEth.stake(_pubKey, _signature, _deposit_data_root);
    }
    */
}
