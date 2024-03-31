// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*********************************************************************
IMPORTS
*********************************************************************/
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@eigenlayer-contracts/interfaces/IEigenPodManager.sol";
import "@eigenlayer-contracts/interfaces/IEigenPod.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/IAPEthStorage.sol";

/*********************************************************************
ERRORS
*********************************************************************/
/// @notice thrown when attempting to stake when there is not enough eth in the contract
error NOT_ENOUGH_ETH();

/*********************************************************************
CONTRACT
*********************************************************************/
contract APETH is Initializable, ERC20Upgradeable, OwnableUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {
    /*********************************************************************
    STORAGE 
    *********************************************************************/
    /// @dev storage outside of upgradeable storage
    IAPEthStorage public apEthStorage;

    /*********************************************************************
    EVENTS
    *********************************************************************/
    /// @notice occurs when a new validator is staked to the beacon chain
    event Stake(bytes pubkey, address caller);

    /// @notice occurs when new APEth coins are minted
    event Mint(address minter, uint256 amount);

    /*********************************************************************
    MODIFIERS
    *********************************************************************/

    /*********************************************************************
    FUNCTIONS
    TODO: ADD METHODS TO INTERACT WITH EIGENPOD
    *********************************************************************/
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, address _APEthStorage) initializer public {
        __ERC20_init("AP-Restaked-Eth", "APETH");
        __Ownable_init(initialOwner);
        __ERC20Permit_init("AP-Restaked-Eth");
        __UUPSUpgradeable_init();
        apEthStorage = IAPEthStorage(_APEthStorage);
        IEigenPodManager eigenPodManager = IEigenPodManager(apEthStorage.getAddress(keccak256(
            abi.encodePacked("external.contract.address", "EigenPodManager")
        )));
        address eigenPod = eigenPodManager.createPod();
        apEthStorage.setAddress(keccak256(abi.encodePacked(
            "external.contract.address", "EigenPod"
        )), eigenPod);
    }

    receive() external payable {}

    fallback() external payable {}

    function mint() public payable {
        uint256 amount = msg.value * 1 ether / _ethPerAPEth(msg.value);
        //TODO: add fee
        _mint(msg.sender, amount);
    }

    function ethPerAPEth() external view returns(uint256) {
        return _ethPerAPEth(0);
    }

    function _ethPerAPEth(uint _value) internal view returns(uint256) {
        if(totalSupply() == 0) {
            return 1 ether;
        } else {
            uint256 activeValidators = apEthStorage.getUint(keccak256(abi.encodePacked("active.validators")));
            uint256 totalEth = address(this).balance + (32 ether * activeValidators) - _value;
            return(totalEth * 1 ether / totalSupply());
        }
    }

    ///@dev stakes 32 ETH from this pool to the deposit contract, accepts validator info
    function stake(
        bytes calldata _pubKey,
        bytes calldata _signature,
        bytes32 _deposit_data_root
    ) external onlyOwner {
        if(address(this).balance < 32 ether)  revert NOT_ENOUGH_ETH();
        //compare expected withdrawal_credentials to provided
        
        IEigenPodManager eigenPodManager = IEigenPodManager(apEthStorage.getAddress(
            keccak256(abi.encodePacked("external.contract.address", "EigenPodManager"))
        ));
        eigenPodManager.stake{value: 32 ether}(
            _pubKey,
            _signature,
            _deposit_data_root
        );
        apEthStorage.addUint(keccak256(abi.encodePacked("active.validators")), 1);
        emit Stake(_pubKey, msg.sender);
    }

    function callSSVNetwork(bytes memory data) external onlyOwner {
        address ssvNetwork = apEthStorage.getAddress(keccak256(
            abi.encodePacked("external.contract.address", "SSVNetwork")
        ));
        (bool success, ) = ssvNetwork.call(data);
        require(success, "Call failed");
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
