// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title Liquid Restaking Token by Avado
 * @author Avado AG, Zug Switzerland
 * @notice Terms of Service: https://ava.do/terms-and-conditions/
 * @notice The main functionalities are:
 * - ERC20 token functionality
 * - Earns fees from staking (provided by DVT operators screened by Avado)
 * - Earns Restaking Fees from Eigenlayer
 * - withdrawals are not yet enabled
 */

/**
 *
 * IMPORTS
 *
 */
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 *
 * INTERFACE
 *
 */
interface IAPETH {
    /**
     *
     * EVENTS
     *
     */
    /// @notice occurs when a new validator is staked to the beacon chain
    event Stake(uint256 podIndex, bytes pubkey, address caller);

    /// @notice occurs when new APEth coins are minted
    event Mint(address minter, uint256 amount);

    /**
     *
     * FUNCTIONS
     *
     */
    function mint() external payable returns (uint256);

    function ethPerAPEth() external view returns (uint256);

    function stake(uint256 podIndex, bytes calldata _pubKey, bytes calldata _signature, bytes32 _deposit_data_root)
        external;

    function deployPod() external;

    function getPodIndex() external returns (uint256 podIndex);

    function getPodAddress(uint256 podIndex) external returns (address podAddress, address podWrapper);

    function callSSVNetwork(uint podIndex, bytes memory data) external;

    function callEigenPod(uint256 podIndex, bytes memory data) external;

    function callEigenPodManager(bytes memory data) external;

    function transferToken(uint podIndex, address tokenAddress, address to, uint256 amount) external;
}
