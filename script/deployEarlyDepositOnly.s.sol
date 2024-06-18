// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, ERC1967Proxy, APETH} from "./scriptBase.s.sol";

contract DeployEarlyDeposits is ScriptBase {
    function run() public {
        address payable proxyAddy = payable(0xAAAAAF0623026CC96BF58bAcB0f68b5e75980212); //change to desired contract address if different
        _proxy = ERC1967Proxy(proxyAddy); 
        _APEth = APETH(proxyAddy);
        deployEarlyDeposit();
    }
}