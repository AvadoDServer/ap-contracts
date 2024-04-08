// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APEthStorage, APETH, console, Create2, ERC1967Proxy, Upgrades} from "./scriptBase.s.sol";

contract DeployTokenImplementation is ScriptBase {
    
    function run(address owner_) public returns (APETH, APETH) {
        _owner = owner_;
        _isTest = true;
        salt.apEth = 0x0000000000000000000000000000000000000000000000000101010101010101; //different salt to avoid collisions with deploied contracts (its annoying)
        //salt.implementation = 0x0000000000000000000000000000000000000000000000000101010101010101;
        salt.storageContract = 0x0000000000000000000000000000000000000000000000000101010101010101;
        run();
        return (_implementation, _APEth);
    }

    function run() public returns (APETH, APETH) {
        console.log("***Deploying Implementation***");
        if (_owner == address(0)) _owner = msg.sender;

        //calculate addresses TODO: WRITE CREATE2 SCRIPT TO CALC SALT TO ADD A BUNCH OF A's AT THE BEGINNING OF THE CONTRACTS
        //storage
        calcStorageAddress();
        

        // Deploy the token implementation
        if (_implementationAddressPreDeploy.code.length == 0 && _apEthPreDeploy.code.length == 0) {
            //Deploy the token implementation
            if (_storageContractPreDeploy.code.length == 0) {
                console.log("Deploy Storage contract first");
            } else {
                deployImplementation();
                calcProxyAddress(); //here is where we could update the salt to have a vanity address (start with 'aaaaaa')
                deployProxy();
            }

        } else if (_implementationAddressPreDeploy.code.length != 0 && _apEthPreDeploy.code.length == 0) {
            _implementation = APETH(payable(_implementationAddressPreDeploy));
            console.log("implementation exists", _implementationAddressPreDeploy);
        } else if (_implementationAddressPreDeploy.code.length == 0 && _apEthPreDeploy.code.length != 0) {
            console.log("Use Upgrade Script", address(_APEth));
        } else {
            console.log("Proxy exists", _apEthPreDeploy);
            console.log("implementation exists", _implementationAddressPreDeploy);
        }
        _APEth = APETH(payable(_apEthPreDeploy));

        return (_implementation, _APEth);
    }


}
