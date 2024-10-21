// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {APETHV2} from "../src/APETHV2.sol";
import {APETHWithdrawalQueueTicket} from "../src/APETHWithdrawalQueueTicket.sol";
import {IAPETH} from "../src/interfaces/IAPETH.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Create2} from "@openzeppelin-contracts/utils/Create2.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Utils} from "./utils/Utils.sol";

contract Deploy is Script, Utils {
    APETHV2 public apeth;
    APETHWithdrawalQueueTicket public withdrawalQueueTicket;
    ERC1967Proxy public proxy;

    bytes32 public constant ETH_STAKER = keccak256("ETH_STAKER");
    bytes32 public constant EARLY_ACCESS = keccak256("EARLY_ACCESS");
    bytes32 public constant UPGRADER = keccak256("UPGRADER");
    bytes32 public constant MISCELLANEOUS = keccak256("MISCELLANEOUS");
    bytes32 public constant SSV_NETWORK_ADMIN = keccak256("SSV_NETWORK_ADMIN");
    bytes32 public constant DELEGATION_MANAGER_ADMIN = keccak256("DELEGATION_MANAGER_ADMIN");
    bytes32 public constant EIGEN_POD_ADMIN = keccak256("EIGEN_POD_ADMIN");
    bytes32 public constant EIGEN_POD_MANAGER_ADMIN = keccak256("EIGEN_POD_MANAGER_ADMIN");
    bytes32 private constant APETH_CONTRACT = keccak256("APETH_CONTRACT");

    address public owner;
    address public staker;
    address public upgrader;

    Options public options;
    bool public debug = true;

    function run() external {
        string memory configData = readInput("aqua_patina_deployment_input");
        if (debug) console.log("configData", configData);
        //addresses:
        owner = stdJson.readAddress(configData, ".permissions.owner");
        if (debug) console.log("owner", owner);
        staker = stdJson.readAddress(configData, ".permissions.staker");
        if (debug) console.log("staker", staker);
        upgrader = stdJson.readAddress(configData, ".permissions.upgrader");
        if (debug) console.log("upgrader", upgrader);
        proxy = ERC1967Proxy(payable(stdJson.readAddress(configData, ".addresses.apEthProxy")));
        if (debug) console.log("proxy", address(proxy));
        //build constructor for APETHV2
        options.constructorData = abi.encode(
            stdJson.readAddress(configData, ".addresses.eigenPodManager"),
            stdJson.readAddress(configData, ".addresses.delegationManager"),
            stdJson.readAddress(configData, ".addresses.ssvNetwork"),
            stdJson.readUint(configData, ".permissions.feeAmount")
        );
        _deployWithdrawalQueue();
        _upgradeApeth();
    }

    function _deployWithdrawalQueue() internal {
        console.log("Deploying Withdrawal Queue");
        vm.startBroadcast();
        APETHWithdrawalQueueTicket apethWQTImplementation = new APETHWithdrawalQueueTicket();
        if (debug) console.log("apethWQTImplementation", address(apethWQTImplementation));
        if (debug) console.log("code length: ", address(apethWQTImplementation).code.length);
        ERC1967Proxy apethWQT1967Proxy = new ERC1967Proxy(
            address(apethWQTImplementation), abi.encodeCall(APETHWithdrawalQueueTicket.initialize, (owner))
        );
        vm.stopBroadcast();
        if (debug) console.log("apethWQT1967Proxy", address(apethWQT1967Proxy));
        withdrawalQueueTicket = APETHWithdrawalQueueTicket(address(apethWQT1967Proxy));
    }

    function _upgradeApeth() internal {
        Upgrades.upgradeProxy(
            address(proxy),
            "APETHV2.sol:APETHV2",
            abi.encodeCall(APETHV2.initialize, (withdrawalQueueTicket)),
            options,
            upgrader
        );
        apeth = APETHV2(payable(address(proxy)));
    }
}
