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
import {APETH__PUBKEY_ALREADY_USED} from "../src/APETH.sol";

contract APETHTest is APEthTestSetup {
    function test_Mint() public {
        //Alice should not be able to mint w/o Early Access
        vm.expectRevert();
        hoax(alice);
        APEth.mint{value: 10 ether}();
        //grant Alice early access
        vm.prank(owner);
        APEth.grantRole(EARLY_ACCESS, alice);
        // Mint 10 eth of tokens and assert the balance
        vm.prank(alice);
        APEth.mint{value: 10 ether}();
        uint256 aliceBalance = _calculateAmountLessFee(10 ether);
        assertEq(APEth.balanceOf(alice), aliceBalance);
        assertEq(address(APEth).balance, 10 ether);
    }

    function test_Cap() public mintAlice(100000 ether) {
        uint256 aliceBalance = APEth.balanceOf(alice);
        vm.expectRevert(); //APETH__CAP_REACHED()
        hoax(alice);
        APEth.mint{value: 1}();
        assertEq(APEth.balanceOf(alice), aliceBalance);
    }

    // Test the basic ERC20 functionality of the APETH contract
    function test_ERC20Functionality() public mintAlice(10 ether) {
        uint256 aliceBalance = _calculateAmountLessFee(10 ether);
        //transfer to bob
        vm.prank(alice);
        APEth.transfer(bob, 5 ether);
        assertEq(APEth.balanceOf(bob), 5 ether);
        assertEq(APEth.balanceOf(alice), aliceBalance - 5 ether);
        assertEq(address(APEth).balance, 10 ether);
    }

    // Test the upgradeability of the APETH contract
    function test_Upgradeability() public {
        //deploy upgrade script
        UpgradeProxy upgradeProxy = new UpgradeProxy();
        vm.prank(owner);
        APEth.grantRole(UPGRADER, upgrader);
        // Upgrade the proxy to a new version; APETHV2
        upgradeProxy.run(upgrader, address(APEth));
        assertEq(address(APEth.apEthStorage()), address(storageContract), "storage contract address did not migrate");
        uint256 two = APETHV2(address(APEth)).version();
        assertEq(2, two, "APEth did not upgrade");
    }

    // Test staking (requires using a forked chain with a deposit contract to test.)
    function test_Stake() public {
        //branch test for case where totalsupply is 0
        assertEq(APEth.ethPerAPEth(), 1 ether);
        //Grant Alice Early Access
        vm.prank(owner);
        APEth.grantRole(EARLY_ACCESS, alice);
        // Impersonate the alice to call mint function
        hoax(alice);
        // Mint 33 eth of tokens and assert the balance
        APEth.mint{value: 33 ether}();
        assertEq(address(APEth).balance, 33 ether);
        if (!workingKeys && block.chainid != 31337) {
            vm.expectRevert("DepositContract: reconstructed DepositData does not match supplied deposit_data_root");
        }
        // Impersonate staker to call stake()
        vm.prank(staker);
        APEth.stake( _pubKey, _signature, _deposit_data_root);
        if (workingKeys) assertEq(address(APEth).balance, 1 ether);
    }

    // test the accounting. the price should change predictibly when the contract recieves rewards
    function test_BasicAccounting() public mintAlice(10 ether) {
        payable(address(APEth)).transfer(1 ether);
        assertEq(address(APEth).balance, 11 ether);
        //check eth per apeth
        uint256 ethPerAPEth = 11 ether / 10;
        assertEq(APEth.ethPerAPEth(), ethPerAPEth);
        vm.prank(owner);
        APEth.grantRole(EARLY_ACCESS, bob);
        hoax(bob);
        // Mint 10 eth of tokens and assert the balance
        APEth.mint{value: 10 ether}();
        uint256 expected = _calculateAmountLessFee(10 ether * 1 ether / ethPerAPEth);
        assertEq(APEth.balanceOf(bob), expected);
        assertEq(address(APEth).balance, 21 ether);
    }

    function test_BasicAccountingWithStaking() public mintAlice(50 ether) {
        // Send eth to contract to increase balance
        payable(address(APEth)).transfer(1 ether);
        assertEq(address(APEth).balance, 51 ether);
        //check eth per apeth
        uint256 ethPerAPEth = 51 ether / 50;
        assertEq(APEth.ethPerAPEth(), ethPerAPEth);
        vm.prank(staker);
        if (!workingKeys && block.chainid != 31337) {
            vm.expectRevert("DepositContract: reconstructed DepositData does not match supplied deposit_data_root");
        }
        APEth.stake( _pubKey, _signature, _deposit_data_root);
        if (workingKeys) assertEq(address(APEth).balance, 19 ether);
        assertEq(APEth.ethPerAPEth(), ethPerAPEth);
        vm.prank(owner);
        APEth.grantRole(EARLY_ACCESS, bob);
        hoax(bob);
        // Mint 10 eth of tokens and assert the balance
        APEth.mint{value: 10 ether}();
        uint256 expected = _calculateAmountLessFee(10 ether * 1 ether / ethPerAPEth);
        assertEq(APEth.balanceOf(bob), expected);
        if (workingKeys) assertEq(address(APEth).balance, 29 ether);
    }

    function test_BasicAccountingWithStakingAndWithdrawal() public mintAlice(50 ether) {
        // Send eth to contract to increase balance
        payable(address(APEth)).transfer(1 ether);
        assertEq(address(APEth).balance, 51 ether);
        //check eth per apeth
        uint256 ethPerAPEth = 51 ether / 50;
        assertEq(APEth.ethPerAPEth(), ethPerAPEth);
        vm.prank(staker);
        if (!workingKeys && block.chainid != 31337) {
            vm.expectRevert("DepositContract: reconstructed DepositData does not match supplied deposit_data_root");
        }
        APEth.stake( _pubKey, _signature, _deposit_data_root);
        if (workingKeys) {
            assertEq(address(APEth).balance, 19 ether);
        }
        if (block.chainid == 31337) {
            assertEq(storageContract.getUint(keccak256(abi.encodePacked("active.validators"))), 1);
            vm.prank(admin);
            APEth.callDelegationManager(abi.encodeWithSelector(IMockDelegationManager.undelegate.selector, address(APEth)), 1);
            assertEq(storageContract.getUint(keccak256(abi.encodePacked("active.validators"))), 0);
        }
    }

    function test_BasicAccountingWithStakingAndFuzzing(uint128 x, uint128 y, uint128 z) public mintAlice(x) {
        // Send eth to contract to increase balance
        vm.deal(address(this), y);
        payable(address(APEth)).transfer(y);
        uint256 cap = storageContract.getUint(keccak256(abi.encodePacked("cap.Amount")));
        uint256 balance = uint256(x) + uint256(y);
        if (uint256(x) > cap) {
            balance = uint256(y);
        }
        assertEq(address(APEth).balance, balance);
        //check eth per apeth
        uint256 ethPerAPEth;
        if (x == 0) {
            ethPerAPEth = 1 ether;
        } else {
            ethPerAPEth = balance * 1 ether / uint256(x);
        }
        assertEq(APEth.ethPerAPEth(), ethPerAPEth, "ethPerAPEth not correct");
        uint256 ethInValidators;
        if (balance >= 32 ether) {
            vm.prank(staker);
            if (!workingKeys && block.chainid != 31337) {
                vm.expectRevert("DepositContract: reconstructed DepositData does not match supplied deposit_data_root");
            }
            APEth.stake( _pubKey, _signature, _deposit_data_root);
            ethInValidators += 32 ether;
        }
        if (balance >= 64 ether) {
            vm.prank(staker);
            if (!workingKeys && block.chainid != 31337) {
                vm.expectRevert("DepositContract: reconstructed DepositData does not match supplied deposit_data_root");
            }
            APEth.stake(  _pubKey2, _signature2, _deposit_data_root2);
            ethInValidators += 32 ether;
        }
        if (balance >= 96 ether) {
            vm.prank(staker);
            if (!workingKeys && block.chainid != 31337) {
                vm.expectRevert("DepositContract: reconstructed DepositData does not match supplied deposit_data_root");
            }
            APEth.stake(  _pubKey3, _signature3, _deposit_data_root3);
            ethInValidators += 32 ether;
        }
        uint256 newBalance = balance;
        if (workingKeys || block.chainid == 31337) newBalance = balance - ethInValidators;
        assertEq(address(APEth).balance, newBalance, "contract balance does not match calculated");
        assertEq(APEth.ethPerAPEth(), ethPerAPEth, "ethperAPEth not correct after staking");
        uint256 amount = uint256(x) + (uint256(z) * 1 ether / ethPerAPEth);
        assertEq(APEth.totalSupply(), uint256(x));
        vm.prank(owner);
        APEth.grantRole(EARLY_ACCESS, bob);
        if (amount > cap) vm.expectRevert(); //APETH__CAP_REACHED()
        hoax(bob);
        // Mint z eth of tokens and assert the balance
        APEth.mint{value: z}();
        uint256 expected = _calculateAmountLessFee(uint256(z) * 1 ether / ethPerAPEth);
        if (amount <= cap) {
            assertEq(APEth.balanceOf(bob), expected);
            assertEq(address(APEth).balance, newBalance + z);
        }
    }

    function test_ERC20Call() public {
        ERC20Mock mockCoin = new ERC20Mock();
        mockCoin.mint(address(APEth), 1 ether);
        assertEq(mockCoin.balanceOf(address(APEth)), 1 ether);
        vm.prank(admin);
        APEth.transferToken(  address(mockCoin), alice, 1 ether);
        assertEq(mockCoin.balanceOf(alice), 1 ether);
        assertEq(mockCoin.balanceOf(address(APEth)), 0);
    }

    function test_SSVCall() public {
        vm.prank(admin);
        APEth.callSSVNetwork(
            abi.encodeWithSelector(bytes4(keccak256("setFeeRecipientAddress(address)")), address(APEth))
        );
        if (block.chainid == 31337) {
            address ssvNetworkAddress =
                storageContract.getAddress(keccak256(abi.encodePacked("external.contract.address", "SSVNetwork")));
            MockSsvNetwork ssvNetwork = MockSsvNetwork(ssvNetworkAddress);
            address feeRecip = ssvNetwork.feeRecipient(address(APEth));
            assertEq(feeRecip, address(APEth), "feeRecip not set in ssv contract");
        }
    }

    function test_EigenPodManagerCall() public {
        vm.prank(admin);
        APEth.callEigenPodManager(abi.encodeWithSelector(IMockEigenPodManager.getPod.selector, address(APEth)));
    }

    function test_DelegationManagerCall() public {
        if (block.chainid != 31337) vm.expectRevert("Call failed");
        vm.prank(admin);
        APEth.callDelegationManager(abi.encodeWithSelector(IMockDelegationManager.undelegate.selector, address(APEth)), 0);
    }

    function test_EigenPodCall() public {
        vm.prank(admin);
        APEth.callEigenPod(abi.encodeWithSelector(IMockEigenPod.podOwner.selector));
    }

    function test_FeeChange() public {
        vm.prank(storageContract.getGuardian());
        storageContract.setUint(keccak256(abi.encodePacked("fee.Amount")), 10000);
        assertEq(storageContract.getUint(keccak256(abi.encodePacked("fee.Amount"))), 10000);
        vm.prank(owner);
        APEth.grantRole(EARLY_ACCESS, alice);
        hoax(alice);
        APEth.mint{value: 10 ether}();
        uint256 aliceBalance = _calculateAmountLessFee(10 ether);
        assertEq(APEth.balanceOf(alice), aliceBalance);
        assertEq(address(APEth).balance, 10 ether);
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
        assertEq(address(APEth).balance, 32 ether);

        // Do a second stake
        vm.prank(staker);
        vm.expectRevert(abi.encodeWithSelector(APETH__PUBKEY_ALREADY_USED.selector, _pubKey));
        APEth.stake(_pubKey, _signature, _deposit_data_root);
    }
}
