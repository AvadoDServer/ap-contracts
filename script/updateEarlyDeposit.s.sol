// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APETH, APEthEarlyDeposits, EARLY_ACCESS} from "./scriptBase.s.sol";

library UpdateEarlyDepositLibrary {
    function run(APETH apEth, APEthEarlyDeposits earlyDeposit) internal {
        apEth.grantRole(EARLY_ACCESS, address(earlyDeposit));
        earlyDeposit.updateAPEth(address(apEth));
    }
}

contract UpdateEarlyDeposit is ScriptBase {
    function run(address apEth, address earlyDeposit) public {
        UpdateEarlyDepositLibrary.run(getAPETH(apEth), getAPEthEarlyDeposits(earlyDeposit));
    }

    function run() public {
        address apEth = vm.envAddress("APETH_PROXY");
        address earlyDeposits = vm.envAddress("APETH_EARLY_DEPOSITS");

        if (apEth == address(0)) {
            apEth = getProxyAddress();
        }

        if (earlyDeposits == address(0)) {
            earlyDeposits = getEarlyDepositAddress();
        }

        vm.broadcast();
        run(apEth, earlyDeposits);
    }
}
