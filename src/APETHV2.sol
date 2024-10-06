// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IDepositContract.sol";

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
    bytes32 private constant UPGRADER = keccak256("UPGRADER");
    bytes32 private constant STAKER = keccak256("MY_ROLE");
    bytes32 private constant EARLY_ACCESS = keccak256("EARLY_ACCESS");

    // Storage slots
    uint256 private activeValidators;
    address private feeRecipient;

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
