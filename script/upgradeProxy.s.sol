// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APEthStorage, APETH, console, Create2, ERC1967Proxy, Upgrades} from "./scriptBase.s.sol";



error DEPLOY_PROXY__MUST_DEPLOY_IMPLEMENTATION_FIRST();
error DEPLOY_PROXY__MUST_CALC_ADDRESS_FIRST(string);

contract UpgradeProxy is ScriptBase {
    address _proxyAddress = 0x41a818122Cf340b69A3106c209c20171Cad1f5B6; //insure that this uses the correct proxy address!!!
    
    function run(address owner_, address proxyAddress_) public {
        _owner = owner_;
        _proxyAddress = proxyAddress_;
        _isTest = true;
        salt.apEth = 0x0000000000000000000000000000000000000000000000000101010101010101; //different salt to avoid collisions with deploied contracts (its annoying)
        //salt.implementation = 0x0000000000000000000000000000000000000000000000000101010101010101;
        salt.storageContract = 0x0000000000000000000000000000000000000000000000000101010101010101;
        run();
    }

    function run() public {
        console.log("***Upgrading Proxy***");
        if (_owner == address(0)) _owner = msg.sender;
        if(!_isTest) vm.startBroadcast();
        Upgrades.upgradeProxy(_proxyAddress, "APETHV2.sol:APETHV2", "", _owner);
        if(!_isTest) vm.stopBroadcast();
        console.log("upgraded");
    }


}
