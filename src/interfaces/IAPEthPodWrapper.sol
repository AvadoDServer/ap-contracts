// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title EigenPod Wrapper
 * @author Avado AG, Zug Switzerland
 * @notice Terms of Service: https://ava.do/terms-and-conditions/
 * @notice Each address can only deploy one EigenPod, APEth requires multiple 
 * EigenPods. This contract is a a pod deployer implementation, which will
 * have ERC-1167 minimal clone instances.
 */

interface IAPEthPodWrapper {
    function initialize(address _APEthStorage) external;
    function callEigenPod(bytes memory data) external returns(bool success);
    function eigenPod() external returns(address);
}