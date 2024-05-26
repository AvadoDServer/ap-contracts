pragma solidity ^0.8.24;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

contract CheckScript is Script {
    function run() external view {
        string memory root = vm.projectRoot();
        string memory path = string.concat(
            root,
            "/broadcast/",
            "deployStorage",
            ".s.sol/17000/run-latest.json"
        );
        string memory json = vm.readFile(path);
        bytes memory contractName = stdJson.parseRaw(
            json,
            ".transactions[0].contractName"
        );
        address contractAddress = stdJson.readAddress(
            json,
            ".transactions[0].contractAddress"
        );
        bytes memory transactionHash = stdJson.parseRaw(
            json,
            ".receipts[0].transactionHash"
        );

        console.log(string(contractName));
        console.logAddress(contractAddress);
        console.logBytes(transactionHash);
    }

    // function bytesToAddress(
    //     bytes memory bys
    // ) private pure returns (address addr) {
    //     assembly {
    //         addr := mload(add(bys, 32))
    //     }
    // }
}