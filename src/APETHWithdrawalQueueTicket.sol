// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

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
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";

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
    using Strings for uint256;

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
        require(_ownerOf(tokenId) != address(0), "token does not exist");
        string memory name = string(abi.encodePacked("APETH Withdrawal Queue Ticket #", tokenId.toString()));
        string memory description =
            string(abi.encodePacked("APETH Withdrawal Queue Ticket #", tokenId.toString(), " for validator exit queue"));
        string memory image = Base64.encode(bytes(_getImage(tokenId)));
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name,
                            '","description":"',
                            description,
                            '", "attributes": [{"trait_type": "value", "value": "',
                            tokenIdToExitQueueExitAmount[tokenId].toString(), //TODO: this would be better is displayd in ETH instead of wei
                            '"},{"trait_type": "exitQueueTimestamp", "value": "',
                            tokenIdToExitQueueTimestamp[tokenId].toString(), //TODO: this is unix timestamp, would be better displayed as date & time
                            '"}], "image": "',
                            "data:image/svg+xml;base64,",
                            image,
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function _getImage(uint256 tokenId) internal view returns (string memory) {
        return string(
            abi.encodePacked( // TODO: stack these better so we dont need viaIR
                '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg"><defs><style>.cls-1 {fill: #a28358;transform: scale(0.5);}</style></defs><rect width="100%" height="100%" fill="#34354e" /><g transform="translate(-125,-125)"><path class="cls-1" d="M345.8,626.4h35.7c0,0,9.8-18.3,9.8-18.3l-20.2-29.3c-4.4-6.3-11.6-9.9-19.3-9.6l-37.2,1.4h-.1c-3.1.2-5.8,1.9-7.3,4.7-1.5,2.8-1.4,6,.2,8.7l19.5,31.7c4.1,6.7,11.2,10.6,19,10.6ZM352.3,582.7c3-.1,5.9,1.3,7.6,3.8l15.5,22.5-2.1,3.9h-27.6c-3.1,0-5.9-1.6-7.5-4.3l-15.3-24.8,29.3-1.1ZM554.2,575.4c-1.5-2.7-4.2-4.5-7.3-4.7l-37.4-1.5h0c-7.7-.3-14.9,3.3-19.3,9.6l-20.2,29.2,9.8,18.3h35.7c7.8,0,14.9-4,19-10.7l19.5-31.6h0c1.6-2.8,1.6-6.1.2-8.8ZM522.9,608.7c-1.6,2.6-4.4,4.2-7.5,4.2h-27.6s-2.1-3.9-2.1-3.9l15.5-22.5c1.7-2.5,4.6-4,7.6-3.8l29.3,1.1-15.3,24.8ZM440.7,694.8h-20.8l-16.3,31.6c-3.5,6.8-3.3,14.9.6,21.5l18.8,32.2h0c1.6,2.8,4.5,4.4,7.6,4.4h0c3.1,0,6-1.6,7.6-4.2l18.8-32.2c3.9-6.7,4.1-14.9.4-21.8l-16.8-31.5ZM445.4,741.3l-14.7,25.2-14.8-25.3c-1.5-2.6-1.6-5.8-.2-8.5l12.5-24.3h4.4l12.9,24.3c1.5,2.7,1.4,6-.2,8.6ZM543.3,677.1c-5.2-11.7-16.9-19.2-29.7-19.2h-42.9l-32.4-55.8,21.3-38.1c6.7-12,5.2-27-3.9-37.3-6.3-7.3-15.4-11.3-25.1-11.2-9.6.1-18.6,4.5-24.7,11.9l-1.3,1.6c-8.6,10.4-9.7,25.3-3,37l21,36.2-31.2,55.6h-43.9c-12.8,0-24.5,7.5-29.7,19.2l-1.2,2.7c-4.1,9.1-3.8,19.4.7,28.3,4.6,8.9,12.8,15.1,22.6,17.1l3.2.6c2.2.4,4.3.6,6.4.6,11.6,0,22.5-6.2,28.4-16.7l21.4-38.3h63.4l22.5,38.6c7.1,12.2,21.1,18.4,34.8,15.5l1.4-.3c9.7-2,17.9-8.3,22.4-17.1,4.5-8.8,4.7-19.1.7-28.1l-1.3-2.9ZM366.3,703.1h0c-4,7.2-12.2,11-20.4,9.4l-3.2-.6c-5.7-1.1-10.5-4.8-13.2-10-2.7-5.2-2.8-11.2-.4-16.5l1.2-2.7c3.1-6.8,9.9-11.2,17.4-11.2h36.3l-17.7,31.7ZM413.4,559.3c-4-6.8-3.3-15.5,1.7-21.6l1.3-1.6c3.6-4.4,8.8-6.9,14.5-7,0,0,.2,0,.3,0,5.5,0,10.7,2.4,14.4,6.5,5.3,6,6.2,14.8,2.3,21.8l-17.4,31.1-17-29.3ZM407.1,657.9l23.6-42.1,24.4,42.1h-48ZM531.9,702c-2.6,5.2-7.4,8.8-13.1,10l-1.4.3c-8.1,1.7-16.3-2-20.4-9.1l-18.5-31.8h35c7.5,0,14.3,4.4,17.4,11.2l1.3,3c2.4,5.3,2.2,11.3-.4,16.5Z"/><g><path class="cls-1" d="M782.7,771.1v6.8h-96.6v-6.8h2.4c17.3,0,21.1-3.1,15.6-20.1l-16-51.7h-57.8l-16.7,53c-5.4,17.3-2,18.7,15.3,18.7h2.7v6.8h-54.7v-6.8h6.8c12.6,0,16.3-5.8,19.4-14.6l67-216.6h18l70.1,218c3.1,9.5,6.8,13.3,19.4,13.3h5.1ZM685.5,690.9l-26.2-84.7-26.5,84.7h52.7Z"/><path class="cls-1" d="M875.7,667.1v85.4c0,16.7,3.1,18.7,20.4,18.7h4.8v6.8h-98.6v-6.8h4.8c17.3,0,20.4-1.7,20.4-18.7v-187c0-17-3.1-18.7-20.4-18.7h-4.8v-6.8h90.1c70.4,0,101.7,21.1,101.7,63.6s-31.3,63.6-101.7,63.6h-16.7ZM875.7,660.3h2.4c55.8,0,66.3-29.2,66.3-56.8s-10.5-56.8-66.3-56.8h-2.4v113.6Z"/></g></g><text font-size="20" x="200" y="75" text-anchor="middle" font-family="Helvetica, sans-serif" letter-spacing="2" fill="#CCCED2">',
                "Withdrawal Ticket",
                '</text><text font-size="15" x="200" y="325" text-anchor="middle" font-family="Helvetica, sans-serif" letter-spacing="2" fill="#CCCED2">',
                "Value: 3.8750 ETH", //sample TODO: put actual value
                '</text><text font-size="10" x="200" y="350" text-anchor="middle" font-family="Helvetica, sans-serif" letter-spacing="2" fill="#CCCED2">',
                "Available 25 Dec 2024 8:30 UTC", //sample TODO: put actual date
                "</text></svg>"
            )
        );
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER) {}
}
