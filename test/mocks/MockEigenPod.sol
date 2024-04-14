// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {MockEigenPodManager, IMockEigenPodManager} from "./MockEigenPodManager.sol";
import {console} from "forge-std/console.sol";

interface IMockEigenPod{
    function eigenPodManager() external view returns (IMockEigenPodManager);
    function podOwner() external view returns (address);
    function initialize(address _owner) external;
}

contract MockEigenPod{
    IMockEigenPodManager manager;
    address owner;

    constructor() {
        manager = IMockEigenPodManager(msg.sender);
    }

    function eigenPodManager() external view returns (IMockEigenPodManager) {
        return(manager);
    }

    /// @notice The owner of this EigenPod
    function podOwner() external view returns (address) {
        console.log("podOwner() called");
        return(owner);
    }

    function initialize(address _owner) external {
        owner = _owner;
    }

    // function verifyWithdrawalCredentials(
    //     uint64 oracleTimestamp,
    //     BeaconChainProofs.StateRootProof calldata stateRootProof,
    //     uint40[] calldata validatorIndices,
    //     bytes[] calldata withdrawalCredentialProofs,
    //     bytes32[][] calldata validatorFields
    // ) external {}
}