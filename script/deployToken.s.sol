// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScriptBase, APEthStorage, APETH, console, Create2, ERC1967Proxy, Upgrades} from "./scriptBase.s.sol";

contract DeployTokenImplementation is ScriptBase {
    
    function run(address owner_) public returns (APEthStorage, APETH, APETH) {
        _owner = owner_;
        _isTest = true;
        salt.apEth = 0x0000000000000000000000000000000000000000000000000101010101010101; //different salt to avoid collisions with deploied contracts (its annoying)
        salt.implementation = 0x0000000000000000000000000000000000000000000000000101010101010101;
        salt.storageContract = 0x0000000000000000000000000000000000000000000000000101010101010101;
        run();
        return (_storageContract, _implementation, _APEth);
    }

    function run() public returns (APEthStorage, APETH, APETH) {
        console.log("***Deploying Implementation***");
        if (_owner == address(0)) _owner = msg.sender;

        //calculate addresses TODO: WRITE CREATE2 SCRIPT TO CALC SALT TO ADD A BUNCH OF A's AT THE BEGINNING OF THE CONTRACTS
        //storage
        console.log("address(this)", address(this));
        _storageContractPreDeploy = Create2.computeAddress(
            salt.storageContract,
            keccak256(abi.encodePacked(type(APEthStorage).creationCode)),
            _factory 
        );
        console.log("storage contract pre deploy", _storageContractPreDeploy);

        //implementation
        _implementationAddressPreDeploy =
            Create2.computeAddress(salt.implementation, keccak256(abi.encodePacked(type(APETH).creationCode)), _factory);
        console.log("implementation address pre deploy", _implementationAddressPreDeploy);
        //wrap as contract to generate the initialization code
        APETH preImplementation = APETH(payable(_implementationAddressPreDeploy));

        //apEth(technically the proxy)
        _apEthPreDeploy = Create2.computeAddress(
            salt.apEth,
            keccak256(
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(
                        _implementationAddressPreDeploy,
                        abi.encodeCall(preImplementation.initialize, (_owner, address(_storageContractPreDeploy)))
                    )
                )
            ),
            _factory
        );
        console.log("proxy address pre deploy", _apEthPreDeploy);

            _storageContract = APEthStorage(_storageContractPreDeploy);
            console.log("storageContract exists", _storageContractPreDeploy);
       
        // Deploy the token implementation
        if (_implementationAddressPreDeploy.code.length == 0 && _apEthPreDeploy.code.length == 0) {
            //Deploy the token implementation
            deployImplementation();
            //deploy proxy
            //deployProxy();
        } else if (_implementationAddressPreDeploy.code.length != 0 && _apEthPreDeploy.code.length == 0) {
            _implementation = APETH(payable(_implementationAddressPreDeploy));
            console.log("implementation exists", _implementationAddressPreDeploy);
            deployProxy();
        } else if (_implementationAddressPreDeploy.code.length == 0 && _apEthPreDeploy.code.length != 0) {
            // Upgrades.upgradeProxy(address(_APEth), "APETH.sol:APETH", "", _owner);
            console.log("Use Upgrade Script", address(_APEth));
        } else {
            _APEth = APETH(payable(_apEthPreDeploy));
            _implementation = APETH(payable(_implementationAddressPreDeploy)); //??
            console.log("Proxy exists", address(_APEth));
            console.log("implementation exists", _implementationAddressPreDeploy);
        }

        console.log(
            "eigen Pod Address",
            _storageContract.getAddress(keccak256(abi.encodePacked("external.contract.address", "EigenPod")))
        );

        return (_storageContract, _implementation, _APEth);
    }


}
