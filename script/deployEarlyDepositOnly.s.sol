// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ScriptBase, ERC1967Proxy, APETH, APEthEarlyDeposits} from "./scriptBase.s.sol";

contract DeployEarlyDeposits is ScriptBase {
    function run(address owner_, ERC1967Proxy proxy_) public returns (APEthEarlyDeposits) {
        _owner = owner_;
        _proxy = proxy_;
        _isTest = true;
        run();
        return (_earlyDeposit);
    }

    function run() public {
        if (address(_proxy) == address(0)) _proxy = ERC1967Proxy(payable(address(getProxyAddress())));
        if (_owner == address(0)) _owner = vm.envAddress("CONTRACT_OWNER");
        _APEth = APETH(payable(address(_proxy)));
        deployEarlyDeposit();
    }
}
