// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.24;

/**
 *
 * @title The primary persistent storage for APEth Staking Pools
 * @author modified 04-Dec-2022 & 30-Mar-2024 by 0xWildhare originally by David Rugendyke (h/t David and Rocket Pool!)
 * @dev this code is modified from the Rocket Pool RocketStorage contract all "Rocket" replaced with "APEth" - everything not used by APEth has beed removed.
 *
 */

/**
 *
 * IMPORTS
 *
 */
import {IAPEthStorage} from "./interfaces/IAPEthStorage.sol";

/**
 *
 * ERRORS
 *
 */
/// @notice thrown when non-guardian is attempting to call an onlyGuardian function
error APEthStorage__ACCOUNT_IS_NOT_GUARDIAN();
/// @notice thrown when an account which is neither the guardian nor the APEth contract tries to call an onlyGuardianOrAPEth function
error APEthStorage__ACCOUNT_IS_NOT_GUARDIAN_OR_APETH();
/// @notice thrown when confirmGuardian is called by an account other that the new guardian
error APEthStorage__MUST_COME_FROM_NEW_GUARDIAN();
/// @notice thrown when the setAPEth is called after APEth has already been set
error APEthStorage__CAN_ONLY_BE_SET_ONCE();
/// @notice to help prevent accidental burning of keys must call setGuardian(0xdead) before calling burnKeys()
error APEthStorage__MUST_SET_TO_0Xdead_FIRST();

contract APEthStorage is IAPEthStorage {
    /**
     *
     * EVENTS
     *
     */
    event GuardianChanged(address oldGuardian, address newGuardian);

    /**
     *
     * STORAGE
     *
     */
    // MAPPINGS
    mapping(bytes32 => uint256) private uintStorage;
    mapping(bytes32 => address) private addressStorage;
    mapping(bytes32 => bool) private booleanStorage;

    // ADDRESSES
    address private guardian;
    address private newGuardian;
    address private apEth;

    /**
     *
     * MODIFIERS
     *
     */
    /**
     * @dev Throws if called by any account other than a guardian account (temporary account allowed access to settings before DAO is fully enabled)
     */
    modifier onlyGuardian() {
        if (msg.sender != guardian) revert APEthStorage__ACCOUNT_IS_NOT_GUARDIAN();
        _;
    }

    /**
     * @dev Throws if called by any account other than apEth or guardian address
     */
    modifier onlyGuardianOrAPEth() {
        if (msg.sender != apEth && msg.sender != guardian) {
            revert APEthStorage__ACCOUNT_IS_NOT_GUARDIAN_OR_APETH();
        }
        _;
    }

    /**
     *
     * FUNCTIONS
     *
     */
    constructor() {
        // Set the guardian upon deployment
        guardian = tx.origin;
    }

    /**
     *
     * @return address of the guardian
     *
     */
    function getGuardian() external view override returns (address) {
        return guardian;
    }

    /**
     *
     * @notice transfers ownership of guardian (step 1 of 2)
     * @dev requires new guardian to accept ownership
     * @param _newAddress address for the new guardian
     *
     */
    function setGuardian(address _newAddress) external override onlyGuardian {
        // Store new address awaiting confirmation
        newGuardian = _newAddress;
    }

    /**
     *
     * @notice confirms ownership of guardian (step 2 of 2)
     * @dev must be called by new guardian
     * @dev setGuardian must be called first
     *
     */
    function confirmGuardian() external override {
        // Check tx came from new guardian address
        if (msg.sender != newGuardian) revert APEthStorage__MUST_COME_FROM_NEW_GUARDIAN();
        // Store old guardian for event
        address oldGuardian = guardian;
        // Update guardian and clear storage
        guardian = newGuardian;
        delete newGuardian;
        // Emit event
        emit GuardianChanged(oldGuardian, guardian);
    }

    /**
     *
     * @return address of APEth contract
     *
     */
    function getAPEth() external view override returns (address) {
        return apEth;
    }

    /**
     *
     * @notice sets the APEth contract Address
     * @dev can only be set once
     * @param _address address for the APEth
     *
     */
    function setAPEth(address _address) external override onlyGuardian {
        if (apEth != address(0)) revert APEthStorage__CAN_ONLY_BE_SET_ONCE();
        apEth = _address;
    }

    /**
     *
     * @notice transfers ownership of guardian to 0 address (step 2 of 2)
     * @dev requires new guardian to be set to address(0xdead) first
     * @dev this action is final, only APEth will be able to change data once keys are burned
     *
     */
    function burnKeys() external override onlyGuardian {
        // Check that new guardian has been set to zero address (are you sure?)
        if (address(0xdead) != newGuardian) revert APEthStorage__MUST_SET_TO_0Xdead_FIRST();
        // Store old guardian for event
        address oldGuardian = guardian;
        // delete guardian
        delete guardian;
        // Emit event
        emit GuardianChanged(oldGuardian, guardian);
    }

    /// @param _key The key for the record
    function getAddress(bytes32 _key) external view override returns (address r) {
        return addressStorage[_key];
    }

    /// @param _key The key for the record
    function getUint(bytes32 _key) external view override returns (uint256 r) {
        return uintStorage[_key];
    }

    /// @param _key The key for the record
    function getBool(bytes32 _key) external view override returns (bool r) {
        return booleanStorage[_key];
    }

    /// @param _key The key for the record
    /// @param _value The value to be set
    function setAddress(bytes32 _key, address _value) external override onlyGuardianOrAPEth {
        addressStorage[_key] = _value;
    }

    /// @param _key The key for the record
    /// @param _value The value to be set
    function setUint(bytes32 _key, uint256 _value) external override onlyGuardianOrAPEth {
        uintStorage[_key] = _value;
    }

    /// @param _key The key for the record
    /// @param _value The value to be set
    function setBool(bytes32 _key, bool _value) external override onlyGuardianOrAPEth {
        booleanStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function deleteAddress(bytes32 _key) external override onlyGuardianOrAPEth {
        delete addressStorage[_key];
    }

    /// @param _key The key for the record - added for APEth ~ 0xWildhare
    function deleteUint(bytes32 _key) external override onlyGuardianOrAPEth {
        delete uintStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBool(bytes32 _key) external override onlyGuardianOrAPEth {
        delete booleanStorage[_key];
    }

    /// @param _key The key for the record
    /// @param _amount An amount to add to the record's value  - 0xWildhare removed safeMath
    function addUint(bytes32 _key, uint256 _amount) external override onlyGuardianOrAPEth {
        uintStorage[_key] += _amount;
    }

    /// @param _key The key for the record
    /// @param _amount An amount to subtract from the record's value - 0xWildhare removed safeMath
    function subUint(bytes32 _key, uint256 _amount) external override onlyGuardianOrAPEth {
        uintStorage[_key] -= _amount;
    }
}
