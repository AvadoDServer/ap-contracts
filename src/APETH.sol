// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

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
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {AccessControlUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {ERC20PermitUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IEigenPodManager} from "@eigenlayer-contracts/interfaces/IEigenPodManager.sol";
import {IEigenPod} from "@eigenlayer-contracts/interfaces/IEigenPod.sol";
import {IDelegationManager} from "@eigenlayer-contracts/interfaces/IDelegationManager.sol";
import {IAPETH, IERC20} from "./interfaces/IAPETH.sol";

/**
 *
 * ERRORS
 *
 */
/// @notice thrown when attempting to stake when there is not enough eth in the contract
error APETH__NOT_ENOUGH_ETH();

/// @notice thrown when attempting to mint over cap
error APETH__CAP_REACHED();

/**
 *
 * CONTRACT
 *
 */
contract APETH is
    IAPETH,
    Initializable,
    ERC20Upgradeable,
    AccessControlUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;
    /**
     *
     * STORAGE
     *
     */
    /// @dev storage outside of upgradeable storage

    bytes32 private constant ETH_STAKER = keccak256("ETH_STAKER");
    bytes32 private constant EARLY_ACCESS = keccak256("EARLY_ACCESS");
    bytes32 private constant UPGRADER = keccak256("UPGRADER");
    bytes32 private constant MISCELLANEOUS = keccak256("MISCELLANEOUS");
    bytes32 private constant SSV_NETWORK_ADMIN = keccak256("SSV_NETWORK_ADMIN");
    bytes32 private constant DELEGATION_MANAGER_ADMIN = keccak256("DELEGATION_MANAGER_ADMIN");
    bytes32 private constant EIGEN_POD_ADMIN = keccak256("EIGEN_POD_ADMIN");
    bytes32 private constant EIGEN_POD_MANAGER_ADMIN = keccak256("EIGEN_POD_MANAGER_ADMIN");
    uint256 private constant PRECISION = 1e5;

    /// @dev Immutables because will disappear in the next upgrade
    uint256 private immutable INITIAL_CAP;

    /// @dev Immutables because these are not going to change
    IEigenPodManager private immutable EIGEN_POD_MANAGER;
    address private immutable DELEGATION_MANAGER;
    address private immutable SSV_NETWORK;

    /// @dev Immutables because these are not going to change without a contract upgrade
    uint256 private immutable FEE_AMOUNT; // divided by PRECISION in calculation

    /// @dev uses storage slots (caution when upgrading)
    uint256 public activeValidators;
    address public feeRecipient;

    /**
     *
     * FUNCTIONS
     *
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    /// @dev eigenPod value needs to
    constructor(
        uint256 initialCap,
        IEigenPodManager eigenPodManager,
        address delegationManager,
        address ssvNetwork,
        uint256 feeAmount
    ) {
        _disableInitializers();

        // enforce feeAmount to be within range ( max 10% )
        require(feeAmount < 10000, "feeAmount out of range");

        INITIAL_CAP = initialCap;
        EIGEN_POD_MANAGER = eigenPodManager;
        DELEGATION_MANAGER = delegationManager;
        SSV_NETWORK = ssvNetwork;
        FEE_AMOUNT = feeAmount;
    }

    function initialize(address admin) public initializer {
        __ERC20_init("AP-Restaked-Eth", "APETH");
        __AccessControl_init();
        __ERC20Permit_init("AP-Restaked-Eth");
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        feeRecipient = admin;

        EIGEN_POD_MANAGER.createPod();
    }

    /**
     * @notice adding ETH without minting APEth is allowed. External rewards
     * @notice such as restaking might be converted to ETH and sent here.
     */
    receive() external payable {}

    /**
     * @notice This function mints new APEth tokens when ETH is deposited
     * @notice there is an early access list which only allows approved minters
     * @dev A deposit fee in APEth is taken and sent to a fee recipient - this is the only fee charged by this protocol
     */
    function mint() external payable onlyRole(EARLY_ACCESS) returns (uint256) {
        uint256 amount = (msg.value * 1 ether) / _ethPerAPEth(msg.value);

        if (totalSupply() + amount > INITIAL_CAP) {
            revert APETH__CAP_REACHED();
        }

        uint256 fee = (amount * FEE_AMOUNT) / PRECISION;
        amount = amount - fee;

        _mint(msg.sender, amount);
        _mint(feeRecipient, fee);

        emit Mint(msg.sender, amount);

        return amount;
    }

    /**
     * @notice This function calculates the ratio of ETH per APEth token - this will increase as the stakng rewards accrue
     * @return uint256 assumes 18 decimals (divide by 1e18 to get ratio of eth/apeth)
     */
    function ethPerAPEth() external view returns (uint256) {
        return _ethPerAPEth(0);
    }

    /**
     * @notice This function calculates the ratio of ETH per APEth token - adjusting for what a user just sent into the contract
     * @param _value is the amount in wei deposited to the APEth contract, used to calculate the return value of APEth
     * @return uint256 assumes 18 decimals (divide by 1e18 to get ratio of eth/apeth)
     */
    function _ethPerAPEth(uint256 _value) internal view returns (uint256) {
        // don't divide by 0
        if (totalSupply() == 0) {
            return 1 ether;
        } else {
            // subtract the amount a user has deposited from contract balance
            uint256 totalEth = address(this).balance + (32 ether * activeValidators) - _value;
            // multiplied by 1 ether so there is an implied 18 decimal response
            return ((totalEth * 1 ether) / totalSupply());
        }
    }

    /**
     *
     * @notice stakes 32 ETH from this pool to the deposit contract, accepts validator info
     * @dev the eigenPod ensures that the withdrawal_keys are set to the eigenPod
     * @param _pubKey the public key of the new validator (generated by contract owner)
     * @param _signature signature associated with _pubKey (generated by contract owner)
     * @param _deposit_data_root data root for this deposit  (generated by contract owner)
     *
     */
    function stake(bytes calldata _pubKey, bytes calldata _signature, bytes32 _deposit_data_root)
        external
        onlyRole(ETH_STAKER)
    {
        // requires 32 ETH
        if (address(this).balance < 32 ether) revert APETH__NOT_ENOUGH_ETH();
        // Stake into eigenPod using the eigenPodManager
        EIGEN_POD_MANAGER.stake{value: 32 ether}(_pubKey, _signature, _deposit_data_root);
        // increase the number of active validators for accounting
        activeValidators++;
        emit Stake(_pubKey, msg.sender);
    }

    /**
     *
     * @notice allows contract owner to call functions on the ssvNetwork
     * @dev the likley functions called would include "registerValidator" and "setFeeRecipientAddress"
     * @param data the calldata for the ssvNetwork
     *
     */
    function callSSVNetwork(bytes memory data) external onlyRole(SSV_NETWORK_ADMIN) {
        (bool success,) = SSV_NETWORK.call(data);
        require(success, "Call failed");
    }

    /**
     *
     * @notice allows contract owner to call functions on the eigenPod
     * @dev the likley functions called would include "recoverTokens" and "withdrawNonBeaconChainETHBalanceWei"
     * @param data the calldata for the eigenPod
     *
     */
    function callEigenPod(bytes memory data) external onlyRole(EIGEN_POD_ADMIN) {
        address eigenPod = address(EIGEN_POD_MANAGER.getPod(address(this)));
        (bool success,) = eigenPod.call(data);
        require(success, "Call failed");
    }

    /**
     *
     * @notice allows contract owner to call functions on the eigenPodManager
     * @dev the only functions that the contract owner can currently call are "createPod" and "stake"
     * @dev these functions are handled elsewhere in this contract, so this method may be redundant
     * @param data the calldata for the eigenPodManager
     *
     */
    function callEigenPodManager(bytes memory data) external onlyRole(EIGEN_POD_MANAGER_ADMIN) {
        (bool success,) = address(EIGEN_POD_MANAGER).call(data);
        require(success, "Call failed");
    }

    /**
     *
     * @notice allows contract owner to call functions on the delegationManager
     * @dev this is how the pod will delegate and undelegate its stake to an operator,
     * @dev this is also how ETH is removed from the eigen pod.
     * @param data the calldata for the delegationManager
     * @param validatorsExited this is the number of validators-worth-of-eth which will be returned in this transaction
     * @dev it is important that the amount of eth returned to this contract in this call corresponds to the number of validators exited
     * @dev if there is not some multiple of 32 ETH being recieved from this txn, validatorsExited should be zero.
     *
     */
    function callDelegationManager(bytes memory data, uint256 validatorsExited)
        external
        onlyRole(DELEGATION_MANAGER_ADMIN)
    {
        (bool success,) = DELEGATION_MANAGER.call(data);
        require(success, "Call failed");
        activeValidators -= validatorsExited;
    }

    /**
     *
     * @notice allows contract owner to call transfer out ERC20's incase of an airdrop (for distribution to users)
     * @param tokenAddress the ERC20 being transfered
     * @param to the token recipient
     * @param amount the amount to transfer
     *
     */
    function transferToken(address tokenAddress, address to, uint256 amount) external onlyRole(MISCELLANEOUS) {
        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(to, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER) {}

    /**
     * @notice This set fee recipient address
     */
    function setFeeRecipient(address _feeRecipient) external onlyRole(UPGRADER) {
        require(_feeRecipient != address(0), "Fee recipient cannot be zero address");
        feeRecipient = _feeRecipient;
    }
}
