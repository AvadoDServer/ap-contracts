// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APETH, APETHV2, Upgrades} from "./scriptBase.s.sol";

contract UpgradeProxy is ScriptBase {
    address _proxyAddress;

    function run(address apEth, address owner) public {
        Upgrades.upgradeProxy(apEth, "APETHV2.sol:APETHV2", abi.encodeCall(APETHV2.initialize, (owner)), owner);
    }

    function run() public {
        address owner = vm.envAddress("CONTRACT_OWNER");
        address apEth = vm.envAddress("APETH_PROXY");

        if (apEth == address(0)) {
            apEth = getProxyAddress();
        }

        vm.broadcast();
        run(apEth, owner);
    }
}
