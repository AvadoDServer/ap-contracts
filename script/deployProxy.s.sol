// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/MyToken.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Script.sol";

//TODO: combine the two deploy scripts
//TODO: use create2 and generate salt for vanity addresses
contract DeployUUPSProxy is Script {
    function run() public {

        address _implementation = 0x8Aaeb7fE983e7b264f7DbC67674c9cB428be39BE; // Replace with your token address
        vm.startBroadcast();

        // Encode the initializer function call
        bytes memory data = abi.encodeWithSelector(
            MyToken(_implementation).initialize.selector,
            msg.sender // Initial owner/admin of the contract
        );

        // Deploy the proxy contract with the implementation address and initializer
        ERC1967Proxy proxy = new ERC1967Proxy(_implementation, data);

        vm.stopBroadcast();
        // Log the proxy address
        console.log("UUPS Proxy Address:", address(proxy));
    }
}
