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
 * INTERFACE
 *
 */
interface IAPVault {
    /**
     *
     * EVENTS
     *
     */
    event Withdraw(address indexed to, uint256 amount);

    /**
     *
     * FUNCTIONS
     *
     */
    function withdraw(uint256 amount) external;
}
