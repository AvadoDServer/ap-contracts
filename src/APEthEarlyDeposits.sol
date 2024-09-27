// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

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
contract APEthEarlyDeposits is Ownable {
    /**
     *
     * STORAGE
     *
     */
    IAPETH public _APETH;
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
    constructor(address _owner) Ownable(_owner) {
        //
    }

    function updateAPEth(address _APEth) external onlyOwner {
        _APETH = IAPETH(payable(_APEth));
    }

    function deposit(address _depositor) public payable {
        deposits[_depositor] += msg.value;
        emit Deposit(_depositor, msg.value);
    }

    receive() external payable {
        deposit(msg.sender);
    }

    fallback() external payable {
        deposit(msg.sender);
    }

    function mintAPEthBulk(address[] calldata recipients) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            require(address(_APETH) != address(0), "APEth contract address not set");
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
        (bool success, /*return data*/ ) = msg.sender.call{value: amount}("");
        assert(success);
        emit Withdrawal(msg.sender, amount);
    }
}
