// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APEthStorage, APETH, console, Create2, ERC1967Proxy, Upgrades, APEthEarlyDeposits} from "./scriptBase.s.sol";

contract transferOwnership is ScriptBase {
    function run() public {
        _APEth = APETH(payable(getProxyAddress()));
        (address storCont,) = getDeployedAddress();
        _earlyDeposit = APEthEarlyDeposits(payable(getEarlyDepositAddress()));
        _storageContract = APEthStorage(storCont);
        address newOwner = vm.envAddress("CONTRACT_OWNER");
        address sender = vm.envAddress("SENDER_PUBLIC_KEY");
        address currentGuardian = _storageContract.getGuardian();
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
        if (newOwner != currentGuardian) {
            console.log("***Transfering guardianship***");
            vm.startBroadcast();
            _storageContract.setGuardian(newOwner);
            vm.stopBroadcast();
        console.log("Storage Contract Address:");
        console.logAddress(address(_storageContract));
        console.log("newGuardian:");
        console.log('\x1b[31m%s\x1b[0m', "(must be confirmed by newGuardian address)");
        } else {
            console.log("guardian is already");
        }
        console.logAddress(newOwner);
        if(earlyDepositOwner != newOwner){
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
