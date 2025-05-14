// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APETHV3, console, Create2, ERC1967Proxy, Upgrades} from "./scriptBase.s.sol";

contract enableWithdrawals is ScriptBase {
    APETHV3 private _APEth;

    function run() public {
        _APEth = APETHV3(payable(getProxyAddress()));
        _APEth.setActiveValidators(0);
    }
}
