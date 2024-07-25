// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {APETH} from "../src/APETH.sol";
import {APETHV2} from "../src/APETHV2.sol";
import {APEthStorage} from "../src/APEthStorage.sol";
import {APEthEarlyDeposits} from "../src/APEthEarlyDeposits.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Create2} from "@openzeppelin-contracts/utils/Create2.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {stdJson} from "forge-std/StdJson.sol";

error SCRIPT_BASE__MUST_DEPLOY_IMPLEMENTATION_FIRST();

contract ScriptBase is Script {
    string chainId = "17000";

    struct Salt {
        //bytes32 storageContract;
        //bytes32 implementation;
        bytes32 apEth;
    }

    Salt public salt = Salt({apEth: 0x0000000000000000000000000000000000000000000000000000000000000969});

    APETH _APEth;
    APETH _implementation;
    APEthStorage _storageContract;
    ERC1967Proxy _proxy;
    APEthEarlyDeposits _earlyDeposit;

    address _ssvNetwork;
    address _eigenPodManager;
    address _delegationManager;
    address storageContractAddress;
    address implementationContractAddress;
    address _owner;

    //these are the create2 pre-deploy address calcs
    address _apEthPreDeploy;

    address _factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    bool _isTest;

    bytes32 public constant UPGRADER = keccak256("UPGRADER");
    bytes32 public constant ETH_STAKER = keccak256("ETH_STAKER");
    bytes32 public constant EARLY_ACCESS = keccak256("EARLY_ACCESS");
    bytes32 public constant ADMIN = keccak256("ADMIN");

    function calcProxyAddress() public {
        if (address(_implementation) == address(0)) revert SCRIPT_BASE__MUST_DEPLOY_IMPLEMENTATION_FIRST();
        if (_owner == address(0)) _owner = vm.envAddress("CONTRACT_OWNER");
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
        if (_owner == address(0)) _owner = vm.envAddress("CONTRACT_OWNER");
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

    function deployEarlyDeposit() public {
        if (_owner == address(0)) _owner = vm.envAddress("CONTRACT_OWNER");
        vm.startBroadcast(_owner);
        _earlyDeposit = new APEthEarlyDeposits(_owner);
        vm.stopBroadcast();
        console.log("early deposit contract:", address(_earlyDeposit));
    }

    function computeProxyInitCodeHash() public {
        if (_owner == address(0)) _owner = vm.envAddress("CONTRACT_OWNER");
        bytes32 hash = keccak256(
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

    function getDeployedAddress() public view returns (address storageCont, address implement) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/broadcast/deployStorage.s.sol/", chainId, "/run-latest.json");
        string memory json = vm.readFile(path);
        storageCont = stdJson.readAddress(json, ".transactions[0].contractAddress");
        implement = stdJson.readAddress(json, ".transactions[6].contractAddress");
    }

    function getProxyAddress() public view returns (address addr) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/broadcast/deployToken.s.sol/", chainId, "/run-latest.json");
        string memory json = vm.readFile(path);
        addr = stdJson.readAddress(json, ".transactions[1].contractAddress");
    }

    function getEarlyDepositAddress() public view returns(address) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/broadcast/deployEarlyDepositOnly.s.sol/", chainId, "/run-latest.json");
        string memory json = vm.readFile(path);
        return stdJson.readAddress(json, ".transactions[0].contractAddress");
    }
}
