// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APEthStorage, APETH, console, Create2, ERC1967Proxy, Upgrades} from "./scriptBase.s.sol";

contract transferOwnership is ScriptBase {
    address proxyAddress = 0xC5826d3734029766C780fE5eC2CcC14E710a84C9;
    address newOwner = 0xe250fbBc81Af47663a6E9a38eE77e96B1a93bf6B;
    APETH _APETH;

    function run() public {
        console.log("***Transfering ownership***");        
        _APEth = APETH(payable(proxyAddress));
        vm.startBroadcast();
        _APETH.transferOwnership(newOwner);
        vm.stopBroadcast();
    }
}
