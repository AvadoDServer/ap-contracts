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
    ERC1967Proxy proxy;
    address owner;
    address newOwner;

    // Set up the test environment before running tests
    function setUp() public {
        // Deploy the token implementation
        APETH implementation = new APETH();
        // Define the owner address
        owner = vm.addr(1);
        // Deploy the proxy and initialize the contract through the proxy
        proxy = new ERC1967Proxy(address(implementation), abi.encodeCall(implementation.initialize, owner));
        // Attach the APETH interface to the deployed proxy
        APEth = APETH(address(proxy));
        // Define a new owner address for upgrade tests
        newOwner = address(1);
        // Emit the owner address for debugging purposes
        emit log_address(owner);
    }

    // Test the basic ERC20 functionality of the APETH contract
    function testERC20Functionality() public {
        // Impersonate the owner to call mint function
        vm.prank(owner);
        // Mint tokens to address(2) and assert the balance
        APEth.mint(address(2), 1000);
        assertEq(APEth.balanceOf(address(2)), 1000);
    }

    // Test the upgradeability of the APETH contract
    function testUpgradeability() public {
        // Upgrade the proxy to a new version; MyTokenV2
        Upgrades.upgradeProxy(address(proxy), "MyTokenV2.sol:MyTokenV2", "", owner);
    }
}
