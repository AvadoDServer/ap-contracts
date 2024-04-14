// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {
    ScriptBase, APEthStorage, APETH, console, Create2, ERC1967Proxy, Upgrades, HelperConfig
} from "./scriptBase.s.sol";

contract DeployStorageContract is ScriptBase {
    function run(address owner_) public returns (APEthStorage, APETH) {
        _owner = owner_;
        _isTest = true;
        salt.apEth = 0x0000000000000000000000000000000000000000000000000101010101010101; //different salt to avoid collisions with deploied contracts (its annoying)
        //salt.implementation = 0x0000000000000000000000000000000000000000000000000101010101010101;
        //salt.storageContract = 0x0000000000000000000000000000000000000000000000000101010101010101;
        run();
        return (_storageContract, _implementation);
    }

    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        (_ssvNetwork, _eigenPodManager) = helperConfig.activeNetworkConfig();
        console.log("ssvNetwork", _ssvNetwork);
        console.log("eigenPodManager", _eigenPodManager);

        if (_owner == address(0)) _owner = msg.sender;
        console.log("***Deploying Storage***");
        
        //Deploy storage contract
        deployStorage();
        //initialize values
        if (_isTest) {
            vm.startBroadcast(_storageContract.getGuardian());
        } else {
            vm.startBroadcast();
        }
        //set SSV network address in storage
        _storageContract.setAddress(
            keccak256(abi.encodePacked("external.contract.address", "SSVNetwork")), _ssvNetwork
        );
        //Set eigen pod manager address in storage
        _storageContract.setAddress(
            keccak256(abi.encodePacked("external.contract.address", "EigenPodManager")), _eigenPodManager
        );
        //set fee recipient in storage
        _storageContract.setAddress(keccak256(abi.encodePacked("fee.recipient.address")), _owner);
        //set fee rate in storage
        _storageContract.setUint(keccak256(abi.encodePacked("fee.Amount")), 500); //fee units are in 1/1000ths of a percent so 500 = 0.5%
        vm.stopBroadcast();
        console.log("storage initialised");

        //Deploy the token implementation
        if (address(_storageContract).code.length == 0) {
            console.log("Deploy Storage contract first");
        } else {
            deployImplementation();
        }
    }
}
