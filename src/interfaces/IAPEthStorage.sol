pragma solidity 0.8.24;

// SPDX-License-Identifier: GPL-3.0-only
//modified from IRocketStorage on 03/12/2022 by 0xWildhare

interface IAPEthStorage {
    // Guardian
    function getGuardian() external view returns (address);
    function setGuardian(address _newAddress) external;
    function confirmGuardian() external;
    function burnKeys() external;

    // APEth
    function getAPEth() external view returns (address);
    function setAPEth(address _newAddress) external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint256);
    function getBool(bytes32 _key) external view returns (bool);

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint256 _value) external;
    function setBool(bytes32 _key, bool _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;

    // Arithmetic
    function addUint(bytes32 _key, uint256 _amount) external;
    function subUint(bytes32 _key, uint256 _amount) external;
}
