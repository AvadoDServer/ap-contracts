// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    ScriptBase,
    APEthEarlyDeposits,
    APETH,
    console,
    Create2,
    ERC1967Proxy,
    Upgrades,
    stdJson,
    ProxyConfig
} from "./scriptBase.s.sol";
import {HelperConfig, NetworkConfig} from "./HelperConfig.s.sol";

contract DeployProxy is ScriptBase {
    function run(ProxyConfig memory config, address implementation) public returns (APETH) {
        return deployProxy(implementation, config);
    }

    function run(ProxyConfig memory config) public returns (APETH) {
        return run(config, address(deployApEth(config)));
    }

    function run() public returns (APETH) {
        ProxyConfig memory config;
        config.network = new HelperConfig().getConfig();
        config.salt = vm.envBytes32("SALT");

        return run(config);
    }
}

contract DeployImplementation is ScriptBase {
    function run(ProxyConfig memory config) public returns (APETH) {
        _implementation = deployApEth(config);
        computeProxyInitCodeHash();
        return _implementation;
    }

    function run() public returns (APETH) {
        ProxyConfig memory config;
        config.network = new HelperConfig().getConfig();
        config.salt = vm.envBytes32("SALT");

        return run(config);
    }
}

contract DeployProxyWithCreate2 is ScriptBase {
    function run(ProxyConfig memory config, address implementation) public returns (APETH) {
        return deployProxy(implementation, config);
    }

    function run() public returns (APETH) {
        ProxyConfig memory config;
        config.network = new HelperConfig().getConfig();
        config.salt = vm.envBytes32("SALT");

        APETH proxy = run(config, getDeployedAddress());

        vm.startBroadcast();
        proxy.grantRole(_EARLY_ACCESS, vm.envAddress("EARLY_ACCESS"));
        proxy.grantRole(_UPGRADER, vm.envAddress("UPGRADER"));
        proxy.grantRole(_MISCELLANEOUS, vm.envAddress("MISCELLANEOUS"));
        proxy.grantRole(_SSV_NETWORK_ADMIN, vm.envAddress("SSV_NETWORK_ADMIN"));
        proxy.grantRole(_DELEGATION_MANAGER_ADMIN, vm.envAddress("DELEGATION_MANAGER_ADMIN"));
        proxy.grantRole(_EIGEN_POD_ADMIN, vm.envAddress("EIGEN_POD_ADMIN"));
        proxy.grantRole(_EIGEN_POD_MANAGER_ADMIN, vm.envAddress("EIGEN_POD_MANAGER_ADMIN"));
        proxy.grantRole(_ADMIN, config.admin);
        proxy.grantRole(_UPGRADER, config.DEPLOYER_PUBLIC_KEY);
        proxy.setFeeRecipient(config.admin);
        proxy.renounceRole(_UPGRADER, config.DEPLOYER_PUBLIC_KEY);
        proxy.renounceRole(_ADMIN, config.DEPLOYER_PUBLIC_KEY);
        vm.stopBroadcast();
        return proxy;
    }
}
