// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Withdrawal Queue Ticket for APETH
 * @author Avado AG, Zug Switzerland
 * @notice Terms of Service: https://ava.do/terms-and-conditions/
 * @notice The main functionalities are:
 * - ERC721 token functionality
 * - represents an ETH withdrawal waiting on the validator exit queue
 */

/**
 *
 * IMPORTS
 *
 */
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface IAPETHWithdrawalQueueTicket {
    /**
     *
     * EVENTS
     *
     */
    /// @notice occurs when a new ticket is minted
    event Mint(address minter, uint256 tokenId);

    /// @notice occurs when a ticket is burned
    event Burn(address burner, uint256 tokenId);

    /**
     *
     * FUNCTIONS
     *
     */
    function mint(address to, uint256 _exitQueueTimestamp, uint256 _exitQueueExitAmount) external;

    function burn(uint256 tokenId) external;

    function tokenIdCounter() external view returns (uint256);

    function tokenIdToExitQueueTimestamp(uint256 tokenId) external view returns (uint256);

    function tokenIdToExitQueueExitAmount(uint256 tokenId) external view returns (uint256);
}
