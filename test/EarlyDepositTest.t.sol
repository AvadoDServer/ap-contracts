// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {APETH} from "../src/APETH.sol";
import {APETHV2} from "../src/APETHV2.sol";
import {APEthStorage} from "../src/APEthStorage.sol";
import {APEthEarlyDeposits} from "../src/APEthEarlyDeposits.sol";
import {DeployStorageContract} from "../script/deployStorage.s.sol";
import {DeployProxy} from "../script/deployToken.s.sol";
import {UpgradeProxy} from "../script/upgradeProxy.s.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {MockSsvNetwork} from "./mocks/MockSsvNetwork.sol";
import {IMockEigenPodManager} from "./mocks/MockEigenPodManager.sol";
import {IMockEigenPod} from "./mocks/MockEigenPod.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Create2} from "@openzeppelin-contracts/utils/Create2.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "@eigenlayer-contracts/interfaces/IEigenPodManager.sol";

contract EarlyDepositTest is Test{
    APETH APEth;
    APETH implementation;
    APEthStorage storageContract;
    APEthEarlyDeposits earlyDeposits;
    address owner;
    address newOwner;

    address alice;
    address bob;

    address staker;
    address upgrader;
    address admin;

    // Set up the test environment before running tests
    function setUp() public {
        console.log("chain ID: ", block.chainid);
        // Define the owner and alice addresses
        owner = vm.addr(1);
        console.log("owner", owner);
        alice = vm.addr(2);
        bob = vm.addr(3);
        staker = vm.addr(4);
        upgrader = vm.addr(5);
        admin = vm.addr(6);
        // Define a new owner address for upgrade tests
        newOwner = address(1);

        DeployStorageContract deployStorage = new DeployStorageContract();
        DeployProxy deployProxy = new DeployProxy();

        (storageContract, implementation) = deployStorage.run(owner);
        (APEth,earlyDeposits) = deployProxy.run(owner, address(storageContract), address(implementation));
    }

    function testDeposit(uint128 x) public {
        assertEq(earlyDeposits.deposits(alice), 0);
        hoax(alice);
        earlyDeposits.deposit{value: uint256(x)}(alice);
        assertEq(earlyDeposits.deposits(alice), uint256(x));
        assertEq(address(earlyDeposits).balance, uint256(x));
    }

    modifier depositAlice(uint256 amount){
        assertEq(earlyDeposits.deposits(alice), 0);
        hoax(alice);
        earlyDeposits.deposit{value: uint256(amount)}(alice);
        assertEq(earlyDeposits.deposits(alice), uint256(amount));
        assertEq(address(earlyDeposits).balance, uint256(amount));
        _;
    }

    function testWithdrawal(uint128 x) public depositAlice(uint256(x)) {
        uint256 aliceBalance = alice.balance;
        vm.prank(alice);
        earlyDeposits.withdraw();
        aliceBalance += uint256(x);
        assertEq(alice.balance, aliceBalance);
        assertEq(address(earlyDeposits).balance, 0);
    }

    function testFallback(uint128 x) public {
        assertEq(earlyDeposits.deposits(alice), 0);
        hoax(alice);
        (bool success,) = payable(address(earlyDeposits)).call{value: uint256(x)}("");
        assert(success);
        assertEq(earlyDeposits.deposits(alice), uint256(x));
        assertEq(address(earlyDeposits).balance, uint256(x));
    }

    function testMint(uint72 x) public depositAlice(uint256(x)) {
        vm.prank(owner);
        earlyDeposits.mintAPEth(alice);
        uint256 aliceBalance = _calculateAmountLessFee(uint256(x));
        assertEq(APEth.balanceOf(alice), aliceBalance);
    }

    //internal functions
    function _calculateFee(uint256 amount) internal view returns (uint256) {
        uint256 fee = amount * storageContract.getUint(keccak256(abi.encodePacked("fee.Amount"))) / 100000;
        return fee;
    }

    function _calculateAmountLessFee(uint256 amount) internal view returns (uint256) {
        return (amount - _calculateFee(amount));
    }
}