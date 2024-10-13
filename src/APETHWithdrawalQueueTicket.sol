// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

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
import {ERC721Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import {AccessControlUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IAPETHWithdrawalQueueTicket} from "./interfaces/IAPETHWithdrawalQueueTicket.sol";

/**
 *
 * CONTRACT
 *
 */
contract APETHWithdrawalQueueTicket is
    Initializable,
    ERC721Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    IAPETHWithdrawalQueueTicket
{
    /**
     *
     * STORAGE
     *
     */
    bytes32 private constant APETH_CONTRACT = keccak256("APETH_CONTRACT");
    bytes32 private constant UPGRADER = keccak256("UPGRADER");
    /// @dev uses storage slots (caution when upgrading)
    uint256 public tokenIdCounter;

    /// @dev uses storage slots (caution when upgrading)
    mapping(uint256 => uint256) public tokenIdToExitQueueTimestamp;

    /// @dev uses storage slots (caution when upgrading)
    mapping(uint256 => uint256) public tokenIdToExitQueueExitAmount;

    /**
     *
     * FUNCTIONS
     *
     */
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __ERC721_init("APETH Withdrawal Queue Ticket", "APETHWQT");
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
    }

    function mint(address to, uint256 exitQueueTimestamp, uint256 exitQueueExitAmount)
        public
        onlyRole(APETH_CONTRACT)
    {
        tokenIdCounter++;
        tokenIdToExitQueueTimestamp[tokenIdCounter] = exitQueueTimestamp;
        tokenIdToExitQueueExitAmount[tokenIdCounter] = exitQueueExitAmount;
        _safeMint(to, tokenIdCounter);
        emit Mint(to, tokenIdCounter);
    }

    function burn(uint256 tokenId) public onlyRole(APETH_CONTRACT) {
        _burn(tokenId);
        emit Burn(msg.sender, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return (
            ERC721Upgradeable.supportsInterface(interfaceId) || AccessControlUpgradeable.supportsInterface(interfaceId)
        );
    }

    function ownerOf(uint256 tokenId)
        public
        view
        override(IAPETHWithdrawalQueueTicket, ERC721Upgradeable)
        returns (address)
    {
        return super.ownerOf(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(IAPETHWithdrawalQueueTicket, ERC721Upgradeable)
        returns (string memory)
    {
        // TODO: add art
        return super.tokenURI(tokenId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER) {}
}
