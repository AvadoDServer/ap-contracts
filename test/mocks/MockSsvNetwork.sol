// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

contract MockSsvNetwork {
    mapping(address => address) public feeRecipient;

    function setFeeRecipientAddress(address _newFeeRecipient) public {
        feeRecipient[msg.sender] = _newFeeRecipient;
    }
}
