// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, ERC1967Proxy} from "./scriptBase.s.sol";

contract DeployEarlyDeposits is ScriptBase {
    run() public {
        _proxy = ERC1967Proxy(0x409fD1B18D8eA7bf3f1A04ef137Fb201d2D398A7); //change to desired contract address if different
        deployEarlyDeposit();
    }
}