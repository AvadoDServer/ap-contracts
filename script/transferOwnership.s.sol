// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APEthStorage, APETH, console, Create2, ERC1967Proxy, Upgrades} from "./scriptBase.s.sol";

contract transferOwnership is ScriptBase {
    address newOwner = 0xa53A6fE2d8Ad977aD926C485343Ba39f32D3A3F6; //0xe250fbBc81Af47663a6E9a38eE77e96B1a93bf6B;
    APETH _APETH = APETH(payable(0xAAAAA0F868C6295c6738752C6c3eda803618BB8D));

    function run() public {
        console.log("***Transfering ownership***");        
        vm.startBroadcast();
        _APETH.transferOwnership(newOwner);
        vm.stopBroadcast();
        console.log("APETH Address:");
        console.logAddress(address(_APETH));
        console.log("newOwner:");
        console.logAddress(newOwner);
    }
}
