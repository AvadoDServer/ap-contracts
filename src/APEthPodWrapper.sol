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

/**
 *
 * IMPORTS
 *
 */

import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {IEigenPodManager} from "@eigenlayer-contracts/interfaces/IEigenPodManager.sol";
import {IEigenPod} from "@eigenlayer-contracts/interfaces/IEigenPod.sol";
import {IAPEthStorage} from "./interfaces/IAPEthStorage.sol";
import {IAPETH, IERC20} from "./interfaces/IAPETH.sol";
import {IAPEthPodWrapper} from "./interfaces/IAPEthPodWrapper.sol";

/**
 *
 * ERRORS
 *
 */
/// @notice thrown when attempting to stake when there is not enough eth in the contract
error CALLER_MUST_BE_APETH(address caller);

contract APEthPodWrapper is IAPEthPodWrapper, Initializable {
    /**
     *
     * STORAGE
     *
     */
    /// @dev storage outside of upgradeable storage
    IAPEthStorage public apEthStorage;
    address public eigenPod;

    /**
     *
     * MODIFIERS
     *
     */
    modifier onlyAPEth() {
        address apeth = apEthStorage.getAPEth();
        if(msg.sender != apeth) revert CALLER_MUST_BE_APETH(msg.sender);
        _;
    } 

    /**
     *
     * FUNCTIONS
     *
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _apEthStorage) external initializer {
        apEthStorage = IAPEthStorage(_apEthStorage);
        IEigenPodManager eigenPodManager = IEigenPodManager(
            apEthStorage.getAddress(keccak256(abi.encodePacked("external.contract.address", "EigenPodManager")))
        );
        eigenPod = eigenPodManager.createPod();
    }

    function callEigenPod(bytes memory data) external onlyAPEth() returns(bool success){
        (success,) = eigenPod.call(data);
    }
}
