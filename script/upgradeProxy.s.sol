// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APETH, APETHV2, Upgrades, IAPETHWithdrawalQueueTicket, Options} from "./scriptBase.s.sol";

contract UpgradeProxy is ScriptBase {
    address _proxyAddress;
    Options _options;

    function run(address apEth, address owner, IAPETHWithdrawalQueueTicket withdrawalQueue) public {
        _options.constructorData = abi.encode(
                vm.envAddress("EIGEN_POD_MANAGER"), //TODO: move from .env to helper config
                vm.envAddress("DELEGATION_MANAGER"), //TODO: move from .env to helper config
                vm.envAddress("SSV_NETWORK"), //TODO: move from .env to helper config
                1000
        );

        vm.broadcast();
        Upgrades.upgradeProxy(
            apEth, "APETHV2.sol:APETHV2", abi.encodeCall(APETHV2.initialize, (withdrawalQueue)), _options, owner
        );
    }

    function run() public {
        address owner = vm.envAddress("CONTRACT_OWNER");
        address apEth = vm.envAddress("APETH_PROXY");
        address withdrawalQueue = vm.envAddress("WITHDRAWAL_QUEUE");

        if (apEth == address(0)) {
            apEth = getProxyAddress();
        }

        run(apEth, owner, IAPETHWithdrawalQueueTicket(withdrawalQueue));
    }
}
