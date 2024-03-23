// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/APETH.sol";
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
    }
}
