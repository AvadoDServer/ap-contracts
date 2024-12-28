// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @title Aqua Patina Vault
 * @author Avado AG, Zug Switzerland
 * @notice Terms of Service: https://ava.do/terms-and-conditions/
 * @notice This vault holds the EigenPod withdrawals so that the validator count
 * can be adjusted in the same transaction that the beacon eth returns to the APETH contract
 */

/**
 *
 * IMPORTS
 *
 */
import {AccessControlUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IAPVault} from "./interfaces/IAPVault.sol";

/**
 *
 * ERRORS
 *
 */

/**
 *
 * CONTRACT
 *
 */
contract APVault is AccessControlUpgradeable, UUPSUpgradeable, IAPVault {
    /**
     *
     * STORAGE
     *
     */
    bytes32 private constant UPGRADER = keccak256("UPGRADER");
    bytes32 private constant APETH_CONTRACT = keccak256("APETH_CONTRACT");

    /**
     *
     * INITIALIZER
     *
     */
    function initialize(address _admin, address _apeth) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(UPGRADER, _admin);
        _grantRole(APETH_CONTRACT, _apeth);
    }

    /**
     *
     * PUBLIC FUNCTIONS
     *
     */
    function withdraw(uint256 _amount) public onlyRole(APETH_CONTRACT) {
        payable(msg.sender).transfer(_amount);
        emit Withdraw(tx.origin, _amount);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     *
     * INTERNAL FUNCTIONS
     *
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER) {}
}
