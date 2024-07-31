// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

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
import {ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {AccessControlUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {ERC20PermitUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IEigenPodManager} from "@eigenlayer-contracts/interfaces/IEigenPodManager.sol";
import {IEigenPod} from "@eigenlayer-contracts/interfaces/IEigenPod.sol";
import {IDelegationManager} from "@eigenlayer-contracts/interfaces/IDelegationManager.sol";
import {IAPEthStorage} from "./interfaces/IAPEthStorage.sol";
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
contract APETH is IAPETH, Initializable, ERC20Upgradeable, AccessControlUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {
    /**
     *
     * STORAGE
     *
     */
    /// @dev storage outside of upgradeable storage
    bytes32 public constant UPGRADER = keccak256("UPGRADER");
    bytes32 public constant ETH_STAKER = keccak256("ETH_STAKER");
    bytes32 public constant EARLY_ACCESS = keccak256("EARLY_ACCESS");
    bytes32 public constant ADMIN = keccak256("ADMIN");
    IAPEthStorage public apEthStorage;

    /**
     *
     * FUNCTIONS
     *
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, address _APEthStorage) public initializer {
        __ERC20_init("AP-Restaked-Eth", "APETH");
        __AccessControl_init();
        __ERC20Permit_init("AP-Restaked-Eth");
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        apEthStorage = IAPEthStorage(_APEthStorage);
        IEigenPodManager eigenPodManager = IEigenPodManager(
            apEthStorage.getAddress(keccak256(abi.encodePacked("external.contract.address", "EigenPodManager")))
        );
        address eigenPod = eigenPodManager.createPod();
        apEthStorage.setAddress(keccak256(abi.encodePacked("external.contract.address", "EigenPod")), eigenPod);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @notice This function mints new APEth tokens when ETH is deposited
     * @notice there is an early access list which only allows approved minters
     * @dev A deposit fee in APEth is taken and sent to a fee recipient - this is the only fee charged by this protocol
     */
    function mint() external payable onlyRole(EARLY_ACCESS) returns (uint256){
        uint256 amount = msg.value * 1 ether / _ethPerAPEth(msg.value);
        uint256 cap = apEthStorage.getUint(keccak256(abi.encodePacked("cap.Amount")));
        if (totalSupply() + amount > cap) revert APETH__CAP_REACHED();
        uint256 fee = amount * apEthStorage.getUint(keccak256(abi.encodePacked("fee.Amount"))) / 100000;
        address feeRecipient = apEthStorage.getAddress(keccak256(abi.encodePacked("fee.recipient.address")));
        amount = amount - fee;
        _mint(msg.sender, amount);
        _mint(feeRecipient, fee);
        emit Mint(msg.sender, amount);
        return(amount);
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
            // get # of 32 eth validators
            uint256 activeValidators = apEthStorage.getUint(keccak256(abi.encodePacked("active.validators")));
            // subtract the amount a user has deposited from contract balance
            uint256 totalEth = address(this).balance + (32 ether * activeValidators) - _value;
            // multiplied by 1 ether so there is an implied 18 decimal response
            return (totalEth * 1 ether / totalSupply());
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
    function stake(bytes calldata _pubKey, bytes calldata _signature, bytes32 _deposit_data_root) external onlyRole(ETH_STAKER) {
        // requires 32 ETH
        if (address(this).balance < 32 ether) revert APETH__NOT_ENOUGH_ETH();
        // get EigenPodManager from storage
        IEigenPodManager eigenPodManager = IEigenPodManager(
            apEthStorage.getAddress(keccak256(abi.encodePacked("external.contract.address", "EigenPodManager")))
        );
        // Stake into eigenPod using the eigenPodManager
        eigenPodManager.stake{value: 32 ether}(_pubKey, _signature, _deposit_data_root);
        // increase the number of active validators for accounting
        apEthStorage.addUint(keccak256(abi.encodePacked("active.validators")), 1);
        emit Stake(_pubKey, msg.sender);
    }

    /**
     *
     * @notice allows contract owner to call functions on the ssvNetwork
     * @dev the likley functions called would include "registerValidator" and "setFeeRecipientAddress"
     * @param data the calldata for the ssvNetwork
     *
     */
    function callSSVNetwork(bytes memory data) external onlyRole(ADMIN) {
        // get address from storage
        address ssvNetwork =
            apEthStorage.getAddress(keccak256(abi.encodePacked("external.contract.address", "SSVNetwork")));
        (bool success,) = ssvNetwork.call(data);
        require(success, "Call failed");
    }

    /**
     *
     * @notice allows contract owner to call functions on the eigenPod
     * @dev the likley functions called would include "recoverTokens" and "withdrawNonBeaconChainETHBalanceWei"
     * @param data the calldata for the eigenPod
     *
     */
    function callEigenPod(bytes memory data) external onlyRole(ADMIN) {
        // get address from storage
        address eigenPod = apEthStorage.getAddress(keccak256(abi.encodePacked("external.contract.address", "EigenPod")));
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
    function callEigenPodManager(bytes memory data) external onlyRole(ADMIN) {
        // get address from storage
        address eigenPodManager =
            apEthStorage.getAddress(keccak256(abi.encodePacked("external.contract.address", "EigenPodManager")));
        (bool success,) = eigenPodManager.call(data);
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
    function callDelegationManager(bytes memory data, uint validatorsExited) external onlyRole(ADMIN) {
        // get address from storage
        address delegationManager =
            apEthStorage.getAddress(keccak256(abi.encodePacked("external.contract.address", "DelegationManager")));
        (bool success,) = delegationManager.call(data);
        require(success, "Call failed");
        apEthStorage.subUint(keccak256(abi.encodePacked("active.validators")), validatorsExited);
    }

    /**
     *
     * @notice allows contract owner to call transfer out ERC20's incase of an airdrop (for distribution to users)
     * @param tokenAddress the ERC20 being transfered
     * @param to the token recipient
     * @param amount the amount to transfer
     *
     */
    function transferToken(address tokenAddress, address to, uint256 amount) external onlyRole(ADMIN) {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(to, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER) {}
}
