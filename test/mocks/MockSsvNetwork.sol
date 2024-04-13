// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract MockSsvNetwork{
    mapping(address=>address) public feeRecipient;

    function setFeeRecipientAddress(address _newFeeRecipient) public {
        feeRecipient[msg.sender] = _newFeeRecipient;
    }
}