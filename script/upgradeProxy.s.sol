// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APETH, APETHV2, Upgrades, IAPETHWithdrawalQueueTicket} from "./scriptBase.s.sol";

contract UpgradeProxy is ScriptBase {
    address _proxyAddress;

    function run(address apEth, address owner, IAPETHWithdrawalQueueTicket withdrawalQueue) public {
        Upgrades.upgradeProxy(apEth, "APETHV2.sol:APETH", abi.encodeCall(APETHV2.initialize, (withdrawalQueue)), owner);
    }

    function run() public {
        address owner = vm.envAddress("CONTRACT_OWNER");
        address apEth = vm.envAddress("APETH_PROXY");
        address withdrawalQueue = vm.envAddress("WITHDRAWAL_QUEUE");

        if (apEth == address(0)) {
            apEth = getProxyAddress();
        }

        vm.broadcast();
        run(apEth, owner, IAPETHWithdrawalQueueTicket(withdrawalQueue));
    }
}
