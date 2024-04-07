// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APEthStorage, APETH, console, Create2, ERC1967Proxy, Upgrades} from "./scriptBase.s.sol";

error DEPLOY_PROXY__MUST_DEPLOY_IMPLEMENTATION_FIRST();
error DEPLOY_PROXY__MUST_CALC_ADDRESS_FIRST(string);

contract DeployTokenProxy is ScriptBase {
    
    function run(address owner_) public returns(APEthStorage, APETH, APETH) {
        _owner = owner_;
        _isTest = true;
        salt.apEth = 0x0000000000000000000000000000000000000000000000000101010101010101; //different salt to avoid collisions with deploied contracts (its annoying)
        salt.implementation = 0x0000000000000000000000000000000000000000000000000101010101010101;
        salt.storageContract = 0x0000000000000000000000000000000000000000000000000101010101010101;
        run();
        return (_storageContract, _implementation, _APEth);
    }

    function run() public returns (APEthStorage, APETH,APETH) {
        console.log("***Deploying Proxy***");
        if (_owner == address(0)) _owner = msg.sender;

        //calculate addresses TODO: WRITE CREATE2 SCRIPT TO CALC SALT TO ADD A BUNCH OF A's AT THE BEGINNING OF THE CONTRACTS
        //storage
        calcStorageAddress();
        //implementation
        calcImplementationAddress();
        //apEth(technically the proxy)
        calcProxyAddress();
       
        //make sure the implementation was deployed first
        if (_implementationAddressPreDeploy.code.length == 0) revert DEPLOY_PROXY__MUST_DEPLOY_IMPLEMENTATION_FIRST();
        // Deploy the token implementation
        if (_apEthPreDeploy.code.length != 0) {
            console.log("Proxy exists Use Upgrade Script", address(_APEth));
        } else {
            deployProxy(); 
        }

        return (_storageContract, _implementation, _APEth);
    }


}
