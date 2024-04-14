// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APEthStorage, APETH, console, Create2, ERC1967Proxy, Upgrades} from "./scriptBase.s.sol";

contract DeployProxy is ScriptBase {
    function run(address owner_, address storage_, address implementation_) public returns (APETH) {
        _owner = owner_;
        _isTest = true;
        salt.apEth = 0x0000000000000000000000000000000000000000000000000101010101010101; //different salt to avoid collisions with deploied contracts (its annoying)
        //salt.implementation = 0x0000000000000000000000000000000000000000000000000101010101010101;
        //salt.storageContract = 0x0000000000000000000000000000000000000000000000000101010101010101;
        _storageContract = APEthStorage(storage_);
        _implementation = APETH(payable(implementation_));
        run();
        return (_APEth);
    }

    function run() public {
        console.log("***Deploying Proxy***");
        if (_owner == address(0)) _owner = msg.sender;

        if(!_isTest){
            salt.apEth = 0x97d61c875f32d0c5b4cd0bf0810dee2b8adb825ee168ddf6653b1cc8fd2a482b; // calculate with vanity address generator manually enter
            console.logBytes32(salt.apEth);
            _storageContract = APEthStorage(0x23c7065F408737d75a74227a0F01F4613E22c65e); //manually enter after deploying
            console.log("storage", address(_storageContract));
            _implementation = APETH(payable(0xDaa1faEaBBA7a48Bf5BDFfF5439A9BcDA08E26F2)); //manually enter after deploying
            console.log("implementation", address(_implementation));
        }
        calcProxyAddress(); 
        deployProxy();
        address podAddress = _storageContract.getAddress(keccak256(abi.encodePacked("external.contract.address", "EigenPod")));
        console.log("Eigen Pod Address: ", podAddress);
        _APEth = APETH(payable(_apEthPreDeploy));
    }
}
