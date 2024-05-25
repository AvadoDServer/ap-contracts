// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APEthStorage, APETH, console, Create2, ERC1967Proxy, Upgrades, stdJson} from "./scriptBase.s.sol";

contract DeployProxy is ScriptBase {

    /*******************************************
    FILL THESE FROM TERMINAL LOGS
    ********************************************/
    bytes saltForVanityAddress = 0x09f8a99918b189f55c1dd77559b5d9c90b6df10b28e7b6c1b53674af9a43614f; // calculate with vanity address generator manually enter
    address storageContractAddress = 0x0000000000000000000000000000000000000000;
    address payable implementationContractAddress = 0x0000000000000000000000000000000000000000;
    /*******************************************
    ********************************************/
    

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
            salt.apEth = saltForVanityAddress;
            console.logBytes32(salt.apEth);
            _storageContract = APEthStorage(storageContractAddress);
            console.log("storage", address(_storageContract));
            _implementation = APETH(implementationContractAddress);
            console.log("implementation", address(_implementation));
        }
        calcProxyAddress(); 
        deployProxy();
        address podAddress = _storageContract.getAddress(keccak256(abi.encodePacked("external.contract.address", "EigenPod")));
        console.log("Eigen Pod Address: ", podAddress);
        _APEth = APETH(payable(_apEthPreDeploy));
    }
}
