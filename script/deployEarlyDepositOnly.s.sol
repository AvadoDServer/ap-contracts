// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {console} from "forge-std/console.sol";
import {
    ScriptBase,
    APEthEarlyDeposits,
    APETH,
    console,
    Create2,
    ERC1967Proxy,
    Upgrades,
    stdJson,
    ProxyConfig
} from "./scriptBase.s.sol";
import {HelperConfig, NetworkConfig} from "./HelperConfig.s.sol";

contract DeployEarlyDeposits is ScriptBase {
    function run(address owner, address earlydeposit_signer) public returns (APEthEarlyDeposits) {
        APEthEarlyDeposits ed = deployEarlyDeposit(owner, earlydeposit_signer);
        console.logString("address");
        console.logAddress(address(ed));
        return ed;
    }

    function run() public returns (APEthEarlyDeposits) {
        return run(address(0), address(0));
    }
}
