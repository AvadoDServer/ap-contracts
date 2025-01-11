pragma solidity 0.8.21;
//SPDX-License-Identifier: MIT

interface IAPEthDeposits {
    struct Deposit {
        address depositor;
        uint256 amount;
        bool withdrawn;
    }

    function deposit() external payable;
    function mintAPEthBulk(uint128 numberOfDeposits) external returns (bool);
    function withdraw(uint128 depositIndex) external;
}
