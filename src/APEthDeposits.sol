// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

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
import {IAPEthDeposits} from "./interfaces/IAPEthDeposits.sol";
import {AccessControlUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

/**
 *
 * ERRORS
 *
 */
/// @notice thrown when numberOfDeposits for minting is too high for existing Index
error APETH_DEPOSITS__NUMBER_OF_DEPOSITS_TOO_HIGH();

/// @notice thrown when deposit is less than minimum deposit
error APETH_DEPOSITS__LESS_THAN_MINIMUM_DEPOSIT();

/// @notice thrown when a withdraw is attempted by an address other than the depositor
error APETH_DEPOSITS__SENDER_MUST_BE_DEPOSITOR();

/// @notice thrown when a withdrawal is attempted on a deposit that has already been withdrawn
error APETH_DEPOSITS__DEPOSIT_WITHDRAWN();

/**
 *
 * CONTRACT
 *
 */
contract APEthDeposits is IAPEthDeposits, Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    /**
     *
     * STORAGE
     *
     */
    /// @dev storage outside of upgradeable storage
    bytes32 private constant UPGRADER = keccak256("UPGRADER");
    bytes32 private constant APETH_CONTRACT = keccak256("APETH_CONTRACT");

    /// @dev Immutables because these are not going to change
    IAPETH public immutable _APETH;

    /// @dev uses storage slots (caution when upgrading)
    uint128 private _depositIndex;
    uint128 private _nextMint;
    uint256 public minDeposit;
    mapping(uint128 => Deposit) public deposits;

    /**
     *
     * EVENTS
     *
     */
    /// @notice occurs when a user makes a deposit
    event Deposited(address depositor, uint256 amount, uint128 index);

    /// @notice occurs when a user withdrawals their funds
    event Withdrawal(address withdrawor, uint256 amount, uint128 index);

    /// @notice occurs when a users funds are used to mint APEth
    event Minted(address recipient, uint256 amount, uint128 index);

    /**
     *
     * FUNCTIONS
     *
     */
    constructor(IAPETH APETH_) {
        _disableInitializers();
        _APETH = APETH_;
    }

    function initialize(address admin, uint256 minDeposit_) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(APETH_CONTRACT, address(_APETH));
        _grantRole(UPGRADER, admin);
        _nextMint++;
        minDeposit = minDeposit_;
    }

    function deposit(address depositor) public payable {
        if (msg.value < minDeposit) revert APETH_DEPOSITS__LESS_THAN_MINIMUM_DEPOSIT();
        _depositIndex++;
        Deposit storage d = deposits[_depositIndex];
        d.depositor = depositor;
        d.amount = msg.value;
        emit Deposited(d.depositor, msg.value, _depositIndex);
    }

    function deposit() external payable {
        deposit(msg.sender);
    }

    receive() external payable {
        deposit(msg.sender);
    }

    fallback() external payable {
        deposit(msg.sender);
    }

    function mintAPEthBulk(uint128 numberOfDeposits) external onlyRole(APETH_CONTRACT) returns (bool) {
        if (numberOfDeposits + _nextMint > ++_depositIndex) revert APETH_DEPOSITS__NUMBER_OF_DEPOSITS_TOO_HIGH();
        for (uint128 i = _nextMint; i < _nextMint + numberOfDeposits; i++) {
            Deposit storage d = deposits[i];
            uint256 newCoins;
            if (!d.withdrawn) {
                uint256 amount = d.amount;
                d.amount = 0;
                newCoins = _APETH.mint{value: amount}(d.depositor);
                emit Minted(d.depositor, newCoins, i);
            }
        }
        _nextMint += numberOfDeposits; //TODO: check math
        return (true);
    }

    function withdraw(uint128 index) external {
        Deposit storage d = deposits[index];
        if (d.depositor != msg.sender) revert APETH_DEPOSITS__SENDER_MUST_BE_DEPOSITOR();
        if (d.withdrawn) revert APETH_DEPOSITS__DEPOSIT_WITHDRAWN();
        uint256 amount = d.amount;
        d.withdrawn = true;
        d.amount = 0;
        (bool success, /*return data*/ ) = msg.sender.call{value: amount}("");
        assert(success);
        emit Withdrawal(msg.sender, amount, index);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER) {}
}
