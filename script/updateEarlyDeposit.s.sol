// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, ERC1967Proxy, APETH, APEthEarlyDeposits} from "./scriptBase.s.sol";

contract UpdateEarlyDeposit is ScriptBase {

    function run(APEthEarlyDeposits earlyDeposit_, ERC1967Proxy proxy_, address owner_) public{
        _earlyDeposit = earlyDeposit_;
        _proxy = proxy_;
        _owner = owner_;
        _isTest = true;
        run();
    }

    function run() public {
        if (address(_proxy) == address(0)) _proxy = ERC1967Proxy(payable(address(getProxyAddress())));
        if (_owner == address(0)) _owner = vm.envAddress("CONTRACT_OWNER");
        _APEth = APETH(payable(address(_proxy)));
        vm.startBroadcast(_owner);
        _APEth.grantRole(EARLY_ACCESS, address(_earlyDeposit));
        _earlyDeposit.updateAPEth(address(_APEth));
        vm.stopBroadcast();
    }
}