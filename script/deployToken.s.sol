// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/MyToken.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Script.sol";

contract DeployTokenImplementation is Script {
    function run() public {

//TODO: use create2 and generate salt for vanity addresses
        // Use address provided in config to broadcast transactions
        vm.startBroadcast();
        // Deploy the ERC-20 token
        MyToken implementation = new MyToken();

        // Encode the initializer function call
        bytes memory data = abi.encodeWithSelector(
            implementation.initialize.selector,
            msg.sender // Initial owner/admin of the contract
        );

        // Deploy the proxy contract with the implementation address and initializer
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), data);

        vm.stopBroadcast();
        // Log the token address
        console.log("Token Implementation Address:", address(implementation));

        // Log the proxy address
        console.log("UUPS Proxy Address:", address(proxy));


    }
}
