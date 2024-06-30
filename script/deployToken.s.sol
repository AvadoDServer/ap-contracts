// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    ScriptBase,
    APEthStorage,
    APEthEarlyDeposits,
    APETH,
    console,
    Create2,
    ERC1967Proxy,
    Upgrades,
    stdJson
} from "./scriptBase.s.sol";

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

        if (!_isTest) {
            salt.apEth = vm.envBytes32("SALT");
            console.logBytes32(salt.apEth);
            (storageContractAddress, implementationContractAddress) = getDeployedAddress();
            //storage
            _storageContract = APEthStorage(storageContractAddress);
            console.log("storage", address(_storageContract));
            //implementation
            _implementation = APETH(payable(implementationContractAddress));
            console.log("implementation", address(_implementation));
        }
        calcProxyAddress();
        deployProxy();
        address podAddress =
            _storageContract.getAddress(keccak256(abi.encodePacked("external.contract.address", "EigenPod")));
        console.log("Eigen Pod Address: ", podAddress);
        _APEth = APETH(payable(_apEthPreDeploy));
        // deployEarlyDeposit(); deploy separately because of verification failure.
    }
}
