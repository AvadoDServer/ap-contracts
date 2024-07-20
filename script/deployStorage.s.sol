// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {
    ScriptBase, APEthStorage, APETH, console, Create2, ERC1967Proxy, Upgrades, HelperConfig
} from "./scriptBase.s.sol";

contract DeployStorageContract is ScriptBase {
    uint256 _initialCap = 100000 ether;
    uint256 _initialFee = 500; //fee units are in 1/1000ths of a percent so 500 = 0.5%

    function run(address owner_) public returns (APEthStorage, APETH) {
        _owner = owner_;
        _isTest = true;
        run();
        return (_storageContract, _implementation);
    }

    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        (_ssvNetwork, _eigenPodManager, _delegationManager) = helperConfig.activeNetworkConfig();
        console.log("ssvNetwork", _ssvNetwork);
        console.log("eigenPodManager", _eigenPodManager);
        console.log("delegationManager", _delegationManager);

        if (_owner == address(0)) _owner = vm.envAddress("CONTRACT_OWNER");
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
        _storageContract.setAddress(keccak256(abi.encodePacked("external.contract.address", "SSVNetwork")), _ssvNetwork);
        //Set eigen pod manager address in storage
        _storageContract.setAddress(
            keccak256(abi.encodePacked("external.contract.address", "EigenPodManager")), _eigenPodManager
        );
        //Set delegation manager address in storage
        _storageContract.setAddress(
            keccak256(abi.encodePacked("external.contract.address", "DelegationManager")), _delegationManager
        );
        //set fee recipient in storage
        _storageContract.setAddress(keccak256(abi.encodePacked("fee.recipient.address")), _owner);
        //set fee rate in storage
        _storageContract.setUint(keccak256(abi.encodePacked("fee.Amount")), _initialFee);
        //set initial mint cap amount
        _storageContract.setUint(keccak256(abi.encodePacked("cap.Amount")), _initialCap);
        console.log("storage initialised");
        vm.stopBroadcast();

        //Deploy the token implementation
        if (address(_storageContract).code.length == 0) {
            console.log("Deploy Storage contract first");
        } else {
            deployImplementation();
        }

        computeProxyInitCodeHash();
    }
}
