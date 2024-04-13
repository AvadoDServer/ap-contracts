// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {MockEigenPod} from "./MockEigenPod.sol";

interface IMockEigenPodManager {
    function createPod() external returns(address);
    function stake(bytes calldata _pubKey, bytes calldata _signature, bytes32 _deposit_data_root) external;
}

contract MockEigenPodManager {
    function createPod() public returns(address){
        MockEigenPod mockEigenPod = new MockEigenPod();
        mockEigenPod.initialize(msg.sender);
        return(address(mockEigenPod));
    }

    function stake(bytes calldata _pubKey, bytes calldata _signature, bytes32 _deposit_data_root) external payable {
        //doesn't actualy need to do anything for now...
    }
}