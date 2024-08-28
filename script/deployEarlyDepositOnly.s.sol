// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, ERC1967Proxy, APETH, APEthEarlyDeposits} from "./scriptBase.s.sol";

contract DeployEarlyDeposits is ScriptBase {
    function run(address owner) public returns (APEthEarlyDeposits) {
        return deployEarlyDeposit(owner);
    }

    function run() public returns (APEthEarlyDeposits) {
        return run(address(0));
    }
}
