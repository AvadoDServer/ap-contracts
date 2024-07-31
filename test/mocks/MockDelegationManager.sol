// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";

interface IMockDelegationManager {
    function undelegate(address staker) external returns (bytes32[] memory withdrawalRoots);
}

contract MockDelegationManager {
    function undelegate(address staker) external  view returns (bytes32[] memory withdrawalRoots) {
        console.log("undelegate() called", staker);
        return(new bytes32[](0));
    }
}