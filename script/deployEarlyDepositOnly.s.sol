// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, ERC1967Proxy, APETH, APEthEarlyDeposits} from "./scriptBase.s.sol";

contract DeployEarlyDeposits is ScriptBase {

    function run(address owner_) public returns(APEthEarlyDeposits){
        _owner = owner_;
        _isTest = true;
        run();
        return(_earlyDeposit);
    }
    function run() public {
        if (_owner == address(0)) _owner = vm.envAddress("CONTRACT_OWNER");
        deployEarlyDeposit();
    }
}