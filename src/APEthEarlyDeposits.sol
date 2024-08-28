// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title APEth early depositor contract
 * @author Avado AG, Zug Switzerland
 * @notice Terms of Service: https://ava.do/terms-and-conditions/
 * @notice The main functionalities are:
 * - receives eth from depositors
 * - depositors can withdraw their eth
 * - contract owner (Avado) can choose early depositors to recieve APEth for their deposit
 */

/**
 *
 * IMPORTS
 *
 */
import {IAPETH, IERC20} from "./interfaces/IAPETH.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 *
 * CONTRACT
 *
 */
contract APEthEarlyDeposits is  Ownable, EIP712 {
    string private constant SIGNING_DOMAIN = "APEthEarlyDeposits";
    string private constant SIGNATURE_VERSION = "1";

    // Define an order structure
    struct EarlyDeposit {
        address sender;
    }

    /**
     *
     * STORAGE
     *
     */
    IAPETH public _APETH;
    address public verifierAddress;
    mapping(address depositor => uint256 amount) public deposits;

    /**
     *
     * EVENTS
     *
     */
    /// @notice occurs when a user makes a deposit
    event Deposit(address depositor, uint256 amount);

    /// @notice occurs when a user withdrawals their funds
    event Withdrawal(address withdrawor, uint256 amount);

    /// @notice occurs when a users funds are used to mint APEth
    event Minted(address recipient, uint256 amount);

    /**
     *
     * FUNCTIONS
     *
     */
    constructor(
        address _owner,
        address _verifierAddress
    ) Ownable(_owner) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        verifierAddress = _verifierAddress;
    }

    function updateAPEth(address _APEth) external onlyOwner {
        _APETH = IAPETH(payable(_APEth));
    }

    function deposit(EarlyDeposit memory _deposit, bytes memory _signature) public payable {
        require(verify(_deposit,_signature));
        deposits[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function verify(
        EarlyDeposit memory _deposit,
        bytes memory _signature
    ) public view returns (bool) {
        bytes32 digest = _hashTypedDataV4(_hashEarlyDeposit(_deposit));
        address recoveredAddress = ECDSA.recover(digest, _signature);
        return recoveredAddress == verifierAddress;
    }

    function _hashEarlyDeposit(
        EarlyDeposit memory _deposit
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EarlyDeposit(address sender)"),
                    _deposit.sender
                )
            );
    }

    function generateHash(
        EarlyDeposit memory _deposit
    ) external view returns (bytes32) {
        return _hashTypedDataV4(_hashEarlyDeposit(_deposit));
    }

    receive() external payable {
        revert("Sending ETH not allowed");
    }

    fallback() external payable {
        revert("Sending ETH not allowed");
    }

    function mintAPEthBulk(address[] calldata recipients) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            require(
                address(_APETH) != address(0),
                "APEth contract address not set"
            );
            _mintAPEth(recipients[i]);
        }
    }

    function _mintAPEth(address recipient) internal {
        uint256 amount = deposits[recipient];
        deposits[recipient] = 0;
        uint256 newCoins = _APETH.mint{value: amount}();
        bool success = IERC20(address(_APETH)).transfer(recipient, newCoins);
        assert(success);
        emit Minted(recipient, newCoins);
    }

    function withdraw() external {
        uint256 amount = deposits[msg.sender];
        deposits[msg.sender] = 0;
        (bool success /*return data*/, ) = msg.sender.call{value: amount}("");
        assert(success);
        emit Withdrawal(msg.sender, amount);
    }
}
