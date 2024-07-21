// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MockSsvNetwork} from "../test/mocks/MockSsvNetwork.sol";
import {MockEigenPodManager} from "../test/mocks/MockEigenPodManager.sol";
import {MockDelegationManager} from "../test/mocks/MockDelegationManager.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address ssvNetwork;
        address eigenpodManager;
        address delegationManager;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 1) activeNetworkConfig = getMainnetConfig();
        if (block.chainid == 17000) activeNetworkConfig = getHoleskyConfig();
        //if(block.chainid == 11155111) activeNetworkConfig = getSepoliaConfig(); No ssv on sepolia
        if (block.chainid == 31337) activeNetworkConfig = getLocalConfig();
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            ssvNetwork: 0xDD9BC35aE942eF0cFa76930954a156B3fF30a4E1,
            eigenpodManager: 0x91E677b07F7AF907ec9a428aafA9fc14a0d3A338,
            delegationManager: 0x39053D51B77DC0d36036Fc1fCc8Cb819df8Ef37A
        });
        return mainnetConfig;
    }

    function getHoleskyConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory holeskyConfig = NetworkConfig({
            ssvNetwork: 0x38A4794cCEd47d3baf7370CcC43B560D3a1beEFA,
            eigenpodManager: 0x30770d7E3e71112d7A6b7259542D1f680a70e315,
            delegationManager: 0xA44151489861Fe9e3055d95adC98FbD462B948e7
        });
        return holeskyConfig;
    }

    function getLocalConfig() public returns (NetworkConfig memory) {
        console.log("***deploying mocks***");
        vm.startBroadcast();
        MockSsvNetwork _ssvNetwork = new MockSsvNetwork();
        MockEigenPodManager _eigenpodManager = new MockEigenPodManager();
        MockDelegationManager _delegationManager = new MockDelegationManager();
        vm.stopBroadcast();
        NetworkConfig memory localConfig =
            NetworkConfig({ssvNetwork: address(_ssvNetwork), eigenpodManager: address(_eigenpodManager), delegationManager: address(_delegationManager)});
        return localConfig;
    }
}
