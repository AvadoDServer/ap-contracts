// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/APETH.sol";
import "../src/APETHV2.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract APETHTest is Test {
    APETH APEth;
    APETH implementation;
    ERC1967Proxy proxy;
    address owner;
    address newOwner;
    address depositContract;
    address alice;

    bytes _pubKey = hex"aed26c6b7e0e2cc2efeae9c96611c3de6b982610e3be4bda9ac26fe8aea53276201b3e45dbc242bb24af7fb10fc12196";
    bytes _withdrawal_credentials = hex"0100000000000000000000002e234dae75c793f67a35089c9d99245e1c58470b";
    bytes _signature = hex"8fde897a0635609d54fa36a6601fe6388b28f2179ae1733d8c9ed0d6882bd431b123ace82cc5520514c3cfafdc92fe140d3120f0383981ccf864542732232aac2a262c587c5026eae0ed0cfa0a60cca9c554769ae64a60660dec832dc0519dec";
    bytes32 _deposit_data_root = 0x9f9f188f55d400cd7bdd1e602346d1a399a1d6d75ac171760bef36391327bdf6;

    bytes _pubKey2 = hex"91bebd77cd834b056ff242331dfcd3baecf3b89fcba6d866860a7ace128fb204af9b892cc84dd2d4eb933f6f8d0499b1";
    bytes _signature2 = hex"91dabec2eac585fc82bbae491f229601b6266388aa5ca6062b56d1fc353afff68f8f53b639221a9982b7ab6c7ce7a16700afe1fcdd25741197ebe09504de4f4f16372c1dc7ffcaf890b3291675b1520cdc953af978e38c61c97e6840a61b58ab";
    bytes32 _deposit_data_root2 = 0x3efa8da312e06de7c1ebdc53f0c5a5e72c4a220bc311c488e5bc9de4c79bded8;

    bytes _pubKey3 = hex"b6ee6088e5b1dca8a7013f702140ab1f4825d349b20f8c4ba8436af36814dfb3309c13d7423898f60c5e332655a54f17";
    bytes _signature3 = hex"965ba9733efc6a26deaff2f26c1e48afbc0663876b704f9b552b573861a8d94b26095541ac662bf064cfccdc542ce7e00e319dfdf3135e3fabfc1b2be8b53fc3e657cd45f1af1cd498842a79f59490040faae20df90bce965de8752c0eb995ac";
    bytes32 _deposit_data_root3 = 0x2930c69f919bc7843f0fa76e914b9b74687d2beaece9fd28fa839acaaaf1bc12;

    // Set up the test environment before running tests
    function setUp() public {
        // Deploy the token implementation
        implementation = new APETH();
        // Define the owner and alice addresses
        owner = vm.addr(1);
        alice = vm.addr(2);
        // Define Deposit Contract TODO: should check which chain we are deployig to to use correct address?
        depositContract = 0x4242424242424242424242424242424242424242; //holesky
        // depositContract = 0x00000000219ab540356cBB839Cbe05303d7705Fa; //minnet
        // Deploy the proxy and initialize the contract through the proxy
        proxy = new ERC1967Proxy(address(implementation), abi.encodeCall(implementation.initialize, (owner, depositContract)));
        // Attach the APETH interface to the deployed proxy
        APEth = APETH(payable(address(proxy)));
        // Define a new owner address for upgrade tests
        newOwner = address(1);
        // Emit the owner address for debugging purposes
        emit log_address(owner);
        emit log_address(address(proxy));
    }

    // Test the basic ERC20 functionality of the APETH contract
    function testERC20Functionality() public {
        // Impersonate the alice to call mint function
        hoax(alice);
        // Mint 1 eth of tokens and assert the balance
        APEth.mint{value: 1 ether}();
        assertEq(APEth.balanceOf(alice), 1 ether);
    }

    // Test the upgradeability of the APETH contract
    function testUpgradeability() public {
        //TODO: initialize upgraded contract (not sure why this didn't work)
        // Upgrade the proxy to a new version; APETHV2
        Upgrades.upgradeProxy(address(proxy), "APETHV2.sol:APETHV2", "", owner);
        emit log_address(address(APEth.depositContract()));
    }

    // Test staking (requires using a forked chain with a deposit contract to test.)
    function testStake() public {
        // Impersonate the alice to call mint function
        hoax(alice);
        // Mint 1 eth of tokens and assert the balance
        APEth.mint{value: 33 ether}();
        // Impersonate owner to call stake()
        assertEq(address(APEth).balance, 33 ether);
        vm.prank(owner);
        APEth.stake(
            _pubKey,
            _withdrawal_credentials,
            _signature,
            _deposit_data_root
        );

        assertEq(address(APEth).balance, 1 ether);
    }

    // test the accounting. the price should change predictibly when the contract recieves rewards
    function testBasicAccounting() public {
        hoax(alice);
        // Mint 10 eth of tokens and assert the balance
        APEth.mint{value: 10 ether}();
        assertEq(APEth.balanceOf(alice), 10 ether);
        assertEq(address(APEth).balance, 10 ether);
        // Send eth to contract to increase balance
        hoax(owner);
        payable(address(APEth)).transfer(1 ether);
        assertEq(address(APEth).balance, 11 ether);
        //check eth per apeth
        uint256 ethPerAPEth = 11 ether / 10;
        assertEq(APEth.ethPerAPEth(), ethPerAPEth);
        hoax(vm.addr(3));
        // Mint 10 eth of tokens and assert the balance
        APEth.mint{value: 10 ether}();
        uint256 expected = 10 ether * 1 ether / ethPerAPEth;
        assertEq(APEth.balanceOf(vm.addr(3)), expected);
        assertEq(address(APEth).balance, 21 ether);
    }

    function testBasicAccountingWithStaking() public {
        hoax(alice);
        // Mint 50 eth of tokens and assert the balance
        APEth.mint{value: 50 ether}();
        assertEq(APEth.balanceOf(alice), 50 ether);
        assertEq(address(APEth).balance, 50 ether);
        // Send eth to contract to increase balance
        hoax(owner);
        payable(address(APEth)).transfer(1 ether);
        assertEq(address(APEth).balance, 51 ether);
        //check eth per apeth
        uint256 ethPerAPEth = 51 ether / 50;
        assertEq(APEth.ethPerAPEth(), ethPerAPEth);
        vm.prank(owner);
        APEth.stake(
            _pubKey,
            _withdrawal_credentials,
            _signature,
            _deposit_data_root
        );
        assertEq(address(APEth).balance, 19 ether);
        assertEq(APEth.ethPerAPEth(), ethPerAPEth);
        hoax(vm.addr(3));
        // Mint 10 eth of tokens and assert the balance
        APEth.mint{value: 10 ether}();
        uint256 expected = 10 ether * 1 ether / ethPerAPEth;
        assertEq(APEth.balanceOf(vm.addr(3)), expected);
        assertEq(address(APEth).balance, 29 ether);
    }

    function testBasicAccountingWithStakingAndFuzzing(uint32 x, uint32 y, uint32 z) public {
        hoax(alice);
        // Mint x eth of tokens and assert the balance
        APEth.mint{value: x}();
        assertEq(APEth.balanceOf(alice), x);
        assertEq(address(APEth).balance, x);
        // Send eth to contract to increase balance
        vm.deal(owner, y);
        vm.prank(owner);
        payable(address(APEth)).transfer(y);
        uint256 balance = uint256(x) + uint256(y);
        assertEq(address(APEth).balance, balance);
        //check eth per apeth
        uint256 ethPerAPEth;
        if(x == 0) {
            ethPerAPEth =  1 ether;
        } else {
            ethPerAPEth = balance * 1 ether / uint256(x);
        }
        assertEq(APEth.ethPerAPEth(), ethPerAPEth);
        uint256 ethInValidators;
        if(balance >= 32 ether) {
            vm.prank(owner);
            APEth.stake(
                _pubKey,
                _withdrawal_credentials,
                _signature,
                _deposit_data_root
            );
            ethInValidators += 32 ether;
        }
        if(balance >= 64 ether) {
            vm.prank(owner);
            APEth.stake(
                _pubKey2,
                _withdrawal_credentials,
                _signature2,
                _deposit_data_root2
            );
            ethInValidators += 32 ether;
        }
        if(balance >= 96 ether) {
            vm.prank(owner);
            APEth.stake(
                _pubKey3,
                _withdrawal_credentials,
                _signature3,
                _deposit_data_root3
            );
            ethInValidators += 32 ether;
        }
        uint256 newBalance = balance - ethInValidators;
        assertEq(address(APEth).balance, newBalance);
        assertEq(APEth.ethPerAPEth(), ethPerAPEth);
        hoax(vm.addr(3));
        // Mint z eth of tokens and assert the balance
        APEth.mint{value: z}();
        uint256 expected = uint256(z) * 1 ether / ethPerAPEth;
        assertEq(APEth.balanceOf(vm.addr(3)), expected);
        assertEq(address(APEth).balance, newBalance + z);
    }
}
