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

contract APETHTest is Test {
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

    bytes32 public constant UPGRADER = keccak256("UPGRADER");
    bytes32 public constant ETH_STAKER = keccak256("ETH_STAKER");
    bytes32 public constant EARLY_ACCESS = keccak256("EARLY_ACCESS");
    bytes32 public constant ADMIN = keccak256("ADMIN");

    //set bool to "true" when fresh keys are added, set to "false" to kill "reconstructed DepositData does not match supplied deposit_data_root"
    bool workingKeys = false;

    bytes _pubKey =
        hex"aed26c6b7e0e2cc2efeae9c96611c3de6b982610e3be4bda9ac26fe8aea53276201b3e45dbc242bb24af7fb10fc12196";
    bytes _signature =
        hex"896a621b4e4fad8d14108111c45141370572882362f40b4a6c4c9bce3f1b13c9e59774a270198448b4e535638916d71d0edbe18a74bc9b087972dbf60c14ef214f77fac423848d75f377ae1214cc0dcb09e2b1f3d2da60e74ac9540d8c6b62c7";
    bytes32 _deposit_data_root = 0x955de0af387a6cc447bb8f2b5554c51245e2239426c7a251381f3175bf99769a;

    bytes _pubKey2 =
        hex"91bebd77cd834b056ff242331dfcd3baecf3b89fcba6d866860a7ace128fb204af9b892cc84dd2d4eb933f6f8d0499b1";
    bytes _signature2 =
        hex"b00761c3426f8df64b5f048edc547b6478e947261ca9a9fbd88afdbbb7463f430fbf46a276d392c39113bd05b034f21905958415f561ca842a3b094a52d8d5651c8866b6ac4a6a37b3ac1fd5bcc1a483966127a30e41eafed621d9aa48734553";
    bytes32 _deposit_data_root2 = 0x657fe2c0d7a9ea7cc56cdad00edd249f4bf7a9f48f845b4f2d4bbcd5f241ca46;

    bytes _pubKey3 =
        hex"b6ee6088e5b1dca8a7013f702140ab1f4825d349b20f8c4ba8436af36814dfb3309c13d7423898f60c5e332655a54f17";
    bytes _signature3 =
        hex"96dcbfd6aa228d56f81cc2ebb0145db72c12a295d531c37f955bb1ab6dfcd0f8fe8ecb0f134cd026fa32520d0fd6ef100e375f697eb0ee441d47a54cdd0a5fcd5598eab5f8d35fd8fdd812a6f3897a8dd972183f1b5a5fc9aa000051e6106376";
    bytes32 _deposit_data_root3 = 0x02d2bd6e36896af49cebf39e52e6a0ae926dfaa8dfbd70cad4188e3aa12e3bae;

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
        (APEth) = deployProxy.run(owner, address(storageContract), address(implementation));
    }

    //test minting the coin
    function testMint() public {
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

    modifier mintAlice(uint256 amount) {
        vm.prank(owner);
        APEth.grantRole(EARLY_ACCESS, alice);
        uint256 cap = storageContract.getUint(keccak256(abi.encodePacked("cap.Amount")));
        uint256 aliceBalance = _calculateAmountLessFee(amount);
        if (amount > cap) {
            aliceBalance = 0;
            vm.expectRevert(); //APETH__CAP_REACHED()
        }
        hoax(alice);
        APEth.mint{value: amount}();
        assertEq(APEth.balanceOf(alice), aliceBalance);
        if (amount > cap) {
            vm.expectRevert(); //APETH__CAP_REACHED()
        }
        assertEq(address(APEth).balance, amount);
        _;
    }

    function testCap() public mintAlice(100000 ether) {
        uint256 aliceBalance = APEth.balanceOf(alice);
        vm.expectRevert(); //APETH__CAP_REACHED()
        hoax(alice);
        APEth.mint{value: 1}();
        assertEq(APEth.balanceOf(alice), aliceBalance);
    }

    // Test the basic ERC20 functionality of the APETH contract
    function testERC20Functionality() public mintAlice(10 ether) {
        uint256 aliceBalance = _calculateAmountLessFee(10 ether);
        //transfer to bob
        vm.prank(alice);
        APEth.transfer(bob, 5 ether);
        assertEq(APEth.balanceOf(bob), 5 ether);
        assertEq(APEth.balanceOf(alice), aliceBalance - 5 ether);
        assertEq(address(APEth).balance, 10 ether);
    }

    // Test the upgradeability of the APETH contract
    function testUpgradeability() public {
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
    function testStake() public {
        //branch test for case where totalsupply is 0
        assertEq(APEth.ethPerAPEth(), 1 ether);
        //Grant Alice Early Access
        vm.prank(owner);
        APEth.grantRole(EARLY_ACCESS, alice);
        // Impersonate the alice to call mint function
        hoax(alice);
        // Mint 33 eth of tokens and assert the balance
        APEth.mint{value: 33 ether}();
        vm.prank(owner);
        APEth.grantRole(ETH_STAKER, staker);
        assertEq(address(APEth).balance, 33 ether);
        if (!workingKeys && block.chainid != 31337) {
            vm.expectRevert("DepositContract: reconstructed DepositData does not match supplied deposit_data_root");
        }
        // Impersonate staker to call stake()
        vm.prank(staker);
        APEth.stake(_pubKey, _signature, _deposit_data_root);
        if (workingKeys) assertEq(address(APEth).balance, 1 ether);
    }

    // test the accounting. the price should change predictibly when the contract recieves rewards
    function testBasicAccounting() public mintAlice(10 ether) {
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

    function testBasicAccountingWithStaking() public mintAlice(50 ether) {
        // Send eth to contract to increase balance
        payable(address(APEth)).transfer(1 ether);
        assertEq(address(APEth).balance, 51 ether);
        //check eth per apeth
        uint256 ethPerAPEth = 51 ether / 50;
        assertEq(APEth.ethPerAPEth(), ethPerAPEth);
        vm.prank(owner);
        APEth.grantRole(ETH_STAKER, staker);
        vm.prank(staker);
        if (!workingKeys && block.chainid != 31337) {
            vm.expectRevert("DepositContract: reconstructed DepositData does not match supplied deposit_data_root");
        }
        APEth.stake(_pubKey, _signature, _deposit_data_root);
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

    function testBasicAccountingWithStakingAndFuzzing(uint128 x, uint128 y, uint128 z) public mintAlice(x) {
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
            vm.prank(owner);
            APEth.grantRole(ETH_STAKER, staker);
            vm.prank(staker);
            if (!workingKeys && block.chainid != 31337) {
                vm.expectRevert("DepositContract: reconstructed DepositData does not match supplied deposit_data_root");
            }
            APEth.stake(_pubKey, _signature, _deposit_data_root);
            ethInValidators += 32 ether;
        }
        if (balance >= 64 ether) {
            vm.prank(staker);
            if (!workingKeys && block.chainid != 31337) {
                vm.expectRevert("DepositContract: reconstructed DepositData does not match supplied deposit_data_root");
            }
            APEth.stake(_pubKey2, _signature2, _deposit_data_root2);
            ethInValidators += 32 ether;
        }
        if (balance >= 96 ether) {
            vm.prank(staker);
            if (!workingKeys && block.chainid != 31337) {
                vm.expectRevert("DepositContract: reconstructed DepositData does not match supplied deposit_data_root");
            }
            APEth.stake(_pubKey3, _signature3, _deposit_data_root3);
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

    function testStakeFailNotEnoughEth() public mintAlice(5) {
        vm.prank(owner);
        APEth.grantRole(ETH_STAKER, staker);
        vm.prank(staker);
        vm.expectRevert(0x82deecdf); //"APETH__NOT_ENOUGH_ETH()"
        APEth.stake(_pubKey, _signature, _deposit_data_root);
    }

    function testStakeFailNotOwner() public mintAlice(32 ether) {
        vm.prank(vm.addr(69));
        vm.expectRevert(); // "OwnableUnauthorizedAccount(0x1326324f5A9fb193409E10006e4EA41b970Df321)"
        APEth.stake(_pubKey, _signature, _deposit_data_root);
    }

    function testERC20Call() public {
        ERC20Mock mockCoin = new ERC20Mock();
        mockCoin.mint(address(APEth), 1 ether);
        assertEq(mockCoin.balanceOf(address(APEth)), 1 ether);
        vm.prank(owner);
        APEth.grantRole(ADMIN, admin);
        vm.prank(admin);
        APEth.transferToken(address(mockCoin), alice, 1 ether);
        assertEq(mockCoin.balanceOf(alice), 1 ether);
        assertEq(mockCoin.balanceOf(address(APEth)), 0);
    }

    function testERC20CallFailNotOwner() public {
        ERC20Mock mockCoin = new ERC20Mock();
        mockCoin.mint(address(APEth), 1 ether);
        vm.prank(vm.addr(69));
        vm.expectRevert(); // "OwnableUnauthorizedAccount(0x1326324f5A9fb193409E10006e4EA41b970Df321)"
        APEth.transferToken(address(mockCoin), alice, 1 ether);
    }

    function testSSVCall() public {
        vm.prank(owner);
        APEth.grantRole(ADMIN, admin);
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

    function testSSVCallFailNotOwner() public {
        vm.prank(vm.addr(69));
        vm.expectRevert(); // "OwnableUnauthorizedAccount(0x1326324f5A9fb193409E10006e4EA41b970Df321)"
        APEth.callSSVNetwork(
            abi.encodeWithSelector(bytes4(keccak256("setFeeRecipientAddress(address)")), address(APEth))
        );
    }

    function testSSVCallFailBadCall() public {
        vm.prank(owner);
        APEth.grantRole(ADMIN, admin);
        vm.prank(admin);
        vm.expectRevert("Call failed");
        APEth.callSSVNetwork(
            abi.encodeWithSelector(bytes4(keccak256("someFunctionThatDoesNotExist(address)")), address(APEth))
        );
    }

    function testEigenPodManagerCall() public {
        vm.prank(owner);
        APEth.grantRole(ADMIN, admin);
        vm.prank(admin);
        APEth.callEigenPodManager(abi.encodeWithSelector(IMockEigenPodManager.getPod.selector, address(APEth)));
    }

    function testEigenPodManagerCallFailNotOwner() public {
        vm.prank(vm.addr(69));
        vm.expectRevert(); // "OwnableUnauthorizedAccount(0x1326324f5A9fb193409E10006e4EA41b970Df321)"
        APEth.callEigenPodManager(abi.encodeWithSelector(IMockEigenPodManager.getPod.selector, address(APEth)));
    }

    function testEigenPodManagerCallFailBadCall() public {
        vm.prank(owner);
        APEth.grantRole(ADMIN, admin);
        vm.prank(admin);
        vm.expectRevert("Call failed");
        APEth.callEigenPodManager(
            abi.encodeWithSelector(bytes4(keccak256("someFunctionThatDoesNotExist(address)")), address(APEth))
        );
    }

    function testEigenPodCall() public {
        vm.prank(owner);
        APEth.grantRole(ADMIN, admin);
        vm.prank(admin);
        APEth.callEigenPod(0, abi.encodeWithSelector(IMockEigenPod.podOwner.selector));
    }

    function testEigenPodCallFailNotOwner() public {
        vm.prank(vm.addr(69));
        vm.expectRevert(); // "OwnableUnauthorizedAccount(0x1326324f5A9fb193409E10006e4EA41b970Df321)"
        APEth.callEigenPod(0, abi.encodeWithSelector(IMockEigenPod.podOwner.selector));
    }

    function testEigenPodCallFailBadCall() public {
        vm.prank(owner);
        APEth.grantRole(ADMIN, admin);
        vm.prank(admin);
        vm.expectRevert("Call failed");
        APEth.callEigenPod(0, abi.encodeWithSelector(bytes4(keccak256("someFunctionThatDoesNotExist()"))));
    }

    function testFeeChange() public {
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

    function testDeployPod() public {
        //
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
