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
        if (msg.sender != apeth) revert CALLER_MUST_BE_APETH(msg.sender);
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

    /*
     *
     * @notice stakes 32 ETH from this pool to the deposit contract, accepts validator info
     * @dev the eigenPod ensures that the withdrawal_keys are set to the eigenPod
     * @param pubKey the public key of the new validator (generated by contract owner)
     * @param signature signature associated with _pubKey (generated by contract owner)
     * @param depositDataRoot data root for this deposit  (generated by contract owner)
     *
     */
    function stake(bytes calldata pubKey, bytes calldata signature, bytes32 depositDataRoot)
        external
        payable
        onlyAPEth
    {
        // get EigenPodManager from storage
        IEigenPodManager eigenPodManager = IEigenPodManager(
            apEthStorage.getAddress(keccak256(abi.encodePacked("external.contract.address", "EigenPodManager")))
        );
        // Stake into eigenPod using the eigenPodManager
        eigenPodManager.stake{value: 32 ether}(pubKey, signature, depositDataRoot);
    }

    function callEigenPod(bytes memory data) external onlyAPEth returns (bool success) {
        (success,) = eigenPod.call(data);
    }
}
