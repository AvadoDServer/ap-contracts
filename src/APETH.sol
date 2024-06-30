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
import {ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {AccessControlUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {ERC20PermitUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IEigenPodManager} from "@eigenlayer-contracts/interfaces/IEigenPodManager.sol";
import {Clones} from "@openzeppelin-contracts/proxy/Clones.sol";
import {IAPEthStorage} from "./interfaces/IAPEthStorage.sol";
import {IAPETH, IERC20} from "./interfaces/IAPETH.sol";
import {IAPEthPodWrapper} from "./interfaces/IAPEthPodWrapper.sol";

/**
 *
 * ERRORS
 *
 */
/// @notice thrown when attempting to stake when there is not enough eth in the contract
error APETH__NOT_ENOUGH_ETH();

/// @notice thrown when attempting to mint over cap
error APETH__CAP_REACHED();

/// @notice thrown when inquiring about a pod index higher than the number of pods
error APETH__NO_POD_AT_THIS_INDEX(uint256 podIndex);

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
    function mint() external payable onlyRole(EARLY_ACCESS) returns (uint256) {
        uint256 amount = msg.value * 1 ether / _ethPerAPEth(msg.value);
        uint256 cap = apEthStorage.getUint(keccak256(abi.encodePacked("cap.Amount")));
        if (totalSupply() + amount > cap) revert APETH__CAP_REACHED();
        uint256 fee = amount * apEthStorage.getUint(keccak256(abi.encodePacked("fee.Amount"))) / 100000;
        address feeRecipient = apEthStorage.getAddress(keccak256(abi.encodePacked("fee.recipient.address")));
        amount = amount - fee;
        _mint(msg.sender, amount);
        _mint(feeRecipient, fee);
        emit Mint(msg.sender, amount);
        return (amount);
    }

    /**
     * @notice This function calculates the ratio of ETH per APEth token - this will increase as the stakng rewards accrue
     * @return valueInEth assumes 18 decimals (divide by 1e18 to get ratio of eth/apeth)
     */
    function ethPerAPEth() external view returns (uint256 valueInEth) {
        return _ethPerAPEth(0);
    }

    /**
     * @notice This function calculates the ratio of ETH per APEth token - adjusting for what a user just sent into the contract
     * @param _value is the amount in wei deposited to the APEth contract, used to calculate the return value of APEth
     * @return valueInEth assumes 18 decimals (divide by 1e18 to get ratio of eth/apeth)
     */
    function _ethPerAPEth(uint256 _value) internal view returns (uint256 valueInEth) {
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
     * @param pubKey the public key of the new validator (generated by contract owner)
     * @param signature signature associated with _pubKey (generated by contract owner)
     * @param depositDataRoot data root for this deposit  (generated by contract owner)
     *
     */
    function stake(uint256 podIndex, bytes calldata pubKey, bytes calldata signature, bytes32 depositDataRoot)
        external
        onlyRole(ETH_STAKER)
    {
        // requires 32 ETH
        if (address(this).balance < 32 ether) revert APETH__NOT_ENOUGH_ETH();
        if (podIndex == 0) {
            // get EigenPodManager from storage
            IEigenPodManager eigenPodManager = IEigenPodManager(
                apEthStorage.getAddress(keccak256(abi.encodePacked("external.contract.address", "EigenPodManager")))
            );
            // Stake into eigenPod using the eigenPodManager
            eigenPodManager.stake{value: 32 ether}(pubKey, signature, depositDataRoot);
        } else {
            (, address wrapperAddress) = getPodAddress(podIndex);
            IAPEthPodWrapper(wrapperAddress).stake{value: 32 ether}(pubKey, signature, depositDataRoot);
        }
        // increase the number of active validators for accounting
        apEthStorage.addUint(keccak256(abi.encodePacked("active.validators")), 1);
        emit Stake(podIndex, pubKey, msg.sender);
    }

    /**
     *
     * @notice deploys an additional eigenpod and adds address to list of eigen pod addresses.
     * @dev the pod.index key stores the number of additional pods deployed (the orignal pod is 0)
     *
     */
    function deployPod() external onlyRole(ETH_STAKER) {
        apEthStorage.addUint(keccak256(abi.encodePacked("pod.index")), 1);
        uint256 podIndex = getPodIndex();
        // get implementation address from storage
        address apEthPodWrapperImplementation =
            apEthStorage.getAddress(keccak256(abi.encodePacked("contract.address", "APEthPodWrapper.implementation")));
        // deploy clone
        address wrapperInstance = Clones.clone(apEthPodWrapperImplementation);
        // store clone address
        apEthStorage.setAddress(
            keccak256(abi.encodePacked("contract.address", "APEthPodWrapper", podIndex)), wrapperInstance
        );
        // apply interface to clone
        IAPEthPodWrapper apEthPodWrapper = IAPEthPodWrapper(wrapperInstance);
        // initialize clone
        apEthPodWrapper.initialize(address(apEthStorage));
        // get pod address
        address podAddress = apEthPodWrapper.eigenPod();
        // store address of pod
        apEthStorage.setAddress(
            keccak256(abi.encodePacked("external.contract.address", "EigenPod", podIndex)), podAddress
        );
    }

    /**
     *
     * @notice returns the number of (additional) pods deployed (the original pod is 0)
     * @dev the pod.index key stores the number of additional pods deployed (the orignal pod is 0)
     *
     */
    function getPodIndex() public view returns (uint256 podIndex) {
        return apEthStorage.getUint(keccak256(abi.encodePacked("pod.index")));
    }

    /**
     *
     * @notice returns the address of a pod and the address of its apEth wrapper
     * @param podIndex is the index of the pod (the orignal pod is 0)
     * @return podAddress is the address of the pod at the index requested
     * @return podWrapper is the address of the ERC1167 clone that owns the pod
     *
     */
    function getPodAddress(uint256 podIndex) public view returns (address podAddress, address podWrapper) {
        if (podIndex > getPodIndex()) revert APETH__NO_POD_AT_THIS_INDEX(podIndex);
        if (podIndex == 0) {
            return (
                apEthStorage.getAddress(keccak256(abi.encodePacked("external.contract.address", "EigenPod"))),
                address(this)
            );
        } else {
            podAddress =
                apEthStorage.getAddress(keccak256(abi.encodePacked("external.contract.address", "EigenPod", podIndex)));
            podWrapper =
                apEthStorage.getAddress(keccak256(abi.encodePacked("contract.address", "APEthPodWrapper", podIndex)));
        }
    }

    /**
     *
     * @notice allows contract owner to call functions on the ssvNetwork
     * @dev the likley functions called would include "registerValidator" and "setFeeRecipientAddress"
     * @param podIndex is the index of the pod (the orignal pod is 0)
     * @param data the calldata for the ssvNetwork
     *
     */
    function callSSVNetwork(uint256 podIndex, bytes memory data) external onlyRole(ADMIN) {
        if (podIndex == 0) {
            // get address from storage
            address ssvNetwork =
                apEthStorage.getAddress(keccak256(abi.encodePacked("external.contract.address", "SSVNetwork")));
            (bool success,) = ssvNetwork.call(data);
            require(success, "Call failed");
        } else {
            // get address
            (, address podWrapperAddress) = getPodAddress(podIndex);
            //call function on pod wrapper
            IAPEthPodWrapper(podWrapperAddress).callSSVNetwork(data);
        }
    }

    /**
     *
     * @notice allows contract owner to call functions on the eigenPod
     * @dev the likley functions called would include "recoverTokens" and "withdrawNonBeaconChainETHBalanceWei"
     * @param podIndex is the index of the pod (the orignal pod is 0)
     * @param data the calldata for the eigenPod
     *
     */
    function callEigenPod(uint256 podIndex, bytes memory data) external onlyRole(ADMIN) {
        // get address
        (address eigenPodAddress, address podWrapperAddress) = getPodAddress(podIndex);
        if (podIndex == 0) {
            (bool success,) = eigenPodAddress.call(data);
            require(success, "Call failed");
        } else {
            IAPEthPodWrapper podWrapper = IAPEthPodWrapper(podWrapperAddress);
            podWrapper.callEigenPod(data);
        }
    }

    /**
     *
     * @notice allows contract owner to call functions on the eigenPodManager
     * @dev the only functions that the contract owner can currently call are "createPod" and "stake"
     * @dev these functions are handled elsewhere in this contract, so this method may be redundant
     * @param podIndex is the index of the pod (the orignal pod is 0)
     * @param data the calldata for the eigenPodManager
     *
     */
    function callEigenPodManager(uint podIndex, bytes memory data) external onlyRole(ADMIN) {
        if (podIndex == 0) {
            // get address from storage
            address eigenPodManager =
                apEthStorage.getAddress(keccak256(abi.encodePacked("external.contract.address", "EigenPodManager")));
            (bool success,) = eigenPodManager.call(data);
            require(success, "Call failed");
        } else {
            // get address
            (, address podWrapperAddress) = getPodAddress(podIndex);
            IAPEthPodWrapper(podWrapperAddress).callEigenPodManager(data);
        }
    }

    /**
     *
     * @notice allows contract owner to call transfer out ERC20's incase of an airdrop (for distribution to users)
     * @param podIndex is the index of the pod (the orignal pod is 0)
     * @param tokenAddress the ERC20 being transfered
     * @param to the token recipient
     * @param amount the amount to transfer
     *
     */
    function transferToken(uint256 podIndex, address tokenAddress, address to, uint256 amount)
        external
        onlyRole(ADMIN)
    {
        if (podIndex == 0) {
            IERC20 token = IERC20(tokenAddress);
            bool success = token.transfer(to, amount);
            require(success, "Call failed");
        } else {
            // get address
            (, address podWrapperAddress) = getPodAddress(podIndex);
            //call function on pod wrapper
            IAPEthPodWrapper(podWrapperAddress).transferToken(tokenAddress, to, amount);
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER) {}
}
