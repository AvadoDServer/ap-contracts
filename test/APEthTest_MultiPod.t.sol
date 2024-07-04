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

contract APETHTestMultiPod is APEthTestSetup {
    function test_fuzz_DeployPod(uint8 x) public deployPods(x / 8) {
        // x / 8 bc all 256 takes way too long!
        assertEq(APEth.getPodIndex(), x / 8);
    }

    function test_BasicAccountingWithStakingAndFuzzing_MultiplePods(uint128 x, uint128 y, uint128 z)
        public
        mintAlice(x)
        deployPods(3)
    {
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
            if (!workingKeys && block.chainid != 31337) {
                vm.expectRevert("DepositContract: reconstructed DepositData does not match supplied deposit_data_root");
            }
            vm.prank(staker);
            APEth.stake(1, _pubKey, _signature_M, _deposit_data_root_M);
            vm.stopPrank();
            ethInValidators += 32 ether;
        }
        if (balance >= 64 ether) {
            if (!workingKeys && block.chainid != 31337) {
                vm.expectRevert("DepositContract: reconstructed DepositData does not match supplied deposit_data_root");
            }
            vm.prank(staker);
            APEth.stake(2, _pubKey2, _signature2_M, _deposit_data_root2_M);
            vm.stopPrank();
            ethInValidators += 32 ether;
        }
        if (balance >= 96 ether) {
            if (!workingKeys && block.chainid != 31337) {
                vm.expectRevert("DepositContract: reconstructed DepositData does not match supplied deposit_data_root");
            }
            vm.prank(staker);
            APEth.stake(3, _pubKey3, _signature3_M, _deposit_data_root3_M);
            vm.stopPrank();
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

    function test_ERC20Call_MultiPod() public deployPods(1) {
        ERC20Mock mockCoin = new ERC20Mock();
        mockCoin.mint(podWrapper, 1 ether);
        assertEq(mockCoin.balanceOf(podWrapper), 1 ether);
        vm.prank(admin);
        APEth.transferToken(1, address(mockCoin), alice, 1 ether);
        assertEq(mockCoin.balanceOf(alice), 1 ether);
        assertEq(mockCoin.balanceOf(podWrapper), 0);
    }

    function test_SSVCall_MultiPod() public deployPods(1) {
        vm.prank(admin);
        APEth.callSSVNetwork(
            1, abi.encodeWithSelector(bytes4(keccak256("setFeeRecipientAddress(address)")), address(wrapper))
        );
        if (block.chainid == 31337) {
            address ssvNetworkAddress =
                storageContract.getAddress(keccak256(abi.encodePacked("external.contract.address", "SSVNetwork")));
            MockSsvNetwork ssvNetwork = MockSsvNetwork(ssvNetworkAddress);
            address feeRecip = ssvNetwork.feeRecipient(address(wrapper));
            assertEq(feeRecip, address(wrapper), "feeRecip not set in ssv contract");
        }
    }

    function test_EigenPodManagerCall_multipod() public deployPods(1) {
        vm.prank(admin);
        APEth.callEigenPodManager(1, abi.encodeWithSelector(IMockEigenPodManager.getPod.selector, address(APEth)));
    }

    function test_EigenPodCall_multipod() public deployPods(1) {
        vm.prank(admin);
        APEth.callEigenPod(1, abi.encodeWithSelector(IMockEigenPod.podOwner.selector));
    }
}
