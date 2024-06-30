// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {APETH} from "../src/APETH.sol";
import {APETHV2} from "../src/APETHV2.sol";
import {APEthStorage} from "../src/APEthStorage.sol";
import {APEthEarlyDeposits} from "../src/APEthEarlyDeposits.sol";
import {DeployStorageContract} from "../script/deployStorage.s.sol";
import {DeployProxy} from "../script/deployToken.s.sol";
import {DeployEarlyDeposits} from "../script/deployEarlyDepositOnly.s.sol";
import {UpgradeProxy} from "../script/upgradeProxy.s.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {MockSsvNetwork} from "./mocks/MockSsvNetwork.sol";
import {IMockEigenPodManager} from "./mocks/MockEigenPodManager.sol";
import {IMockEigenPod} from "./mocks/MockEigenPod.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Create2} from "@openzeppelin-contracts/utils/Create2.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "@eigenlayer-contracts/interfaces/IEigenPodManager.sol";

contract EarlyDepositTest is Test {
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
    address[] recipients;

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
        DeployEarlyDeposits deployEarlyDeposits = new DeployEarlyDeposits();

        (storageContract, implementation) = deployStorage.run(owner);
        (APEth) = deployProxy.run(owner, address(storageContract), address(implementation));
        //deploy early deposit contract sepatately
        earlyDeposits = deployEarlyDeposits.run(owner, ERC1967Proxy(payable(address(APEth))));
    }

    function testDeposit(uint128 x) public {
        assertEq(earlyDeposits.deposits(alice), 0);
        hoax(alice);
        earlyDeposits.deposit{value: uint256(x)}(alice);
        assertEq(earlyDeposits.deposits(alice), uint256(x));
        assertEq(address(earlyDeposits).balance, uint256(x));
    }

    modifier depositAlice(uint256 amount) {
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
        assertEq(earlyDeposits.deposits(alice), 0);
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
        recipients.push(alice);
        vm.prank(owner);
        earlyDeposits.mintAPEthBulk(recipients);
        uint256 aliceBalance = _calculateAmountLessFee(uint256(x));
        assertEq(APEth.balanceOf(alice), aliceBalance);
        assertEq(earlyDeposits.deposits(alice), 0);
    }

    function testBulkMint(uint64 a, uint64 b, uint64 c, uint64 d, uint64 e, uint64 f, uint64 aa)
        public
        depositAlice(uint256(a))
    {
        // deposit to early deposit contract
        hoax(bob);
        earlyDeposits.deposit{value: uint256(b)}(bob);
        hoax(vm.addr(69));
        earlyDeposits.deposit{value: uint256(c)}(vm.addr(69));
        hoax(vm.addr(70));
        earlyDeposits.deposit{value: uint256(d)}(vm.addr(70));
        hoax(vm.addr(71));
        earlyDeposits.deposit{value: uint256(e)}(vm.addr(71));
        hoax(vm.addr(72));
        earlyDeposits.deposit{value: uint256(f)}(vm.addr(72));
        hoax(vm.addr(73));
        earlyDeposits.deposit{value: uint256(aa)}(alice); // alice's friend sheldon gave her some extra
        // check the depositvalues
        assertEq(earlyDeposits.deposits(alice), uint256(a) + uint256(aa));
        assertEq(earlyDeposits.deposits(bob), uint256(b));
        assertEq(earlyDeposits.deposits(vm.addr(69)), uint256(c));
        assertEq(earlyDeposits.deposits(vm.addr(70)), uint256(d));
        assertEq(earlyDeposits.deposits(vm.addr(71)), uint256(e));
        assertEq(earlyDeposits.deposits(vm.addr(72)), uint256(f));
        // push addresses
        recipients.push(alice);
        recipients.push(bob);
        recipients.push(vm.addr(69));
        recipients.push(vm.addr(70));
        recipients.push(vm.addr(71));
        recipients.push(vm.addr(72));
        // mint the APEth
        vm.startPrank(owner);
        earlyDeposits.mintAPEthBulk(recipients);
        vm.stopPrank();
        // check the deposits are zeroed
        assertEq(earlyDeposits.deposits(alice), 0);
        assertEq(earlyDeposits.deposits(bob), 0);
        assertEq(earlyDeposits.deposits(vm.addr(69)), 0);
        assertEq(earlyDeposits.deposits(vm.addr(70)), 0);
        assertEq(earlyDeposits.deposits(vm.addr(71)), 0);
        assertEq(earlyDeposits.deposits(vm.addr(72)), 0);
        // check that they recieved their tokens
        uint256 aliceBalance = _calculateAmountLessFee(uint256(a) + uint256(aa));
        assertEq(APEth.balanceOf(alice), aliceBalance);
        uint256 bobBalance = _calculateAmountLessFee(uint256(b));
        assertEq(APEth.balanceOf(bob), bobBalance);
        uint256 sixNineBalance = _calculateAmountLessFee(uint256(c));
        assertEq(APEth.balanceOf(vm.addr(69)), sixNineBalance);
        uint256 sevenZeroBalance = _calculateAmountLessFee(uint256(d));
        assertEq(APEth.balanceOf(vm.addr(70)), sevenZeroBalance);
        uint256 sevenOneBalance = _calculateAmountLessFee(uint256(e));
        assertEq(APEth.balanceOf(vm.addr(71)), sevenOneBalance);
        uint256 sevenTwoBalance = _calculateAmountLessFee(uint256(f));
        assertEq(APEth.balanceOf(vm.addr(72)), sevenTwoBalance);
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
