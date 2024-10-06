// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ScriptBase, APETH, console, Create2, ERC1967Proxy, Upgrades, APEthEarlyDeposits} from "./scriptBase.s.sol";

/*
contract transferOwnership is ScriptBase {
    APETH private _APEth;
    APEthEarlyDeposits private _earlyDeposit;

    function run() public {
        _APEth = APETH(payable(getProxyAddress()));
        _earlyDeposit = APEthEarlyDeposits(payable(getEarlyDepositAddress()));

        address newOwner = vm.envAddress("CONTRACT_OWNER");
        address sender = vm.envAddress("SENDER_PUBLIC_KEY");
        address earlyDepositOwner = _earlyDeposit.owner();
        bool isAdmin = _APEth.hasRole(0x00, newOwner);

        if (!isAdmin) {
            console.log("***Transfering ownership***");
            vm.startBroadcast();
            _APEth.grantRole(0x00, newOwner);
            _APEth.renounceRole(0x00, sender);
            vm.stopBroadcast();
            console.log("APETH Address:");
            console.logAddress(address(_APEth));
            console.log("APEth newOwner:");
        } else {
            console.log("APEth owner is set already");
        }
        console.logAddress(newOwner);
        if (earlyDepositOwner != newOwner) {
            console.log("***Transfering EarlyDepositOwner***");
            vm.startBroadcast();
            _earlyDeposit.transferOwnership(newOwner);
            vm.stopBroadcast();
            console.log("early deposit address:");
            console.logAddress(address(_earlyDeposit));
            console.log("early deposit new owner:");
        } else {
            console.log("early deposit owner already set");
        }
        console.logAddress(newOwner);
    }
}
*/
