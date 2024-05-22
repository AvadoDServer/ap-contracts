// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APEthStorage, APETH, console, Create2, ERC1967Proxy, Upgrades} from "./scriptBase.s.sol";

contract DeployProxy is ScriptBase {
    function run(address owner_, address storage_, address implementation_) public returns (APETH) {
        _owner = owner_;
        _isTest = true;
        _storageContract = APEthStorage(storage_);
        _implementation = APETH(payable(implementation_));
        run();
        return (_APEth);
    }

    function run() public {
        console.log("***Deploying Proxy***");

        if(!_isTest){
            salt.apEth = 0x5310c668dd699d3b7975c1b9680acc961b8e8e849815a26af78f1d2e97960654; // calculate with vanity address generator manually enter
            console.logBytes32(salt.apEth);
            _storageContract = APEthStorage(0x868d0997A8b97294Cd6aBcF3A8e4E40D8864216D); //manually enter after deploying
            console.log("storage", address(_storageContract));
            _implementation = APETH(payable(0x3A824bf129D44961ab67b3dE3e86A173E0f54d76)); //manually enter after deploying
            console.log("implementation", address(_implementation));
        }
        calcProxyAddress(); 
        deployProxy();
        address podAddress = _storageContract.getAddress(keccak256(abi.encodePacked("external.contract.address", "EigenPod")));
        console.log("Eigen Pod Address: ", podAddress);
        _APEth = APETH(payable(_apEthPreDeploy));
    }
}
