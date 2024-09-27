// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 *
 * IMPORTS
 *
 */
import {ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {AccessControlUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {ERC20PermitUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IEigenPodManager} from "@eigenlayer-contracts/interfaces/IEigenPodManager.sol";
import {IEigenPod} from "@eigenlayer-contracts/interfaces/IEigenPod.sol";
import {IDelegationManager} from "@eigenlayer-contracts/interfaces/IDelegationManager.sol";
import {IAPETH, IERC20} from "./interfaces/IAPETH.sol";
import {IAPETHWithdrawalQueueTicket} from "./interfaces/IAPETHWithdrawalQueueTicket.sol";

/// @custom:oz-upgrades-from APETH
contract APETHV2 is
    Initializable,
    ERC20Upgradeable,
    AccessControlUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable
{
    /**
     *
     * STORAGE
     *
     */
    /// @dev storage outside of upgradeable storage
    bytes32 private constant ETH_STAKER = keccak256("ETH_STAKER");
    bytes32 private constant EARLY_ACCESS = keccak256("EARLY_ACCESS");
    bytes32 private constant UPGRADER = keccak256("UPGRADER");
    bytes32 private constant MISCELLANEOUS = keccak256("MISCELLANEOUS");
    bytes32 private constant SSV_NETWORK_ADMIN = keccak256("SSV_NETWORK_ADMIN");
    bytes32 private constant DELEGATION_MANAGER_ADMIN = keccak256("DELEGATION_MANAGER_ADMIN");
    bytes32 private constant EIGEN_POD_ADMIN = keccak256("EIGEN_POD_ADMIN");
    bytes32 private constant EIGEN_POD_MANAGER_ADMIN = keccak256("EIGEN_POD_MANAGER_ADMIN");

    /// @dev uses storage slots (caution when upgrading)
    uint256 public activeValidators;
    address public feeRecipient;
    uint256 public withdrawalQueue;
    IAPETHWithdrawalQueueTicket public withdrawalQueueTicket;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public reinitializer(2) {
        __ERC20_init("AP-Restaked-Eth-V2", "APETHV2");
        __AccessControl_init();
        __ERC20Permit_init("AP-Restaked-Eth");
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
    }

    function mint(address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, amount);
    }

    function version() public pure returns (uint256) {
        return 2;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
