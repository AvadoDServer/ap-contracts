// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APEthEarlyDeposits, APETH, console, Create2, ERC1967Proxy, Upgrades, stdJson, ProxyConfig} from "./scriptBase.s.sol";
import {HelperConfig, NetworkConfig} from "./HelperConfig.s.sol";

contract DeployProxy is ScriptBase {
    function run(
        ProxyConfig memory config,
        address implementation
    ) public returns (APETH) {
        return deployProxy(implementation, config);
    }

    function run(ProxyConfig memory config) public returns (APETH) {
        return run(config, address(new APETH()));
    }

    function run() public returns (APETH) {
        ProxyConfig memory config;
        config.network = new HelperConfig().getConfig();
        config.salt = vm.envBytes32("SALT");

        return run(config);
    }
}
