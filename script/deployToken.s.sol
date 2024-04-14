// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APEthStorage, APETH, console, Create2, ERC1967Proxy, Upgrades} from "./scriptBase.s.sol";

contract DeployProxy is ScriptBase {
    function run(address owner_, address storage_, address implementation_) public returns (APETH) {
        _owner = owner_;
        _isTest = true;
        salt.apEth = 0x0000000000000000000000000000000000000000000000000101010101010101; //different salt to avoid collisions with deploied contracts (its annoying)
        //salt.implementation = 0x0000000000000000000000000000000000000000000000000101010101010101;
        //salt.storageContract = 0x0000000000000000000000000000000000000000000000000101010101010101;
        _storageContract = APEthStorage(storage_);
        _implementation = APETH(payable(implementation_));
        run();
        return (_APEth);
    }

    function run() public {
        console.log("***Deploying Implementation***");
        if (_owner == address(0)) _owner = msg.sender;

        if(!_isTest){
            salt.apEth = 0x0000000000000000000000000000000000000000000000000000000000000123; // calculate with vanity address generator manually enter
            _storageContract = APEthStorage(0xe66a3Eb56866420fF2a6CC6F114A6DF6Dd78F95c); //manually enter after deploying
            _implementation = APETH(payable(0x28eE43c5385219FB0A928da2107a128468b23193)); //manually enter after deploying
        }

        calcProxyAddress(); //here is where we could update the salt to have a vanity address (start with 'aaaaaa')
        deployProxy();
            
        _APEth = APETH(payable(_apEthPreDeploy));
    }
}
