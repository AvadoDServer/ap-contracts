// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IDepositContract.sol";

contract APETH is Initializable, ERC20Upgradeable, OwnableUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {
    /*********************************************************************
    STORAGE TODO: consider moving to its own contract
    *********************************************************************/
    IDepositContract public depositContract;

    address ssvNetwork; // TODO: load in initiaizer or elsewhere

    uint256 activeValidators;

    /*********************************************************************
    EVENTS
    *********************************************************************/
    event Stake(address depositContractAddress, address caller);

    /*********************************************************************
    ERRORS
    *********************************************************************/
    ///@notice thrown when attempting to stake when there is not enough eth in the contract
    error NOT_ENOUGH_ETH();

    ///@notice thrown when the provided withdrawal credentials do not point to the current contract.
    error WITHDRAWAL_CREDENTIAL_MISMATCH();

    /*********************************************************************
    MODIFIERS
    *********************************************************************/

    /*********************************************************************
    FUNCTIONS
    *********************************************************************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, address _depositContract) initializer public {
        __ERC20_init("AP-Restaked-Eth", "APETH");
        __Ownable_init(initialOwner);
        __ERC20Permit_init("AP-Restaked-Eth");
        __UUPSUpgradeable_init();
        depositContract = IDepositContract(_depositContract);
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
            uint256 totalEth = address(this).balance + (32 ether * activeValidators) - _value;
            return(totalEth * 1 ether / totalSupply());
        }
    }

        ///@dev stakes 32 ETH from this pool to the deposit contract, accepts validator info
        // TODO: deposit to eigenpod
    function stake(
        bytes calldata _pubKey,
        bytes calldata _withdrawal_credentials,
        bytes calldata _signature,
        bytes32 _deposit_data_root
    ) external onlyOwner {
        if(address(this).balance < 32 ether)  revert NOT_ENOUGH_ETH();
        //compare expected withdrawal_credentials to provided
        if(
            keccak256(_withdrawal_credentials) !=
                keccak256(_getWithdrawalCred())
        ) {
            revert WITHDRAWAL_CREDENTIAL_MISMATCH();
        }
        depositContract.deposit{value: 32 ether}(
            _pubKey,
            _withdrawal_credentials,
            _signature,
            _deposit_data_root
        );
        activeValidators += 1;
        emit Stake(address(depositContract), msg.sender);
    }

    ///@dev translates the addres of this contract to withdrawal credential format
    function _getWithdrawalCred() private view returns (bytes memory) {
        return abi.encodePacked(bytes1(0x01), bytes11(0x0), address(this));
    }

    function callSSVNetwork(bytes memory data) external onlyOwner {
        //address ssvNetwork = frensStorage.getAddress(keccak256(abi.encodePacked("external.contract.address", "SSVNetwork")));
        (bool success, ) = ssvNetwork.call(data);
        require(success, "Call failed");
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
