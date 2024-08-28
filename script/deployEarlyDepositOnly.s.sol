// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, ERC1967Proxy, APETH, APEthEarlyDeposits} from "./scriptBase.s.sol";

contract DeployEarlyDeposits is ScriptBase {
    function run(address owner, address earlydeposit_signer) public returns (APEthEarlyDeposits) {
        return deployEarlyDeposit(owner,earlydeposit_signer);
    }

    // function run() public returns (APEthEarlyDeposits) {
    //     return run(address(0));
    // }
}
