// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title APEth early depositor contract
 * @author Aqua Patina - A Product of AVADO AG, Zug Switzerland
 * @notice Terms of Service: https://www.aquapatina.com/blog/terms-of-service
 * @notice The main functionalities are:
 * @notice - Receive ETH from early depositors
 * @notice - Depositors can withdraw their eth before launch
 * @notice - Contract owner can "flush" early deposits so that users
 * @notice   recieve APEth for their deposit
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
contract APEthEarlyDeposits is Ownable, EIP712 {
    event Debug(string message);

    string private constant SIGNING_DOMAIN = "APEthEarlyDeposits";
    string private constant SIGNATURE_VERSION = "1";

    // Define an early deposit structure
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
    constructor(address _owner, address _verifierAddress) Ownable(_owner) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        verifierAddress = _verifierAddress;
    }

    /**
     * @notice disable receiving ETH
     */
    receive() external payable {
        revert("Sending ETH not allowed");
    }

    fallback() external payable {
        revert("Sending ETH not allowed");
    }

    /**
     * @notice Deposit ETH to the queue involves sending ETH as well as provising a _signature
     * @notice that whitelists the sender. This signature is received when a user signs up
     * @notice the signature can be re-used by the same sender multiple times. This is by design.
     * @notice By using EIP712 the re-use is limited to this contract only.
     */
    function deposit(bytes memory _signature) public payable {
        EarlyDeposit memory _deposit = EarlyDeposit({sender: msg.sender});
        require(verify(_deposit, _signature), "invalid signature");
        deposits[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice as long as the ETH hasn't been converted into apETH
     * @notice the user is free to withdraw his deposit
     */
    function withdraw() external {
        uint256 amount = deposits[msg.sender];
        deposits[msg.sender] = 0;
        (bool success, /*return data*/ ) = msg.sender.call{value: amount}("");
        assert(success);
        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @notice This function allows to set the apETH contract address once it has been deployed
     * @notice this allows to start depositing before having deployed the apETH contract
     * @dev This address can only be set once - and should be set to the apETH contract proxy address later on
     */
    function updateAPEth(address _APEth) external onlyOwner {
        require(address(_APETH) == address(0), "Contract address already set");
        _APETH = IAPETH(payable(_APEth));
    }

    /**
     * @notice mint tokens for selected recipients
     */
    function mintAPEthBulk(address[] calldata recipients) external onlyOwner {
        require(address(_APETH) != address(0), "APEth contract address not set");
        for (uint256 i = 0; i < recipients.length; i++) {
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

    /**
     * @notice generate the structHash of the EarlyDeposit struct (EIP712)
     * @dev external because it's used by the signer account during the signup
     */
    function generateHash(EarlyDeposit memory _deposit) external view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(keccak256("EarlyDeposit(address sender)"), _deposit.sender)));
    }

    /**
     * @notice verify that the signature matches the EarlyDeposit data
     * @notice and was signed by the verifierAddress
     */
    function verify(EarlyDeposit memory _deposit, bytes memory _signature) internal view returns (bool) {
        bytes32 digest = this.generateHash(_deposit);
        address recoveredAddress = recover(digest, _signature);
        return recoveredAddress == verifierAddress;
    }

    /**
     * @notice recover the signer address from _digest and _signature
     */
    function recover(bytes32 _digest, bytes memory _signature) public pure returns (address) {
        return ECDSA.recover(MessageHashUtils.toEthSignedMessageHash(_digest), _signature);
    }
}
