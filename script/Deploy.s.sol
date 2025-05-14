// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {APETHV2} from "../src/APETHV2.sol";
import {APETHV3} from "../src/APETHV3.sol";
import {APETHWithdrawalQueueTicket} from "../src/APETHWithdrawalQueueTicket.sol";
import {APEthDeposits} from "../src/APEthDeposits.sol";
import {IAPETH} from "../src/interfaces/IAPETH.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Create2} from "@openzeppelin-contracts/utils/Create2.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Utils} from "./utils/Utils.sol";

contract Deploy is Script, Utils {
    APETHV3 public APEth;
    APETHWithdrawalQueueTicket public withdrawalQueueTicket;
    APEthDeposits public apEthDeposits;
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
    address public eigenPodManager;
    address public delegationManager;
    address public ssvNetwork;
    uint256 public feeAmount;
    uint256 public minDeposit;

    Options public options;
    bool public debug = true;

    function run() public {
        string memory configData = readInput("aqua_patina_deployment_input");
        // if (debug) console.log("configData", configData);
        //addresses:
        owner = stdJson.readAddress(configData, ".permissions.owner");
        if (debug) console.log("owner", owner);
        staker = stdJson.readAddress(configData, ".permissions.staker");
        if (debug) console.log("staker", staker);
        upgrader = stdJson.readAddress(configData, ".permissions.upgrader");
        if (debug) console.log("upgrader", upgrader);
        proxy = ERC1967Proxy(payable(stdJson.readAddress(configData, ".addresses.apEthProxy")));
        if (debug) console.log("proxy", address(proxy));
        eigenPodManager = stdJson.readAddress(configData, ".addresses.eigenPodManager");
        delegationManager = stdJson.readAddress(configData, ".addresses.delegationManager");
        ssvNetwork = stdJson.readAddress(configData, ".addresses.ssvNetwork");
        feeAmount = stdJson.readUint(configData, ".permissions.feeAmount");
        minDeposit = stdJson.readUint(configData, ".permissions.minDeposit");
        //build constructor for APETHV3
        options.constructorData = abi.encode(eigenPodManager, delegationManager, ssvNetwork, feeAmount);
        // _deployWithdrawalQueue();
        // _deployDepositQueue();
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

    function _deployDepositQueue() internal {
        console.log("Deploying APETH Deposit Vault");
        vm.startBroadcast();
        APEthDeposits apEthDepositsImplementation = new APEthDeposits(IAPETH(address(proxy)));
        if (debug) console.log("apEthDepositsImplementation", address(apEthDepositsImplementation));
        if (debug) console.log("code length: ", address(apEthDepositsImplementation).code.length);
        ERC1967Proxy apEthDeposits1967Proxy = new ERC1967Proxy(
            address(apEthDepositsImplementation), abi.encodeCall(APEthDeposits.initialize, (owner, minDeposit))
        );
        vm.stopBroadcast();
        if (debug) console.log("apEthDeposits1967Proxy", address(apEthDeposits1967Proxy));
        apEthDeposits = APEthDeposits(payable(address(apEthDeposits1967Proxy)));
    }

    function _upgradeApeth() internal {
        vm.startBroadcast(upgrader);
        Upgrades.upgradeProxy(
            address(proxy),
            "APETHV3.sol:APETHV3",
            abi.encodeCall(APETHV3.initialize,()),
            options,
            upgrader
        );
        // since this must be called by the upgrader (same address as owner),
        // we will set the permission in the withdrwawl queue here.
        // withdrawalQueueTicket.grantRole(APETH_CONTRACT, address(proxy));
        vm.stopBroadcast();
        APEth = APETHV3(payable(address(proxy)));
        if (debug) console.log("APEth", address(APEth));
    }
}
