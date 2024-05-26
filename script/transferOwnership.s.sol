// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APEthStorage, APETH, console, Create2, ERC1967Proxy, Upgrades} from "./scriptBase.s.sol";

contract transferOwnership is ScriptBase {
    function run() public {
        _APEth = APETH(payable(getProxyAddress()));
        (address storCont,) = getDeployedAddress();
        _storageContract = APEthStorage(storCont);
        address newOwner = vm.envAddress("CONTRACT_OWNER");
        address currentOwner = _APEth.owner();
        address currentGuardian = _storageContract.getGuardian();
        if (newOwner != currentOwner) {
            console.log("***Transfering ownership***");
            vm.startBroadcast();
            _APEth.transferOwnership(newOwner);
            vm.stopBroadcast();
        console.log("APETH Address:");
        console.logAddress(address(_APEth));
        console.log("newOwner:");
        } else {
            console.log("owner is set already");
        }
        console.logAddress(newOwner);
        if (newOwner != currentGuardian) {
            console.log("***Transfering guardianship***");
            vm.startBroadcast();
            _storageContract.setGuardian(newOwner);
            vm.stopBroadcast();
        console.log("Storage Contract Address:");
        console.logAddress(address(_storageContract));
        console.log("newGuardian");
        console.log('\x1b[31m%s\x1b[0m', "(must be confirmed by newGuardian address)");
        } else {
            console.log("guardian is already");
        }
        console.logAddress(newOwner);
    }
}
