// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {APETH} from "../src/APETH.sol";
import {APETHV2} from "../src/APETHV2.sol";
import {APEthStorage} from "../src/APEthStorage.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Create2} from "@openzeppelin-contracts/utils/Create2.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

error SCRIPT_BASE__MUST_DEPLOY_IMPLEMENTATION_FIRST();

contract ScriptBase is Script {
    struct Salt {
        bytes32 storageContract;
        //bytes32 implementation;
        bytes32 apEth;
    }

    Salt public salt = Salt({
        storageContract: 0x0000000000000000000000000000000000000000000000000000000000001069,
        //implementation: 0x0000000000000000000000000000000000000000000000000000000000001069,
        apEth: 0x0000000000000000000000000000000000000000000000000000000000000969
    });

    APETH _APEth;
    APETH _implementation;
    APEthStorage _storageContract;
    ERC1967Proxy _proxy;

    // // Define Deposit Contract TODO: should check which chain we are deployig to to use correct address?
    // address depositContract = 0x4242424242424242424242424242424242424242; //holesky
    // depositContract = 0x00000000219ab540356cBB839Cbe05303d7705Fa; //mainnet
    address _ssvNetwork = 0x38A4794cCEd47d3baf7370CcC43B560D3a1beEFA; //holesky
    // address public _ssvNetwork = 0xDD9BC35aE942eF0cFa76930954a156B3fF30a4E1; //mainnet
    address _eigenPodManager = 0x30770d7E3e71112d7A6b7259542D1f680a70e315; //holesky
    // address _eigenPodManager = 0x91E677b07F7AF907ec9a428aafA9fc14a0d3A338; //mainnet

    //these are the create2 pre-deploy address calcs
    address _apEthPreDeploy;
    address _implementationAddressPreDeploy;
    address _storageContractPreDeploy;

    address _owner;
    address _factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    bool _isTest;

    function calcStorageAddress() public {
        _storageContractPreDeploy = Create2.computeAddress(
            salt.storageContract,
            keccak256(abi.encodePacked(type(APEthStorage).creationCode)),
            _factory 
        );
        console.log("storage contract pre deploy", _storageContractPreDeploy);
        _storageContract = APEthStorage(_storageContractPreDeploy);
    }

    function calcProxyAddress() public {
        if(address(_implementation) == address(0)) revert SCRIPT_BASE__MUST_DEPLOY_IMPLEMENTATION_FIRST();
        _apEthPreDeploy = Create2.computeAddress(
            salt.apEth,
            keccak256(
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(
                        address(_implementation),
                        abi.encodeCall(_implementation.initialize, (_owner, address(_storageContractPreDeploy)))
                    )
                )
            ),
            _factory
        );
        console.log("proxy address pre deploy", _apEthPreDeploy);
        _APEth = APETH(payable(_apEthPreDeploy));
    }

    function calcProxyAddress(address implementation) public {
        _implementation = APETH(payable(implementation));
        _apEthPreDeploy = Create2.computeAddress(
            salt.apEth,
            keccak256(
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(
                        address(_implementation),
                        abi.encodeCall(_implementation.initialize, (_owner, address(_storageContractPreDeploy)))
                    )
                )
            ),
            _factory
        );
        console.log("proxy address pre deploy", _apEthPreDeploy);
        _APEth = APETH(payable(_apEthPreDeploy));
    }

    function deployStorage() public {
        vm.startBroadcast();
        _storageContract = new APEthStorage{salt: salt.storageContract}();
        vm.stopBroadcast();
        console.log("storageContract deployed", address(_storageContract));
        console.log("guardian address", _storageContract.getGuardian());
        console.log("should match msg.sender", msg.sender);
        console.log("tx.origin", tx.origin);
        require(_storageContractPreDeploy == address(_storageContract), "storage contract address mismatch");
    }

    function deployImplementation() public {
        vm.startBroadcast();
        _implementation = new APETH();
        
        vm.stopBroadcast();
        console.log("impementation deloyed", address(_implementation));
    }

    function deployProxy() public {
        vm.startBroadcast();
        //Set as apEth in storage
        _storageContract.setAPEth(address(_apEthPreDeploy));
        _proxy = new ERC1967Proxy{salt: salt.apEth}(
            address(_implementation), abi.encodeCall(_implementation.initialize, (_owner, address(_storageContract)))
        );
        vm.stopBroadcast();
        console.log("APEth (proxy) deployed", (address(_proxy)));
        require(_apEthPreDeploy == address(_proxy), "proxy address mismatch");
        // Attach the APETH interface to the deployed proxy
        _APEth = APETH(payable(address(_proxy)));
    }
}