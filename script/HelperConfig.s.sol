// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MockSsvNetwork} from "../test/mocks/MockSsvNetwork.sol";
import {MockEigenPodManager} from "../test/mocks/MockEigenPodManager.sol";
import {MockDelegationManager} from "../test/mocks/MockDelegationManager.sol";

struct NetworkConfig {
    address ssvNetwork;
    address eigenPodManager;
    address delegationManager;
}

contract HelperConfig is Script {
    NetworkConfig private _localConfig;

    function getConfig() public returns (NetworkConfig memory) {
        if (block.chainid == 1) {
            return getMainnetConfig();
        }

        if (block.chainid == 17000) {
            return getHoleskyConfig();
        }

        if (block.chainid == 31337) {
            return getLocalConfig();
        }

        NetworkConfig memory config;
        return config;
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            ssvNetwork: 0xDD9BC35aE942eF0cFa76930954a156B3fF30a4E1,
            eigenPodManager: 0x91E677b07F7AF907ec9a428aafA9fc14a0d3A338,
            delegationManager: 0x39053D51B77DC0d36036Fc1fCc8Cb819df8Ef37A
        });
        return mainnetConfig;
    }

    function getHoleskyConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory holeskyConfig = NetworkConfig({
            ssvNetwork: 0x38A4794cCEd47d3baf7370CcC43B560D3a1beEFA,
            eigenPodManager: 0x30770d7E3e71112d7A6b7259542D1f680a70e315,
            delegationManager: 0xA44151489861Fe9e3055d95adC98FbD462B948e7
        });
        return holeskyConfig;
    }

    function getLocalConfig() public returns (NetworkConfig memory) {
        if (_localConfig.eigenPodManager == address(0)) {
            _localConfig = NetworkConfig({
                ssvNetwork: address(new MockSsvNetwork()),
                eigenPodManager: address(new MockEigenPodManager()),
                delegationManager: address(new MockDelegationManager())
            });
        }

        return _localConfig;
    }
}
