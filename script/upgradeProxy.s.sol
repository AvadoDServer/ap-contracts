// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APETH, APETHV2, Upgrades, IAPETHWithdrawalQueueTicket, Options} from "./scriptBase.s.sol";

contract UpgradeProxy is ScriptBase {
    address _proxyAddress;
    Options _options;

    function run(address apEth, address upgrader, IAPETHWithdrawalQueueTicket withdrawalQueue, Options memory options)
        public
    {
        Upgrades.upgradeProxy(
            apEth, "APETHV2.sol:APETHV2", abi.encodeCall(APETHV2.initialize, (withdrawalQueue)), options, upgrader
        );
    }

    function run() public {
        // address owner = vm.envAddress("CONTRACT_OWNER");
        // address apEth = vm.envAddress("APETH_PROXY");
        // address withdrawalQueue = vm.envAddress("WITHDRAWAL_QUEUE");
        // _options.constructorData = abi.encode(
        //     vm.envAddress("EIGEN_POD_MANAGER"), //TODO: move from .env to helper config
        //     vm.envAddress("DELEGATION_MANAGER"), //TODO: move from .env to helper config
        //     vm.envAddress("SSV_NETWORK"), //TODO: move from .env to helper config
        //     1000
        // );

        // if (apEth == address(0)) {
        //     apEth = getProxyAddress();
        // }
        // vm.broadcast();
        // run(apEth, owner, IAPETHWithdrawalQueueTicket(withdrawalQueue), _options);
    }
}
