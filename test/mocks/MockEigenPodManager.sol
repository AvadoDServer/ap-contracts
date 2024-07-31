// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MockEigenPod, IMockEigenPod} from "./MockEigenPod.sol";
import {console} from "forge-std/console.sol";

interface IMockEigenPodManager {
    function createPod() external returns (address);
    function stake(bytes calldata _pubKey, bytes calldata _signature, bytes32 _deposit_data_root) external;
    function getPod(address) external returns (IMockEigenPod);
}

contract MockEigenPodManager {
    mapping(address => address) public pods;

    function createPod() public returns (address) {
        MockEigenPod mockEigenPod = new MockEigenPod();
        mockEigenPod.initialize(msg.sender);
        pods[msg.sender] = address(mockEigenPod);
        return (address(mockEigenPod));
    }

    function stake(bytes calldata _pubKey, bytes calldata _signature, bytes32 _deposit_data_root) external payable {
        //doesn't actualy need to do anything for now...
    }

    function getPod(address podOwner) public view returns (IMockEigenPod) {
        console.log("getPod() was called");
        return (IMockEigenPod(pods[podOwner]));
    }
}
