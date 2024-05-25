// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {APETH} from "../src/APETH.sol";
import {APETHV2} from "../src/APETHV2.sol";
import {APEthStorage} from "../src/APEthStorage.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Create2} from "@openzeppelin-contracts/utils/Create2.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {stdJson} from "forge-std/StdJson.sol";

error SCRIPT_BASE__MUST_DEPLOY_IMPLEMENTATION_FIRST();

contract ScriptBase is Script {

    /*******************************************
    FILL THESE FROM TERMINAL LOGS
    ********************************************/
    bytes32 saltForVanityAddress = 0xf2cba114011070072d32111b445bc7653a190ffbadccdb6301c45f6750a720ab; // calculate with vanity address generator manually enter
    address storageContractAddress = 0x9546bDda1d003eFe8AC035F28fa57d887A785178;
    address payable implementationContractAddress = payable(0xa929Db0Cf6960ba709252D80355aD7BB848A3E9c);
    address _owner = 0x51336769321dE54925E2da6881D7BDCb02258D5e; //set to the address that will own the token.
    /*******************************************
    ********************************************/


    struct Salt {
        //bytes32 storageContract;
        //bytes32 implementation;
        bytes32 apEth;
    }

    Salt public salt = Salt({
        apEth: 0x0000000000000000000000000000000000000000000000000000000000000969
    });

    APETH _APEth;
    APETH _implementation;
    APEthStorage _storageContract;
    ERC1967Proxy _proxy;

    address _ssvNetwork;
    address _eigenPodManager;

    //these are the create2 pre-deploy address calcs
    address _apEthPreDeploy;

    address _factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    bool _isTest;

    function calcProxyAddress() public {
        if (address(_implementation) == address(0)) revert SCRIPT_BASE__MUST_DEPLOY_IMPLEMENTATION_FIRST();
        _apEthPreDeploy = Create2.computeAddress(
            salt.apEth,
            keccak256(
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(
                        address(_implementation),
                        abi.encodeCall(_implementation.initialize, (_owner, address(_storageContract)))
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
        _storageContract = new APEthStorage();
        vm.stopBroadcast();
        console.log("storageContract deployed", address(_storageContract));
        console.log("guardian address", _storageContract.getGuardian());
    }

    function deployImplementation() public {
        vm.startBroadcast();
        _implementation = new APETH();
        vm.stopBroadcast();
        console.log("impementation deloyed", address(_implementation));
    }

    function deployProxy() public {
        vm.startBroadcast();
        if (_owner == address(0)) _owner = msg.sender;
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

    function computeProxyInitCodeHash() public view {
        bytes32 hash = 
            keccak256(
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(
                        address(_implementation),
                        abi.encodeCall(_implementation.initialize, (_owner, address(_storageContract)))
                    )
                )
            );
        console.log("init code hash");
        console.logBytes32(hash);
    }
}
