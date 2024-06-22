// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APEthStorage, APETH, console, Create2, ERC1967Proxy, Upgrades, APETHV2} from "./scriptBase.s.sol";

error DEPLOY_PROXY__MUST_DEPLOY_IMPLEMENTATION_FIRST();
error DEPLOY_PROXY__MUST_CALC_ADDRESS_FIRST(string);

contract UpgradeProxy is ScriptBase {
    address _proxyAddress;
    APETHV2 newContract;

    function run(address owner_, address proxyAddress_) public {
        _owner = owner_;
        _proxyAddress = proxyAddress_;
        _isTest = true;
        run();
    }

    function run() public {
        if (_proxyAddress == address(0)) _proxyAddress = getProxyAddress();
        // _proxyAddress = 0x409fD1B18D8eA7bf3f1A04ef137Fb201d2D398A7;
        if (_owner == address(0)) _owner = vm.envAddress("CONTRACT_OWNER");
        console.log("***Upgrading Proxy***");
        if (!_isTest) vm.startBroadcast();
        Upgrades.upgradeProxy(_proxyAddress, "APETHV2.sol:APETHV2", abi.encodeCall(newContract.initialize, (_owner)), _owner);
        if (!_isTest) vm.stopBroadcast();
        console.log("upgraded");
    }
}
