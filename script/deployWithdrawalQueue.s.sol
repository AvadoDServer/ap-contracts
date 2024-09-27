// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APETHWithdrawalQueueTicket, ProxyConfig, HelperConfig} from "./scriptBase.s.sol";

contract DeployWithdrawalQueue is ScriptBase {
    function run(ProxyConfig memory config) public returns (APETHWithdrawalQueueTicket) {
        return deployAPETHWithdrawalQueueTicket(config);
    }

    function run() public returns (APETHWithdrawalQueueTicket) {
        ProxyConfig memory config;
        config.network = new HelperConfig().getConfig();
        return run(config);
    }
}
