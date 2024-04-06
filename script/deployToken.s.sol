// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {APETH} from "../src/APETH.sol";
import {APEthStorage} from "../src/APEthStorage.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Create2} from "@openzeppelin-contracts/utils/Create2.sol";

contract DeployTokenImplementation is Script {

    struct Salt {
        bytes32 storageContract;
        bytes32 implementation;
        bytes32 apEth;
    }

    Salt public salt = Salt({
        storageContract: 0x0000000000000000000000000000000000000000000000000000000000000000,
        implementation: 0x0000000000000000000000000000000000000000000000000000000000000000,
        apEth: 0x0000000000000000000000000000000000000000000000000000000000000000
    });

    APETH APEth;
    APETH implementation;
    APEthStorage storageContract;
    ERC1967Proxy proxy;

    // // Define Deposit Contract TODO: should check which chain we are deployig to to use correct address?
    // address depositContract = 0x4242424242424242424242424242424242424242; //holesky
    // depositContract = 0x00000000219ab540356cBB839Cbe05303d7705Fa; //mainnet
    address ssvNetwork = 0x38A4794cCEd47d3baf7370CcC43B560D3a1beEFA; //holesky
    // address public SSVNetwork = 0xDD9BC35aE942eF0cFa76930954a156B3fF30a4E1; //mainnet
    address eigenPodManager = 0x30770d7E3e71112d7A6b7259542D1f680a70e315; //holesky
    // address eigenPodManager = 0x91E677b07F7AF907ec9a428aafA9fc14a0d3A338; //mainnet

    //these are the create2 pre-deploy address calcs
    address apEthPreDeploy;
    address implementationAddressPreDeploy;
    address storageContractPreDeploy;
    

    function run(address owner, address deployer) public returns(APEthStorage,APETH,APETH) {
        //calculate addresses TODO: WRITE CREATE2 SCRIPT TO CALC SALT TO ADD A BUNCH OF A's AT THE BEGINNING OF THE CONTRACTS
        //storage
        console.log("address(this)", address(this));
        storageContractPreDeploy = Create2.computeAddress(
            salt.storageContract, keccak256(abi.encodePacked(type(APEthStorage).creationCode)), deployer
        );
        console.log("storage contract pre deploy", storageContractPreDeploy);
        
        //implementation
        implementationAddressPreDeploy = Create2.computeAddress(
            salt.implementation, keccak256(abi.encodePacked(type(APETH).creationCode)), deployer
        );
        console.log("implementation address pre deploy", implementationAddressPreDeploy);
        //wrap as contract to generate the initialization code
        APETH preImplementation = APETH(payable(implementationAddressPreDeploy));

        //apEth(technically the proxy)
        apEthPreDeploy = Create2.computeAddress(
            salt.apEth,
            keccak256(
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(
                        implementationAddressPreDeploy,
                        abi.encodeCall(preImplementation.initialize, (owner, address(storageContractPreDeploy)))
                    )
                )
            ),
            deployer
        );
        console.log("proxy address pre deploy", apEthPreDeploy);

        //Deploy storage contract
        if (storageContractPreDeploy.code.length == 0) {
            vm.startBroadcast();
            storageContract = new APEthStorage{salt: salt.storageContract}();
            vm.stopBroadcast();
            console.log("storageContract deployed", address(storageContract));
        } else {
            storageContract = APEthStorage(storageContractPreDeploy);
            console.log("storageContract exists", storageContractPreDeploy);
        }
        console.log("guardian address", storageContract.getGuardian());
        console.log("should match msg.sender", msg.sender);
        require(storageContractPreDeploy == address(storageContract), "storage contract address mismatch");
        // console.log("tx.origin", tx.origin);
        // console.log("address(this)", address(this));
        //load addresses into storage
        // storageContract.setAddress(
        //     keccak256(abi.encodePacked("external.contract.address", "DepositContract")), depositContract
        // );
        vm.startBroadcast(deployer);
        storageContract.setAddress(keccak256(abi.encodePacked("external.contract.address", "SSVNetwork")), ssvNetwork);
        storageContract.setAddress(
            keccak256(abi.encodePacked("external.contract.address", "EigenPodManager")), eigenPodManager
        );
        // Set as apEth in storage
        storageContract.setAPEth(apEthPreDeploy);
        vm.stopBroadcast();
        console.log("storage initialised");

        // Deploy the token implementation
        if (implementationAddressPreDeploy.code.length == 0) {
            vm.startBroadcast();
            implementation = new APETH{salt: salt.implementation}();
            vm.stopBroadcast();
            console.log("impementation deloyed", address(implementation));
        } else {
            implementation = APETH(payable(implementationAddressPreDeploy));
            console.log("implementation exists", implementationAddressPreDeploy);
        }
        require(implementationAddressPreDeploy == address(implementation), "implementation address mismatch");

        // Deploy the proxy and initialize the proxy
        if (apEthPreDeploy.code.length == 0) {
            vm.startBroadcast();
            proxy = new ERC1967Proxy{salt: salt.apEth}(
                address(implementation), abi.encodeCall(implementation.initialize, (owner, address(storageContract)))
            );
            vm.stopBroadcast();
            // Attach the APETH interface to the deployed proxy
            APEth = APETH(payable(address(proxy)));
            console.log("APEth deployed", (address(proxy)));
        } else {
            //TODO: THIS SHOULD HANDLE THE CASE FOR AN IMPLEMENTATION CHANGE (FOR DEPLOY SCRIPT, NOT FOR TEST)
            APEth = APETH(payable(apEthPreDeploy));
            console.log("APEth exists", apEthPreDeploy);
        }
        require(apEthPreDeploy == address(proxy), "proxy address mismatch");

        console.log(
            "eigen Pod Address",
            storageContract.getAddress(keccak256(abi.encodePacked("external.contract.address", "EigenPod")))
        );

        return(storageContract, implementation, APEth);

    }
}
