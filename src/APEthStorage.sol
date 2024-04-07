pragma solidity 0.8.20;

// SPDX-License-Identifier: GPL-3.0-only

/// @title The primary persistent storage for APEth Staking Pools
/// @author modified 04-Dec-2022 & 30-Mar-2024 by 0xWildhare originally by David Rugendyke (h/t David and Rocket Pool!)
/// @dev this code is modified from the Rocket Pool RocketStorage contract all "Rocket" replaced with "APEth" - everything not used by APEth has beed removed.

import {IAPEthStorage} from "./interfaces/IAPEthStorage.sol";

error APEthStorage__ACCOUNT_IS_NOT_GUARDIAN();
error APEthStorage__ACCOUNT_IS_NOT_GUARDIAN_OR_APETH(address);
error APEthStorage__MUST_COME_FROM_NEW_GUARDIAN();
error APEthStorage__CAN_ONLY_BE_SET_ONCE();
error APEthStorage__MUST_SET_TO_0X0_FIRST();

contract APEthStorage is IAPEthStorage {
    // Events
    event GuardianChanged(address oldGuardian, address newGuardian);

    // Storage maps

    mapping(bytes32 => uint256) private uintStorage;
    mapping(bytes32 => address) private addressStorage;
    mapping(bytes32 => bool) private booleanStorage;

    // Guardian address
    address private guardian;
    address private newGuardian;
    address private apEth;

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
        if (msg.sender != apEth && msg.sender != guardian) revert APEthStorage__ACCOUNT_IS_NOT_GUARDIAN_OR_APETH(msg.sender);
        _;
    }

    /// @dev Construct APEthStorage
    constructor() {
        // Set the guardian upon deployment
        guardian = tx.origin;
    }

    // Get guardian address
    function getGuardian() external view override returns (address) {
        return guardian;
    }

    // Transfers guardianship to a new address
    function setGuardian(address _newAddress) external override onlyGuardian {
        // Store new address awaiting confirmation
        newGuardian = _newAddress;
    }

    // Confirms change of guardian
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

    // Get the APEth contract address
    function getAPEth() external view override returns (address) {
        return apEth;
    }

    // Set the APEth contract address
    function setAPEth(address _newAddress) external override onlyGuardian {
        if (apEth != address(0)) revert APEthStorage__CAN_ONLY_BE_SET_ONCE();
        apEth = _newAddress;
    }

    // Confirms burning guardianship
    function burnKeys() external override onlyGuardian {
        // Check that new guardian has been set to zero address (are you sure?)
        if (address(0) != newGuardian) revert APEthStorage__MUST_SET_TO_0X0_FIRST();
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
    function setAddress(bytes32 _key, address _value) external override onlyGuardianOrAPEth {
        addressStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setUint(bytes32 _key, uint256 _value) external override onlyGuardianOrAPEth {
        uintStorage[_key] = _value;
    }

    /// @param _key The key for the record
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
