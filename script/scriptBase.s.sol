// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {APETH} from "../src/APETH.sol";
import {APETHV2} from "../src/APETHV2.sol";
import {APEthEarlyDeposits} from "../src/APEthEarlyDeposits.sol";
import {HelperConfig, NetworkConfig} from "./HelperConfig.s.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Create2} from "@openzeppelin-contracts/utils/Create2.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {IEigenPodManager} from "@eigenlayer-contracts/interfaces/IEigenPodManager.sol";

error SCRIPT_BASE__MUST_DEPLOY_IMPLEMENTATION_FIRST();

struct ProxyConfig {
    bool isTest;
    bytes32 salt;
    address admin;
    address feeRecipient;
    uint256 feeAmount;
    uint256 initialCap;
    NetworkConfig network;
    address DEPLOYER_PUBLIC_KEY;
}

bytes32 constant EARLY_ACCESS = keccak256("EARLY_ACCESS");

contract ScriptBase is Script {
    address private constant FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    bytes32 private constant DEFAULT_SALT = 0x0000000000000000000000000000000000000000000000000000000000000969;

    string chainId;

    bytes32 public constant _ETH_STAKER = keccak256("ETH_STAKER");
    bytes32 public constant _EARLY_ACCESS = keccak256("EARLY_ACCESS");
    bytes32 public constant _UPGRADER = keccak256("UPGRADER");
    bytes32 public constant _MISCELLANEOUS = keccak256("MISCELLANEOUS");
    bytes32 public constant _SSV_NETWORK_ADMIN = keccak256("SSV_NETWORK_ADMIN");
    bytes32 public constant _DELEGATION_MANAGER_ADMIN = keccak256("DELEGATION_MANAGER_ADMIN");
    bytes32 public constant _EIGEN_POD_ADMIN = keccak256("EIGEN_POD_ADMIN");
    bytes32 public constant _EIGEN_POD_MANAGER_ADMIN = keccak256("EIGEN_POD_MANAGER_ADMIN");
    bytes32 public constant _ADMIN = 0x00;

    APETH public _implementation;

    function getSalt(ProxyConfig memory config) private pure returns (bytes32) {
        if (config.salt == bytes32(0)) {
            return DEFAULT_SALT;
        }

        return config.salt;
    }

    function getConfig(ProxyConfig memory config) public returns (ProxyConfig memory) {
        if (config.admin == address(0)) {
            config.admin = vm.envAddress("CONTRACT_OWNER");
        }

        if (config.feeRecipient == address(0)) {
            config.feeRecipient = config.admin;
            config.feeAmount = 1000;
        }

        if (config.initialCap == 0) {
            config.initialCap = 100000 ether;
        }

        config.salt = getSalt(config);

        if (config.network.eigenPodManager == address(0)) {
            config.network = new HelperConfig().getConfig();
        }

        if (config.DEPLOYER_PUBLIC_KEY == address(0)) {
            config.DEPLOYER_PUBLIC_KEY = vm.envAddress("DEPLOYER_PUBLIC_KEY");
        }

        return config;
    }

    function computeProxyInitCodeHash() public view {
        address _owner = vm.envAddress("DEPLOYER_PUBLIC_KEY");
        bytes32 hash = keccak256(
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(address(_implementation), abi.encodeCall(_implementation.initialize, (_owner)))
            )
        );
        console.log("init code hash");
        console.logBytes32(hash);
    }

    function calcProxyAddress(address implementation, ProxyConfig memory config) public returns (address) {
        if (implementation == address(0)) {
            revert SCRIPT_BASE__MUST_DEPLOY_IMPLEMENTATION_FIRST();
        }

        return Create2.computeAddress(
            getSalt(config),
            keccak256(
                abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, encodeInitializer(config)))
            ),
            FACTORY
        );
    }

    function encodeInitializer(ProxyConfig memory partialConfig) public returns (bytes memory) {
        ProxyConfig memory config = getConfig(partialConfig);
        return abi.encodeCall(APETH.initialize, (config.DEPLOYER_PUBLIC_KEY));
    }

    function deployApEth(ProxyConfig memory partialConfig) public returns (APETH) {
        ProxyConfig memory config = getConfig(partialConfig);
        vm.startBroadcast();
        APETH apETH = new APETH(
            config.initialCap,
            IEigenPodManager(config.network.eigenPodManager),
            config.network.delegationManager,
            config.network.ssvNetwork,
            config.feeAmount
        );
        vm.stopBroadcast();
        return apETH;
    }

    function deployProxy(address implementation, ProxyConfig memory config) public returns (APETH) {
        vm.startBroadcast();
        ERC1967Proxy proxy = new ERC1967Proxy{salt: getSalt(config)}(implementation, encodeInitializer(config));
        vm.stopBroadcast();
        return APETH(payable(address(proxy)));
    }

    function deployEarlyDeposit(address owner, address earlydeposit_signer) public returns (APEthEarlyDeposits) {
        if (owner == address(0)) {
            owner = vm.envAddress("CONTRACT_OWNER");
        }
        if (earlydeposit_signer == address(0)) {
            earlydeposit_signer = vm.envAddress("EARLYDEPOSIT_SIGNER");
        }
        return new APEthEarlyDeposits(owner, earlydeposit_signer);
    }

    function getProxyAddress() public returns (address addr) {
        if (block.chainid == 1) {
            chainId = "1";
        } else if (block.chainid == 17000) {
            chainId = "17000";
        } else {
            chainId = "31337";
        }

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/broadcast/deployToken.s.sol/", chainId, "/run-latest.json");
        string memory json = vm.readFile(path);
        addr = stdJson.readAddress(json, ".transactions[1].contractAddress");
    }

    function getEarlyDepositAddress() public returns (address) {
        if (block.chainid == 1) {
            chainId = "1";
        } else if (block.chainid == 17000) {
            chainId = "17000";
        } else {
            chainId = "31337";
        }

        string memory root = vm.projectRoot();
        string memory path =
            string.concat(root, "/broadcast/deployEarlyDepositOnly.s.sol/", chainId, "/run-latest.json");
        string memory json = vm.readFile(path);
        return stdJson.readAddress(json, ".transactions[0].contractAddress");
    }

    function getAPETH(address addr) public pure returns (APETH) {
        return APETH(payable(addr));
    }

    function getDeployedAddress() public returns (address) {
        if (block.chainid == 1) {
            chainId = "1";
        } else if (block.chainid == 17000) {
            chainId = "17000";
        } else {
            chainId = "31337";
        }

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/broadcast/deployToken.s.sol/", chainId, "/run-latest.json");
        string memory json = vm.readFile(path);
        address implement = stdJson.readAddress(json, ".transactions[0].contractAddress");
        console.log("implementation: ", implement);
        return implement;
    }

    function getAPEthEarlyDeposits(address addr) public pure returns (APEthEarlyDeposits) {
        return APEthEarlyDeposits(payable(addr));
    }
}
