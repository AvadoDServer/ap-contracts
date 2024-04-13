// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {MockEigenPodManager, IMockEigenPodManager} from "./MockEigenPodManager.sol";


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