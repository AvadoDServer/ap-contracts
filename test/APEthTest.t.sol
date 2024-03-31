// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/APETH.sol";
import "../src/APETHV2.sol";
import "../src/APEthStorage.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { Create2 } from "@openzeppelin-contracts/utils/Create2.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "@eigenlayer-contracts/interfaces/IEigenPodManager.sol";

contract APETHTest is Test {
    APETH APEth;
    APETH implementation;
    APEthStorage storageContract;
    ERC1967Proxy proxy;
    address owner;
    address newOwner;
    // Define Deposit Contract TODO: should check which chain we are deployig to to use correct address?
    address depositContract = 0x4242424242424242424242424242424242424242; //holesky
    // depositContract = 0x00000000219ab540356cBB839Cbe05303d7705Fa; //mainnet
    address ssvNetwork = 0x38A4794cCEd47d3baf7370CcC43B560D3a1beEFA; //holesky
    // address public SSVNetwork = 0xDD9BC35aE942eF0cFa76930954a156B3fF30a4E1; //mainnet
    address eigenPodManager = 0x30770d7E3e71112d7A6b7259542D1f680a70e315; //holesky
    // address eigenPodManager = 0x91E677b07F7AF907ec9a428aafA9fc14a0d3A338; //mainnet
    address alice;
   
    //these are the create2 pre-deploy address calcs
    address apEthPreDeploy;
    address implementationAddressPreDeploy;
    address storageContractPreDeploy;

    bytes _pubKey = hex"aed26c6b7e0e2cc2efeae9c96611c3de6b982610e3be4bda9ac26fe8aea53276201b3e45dbc242bb24af7fb10fc12196";
    bytes _signature = hex"a0696aefce9cd401fab9641e66799bd7af8b338fabac11aa42e6a6036a4cb03e80364a17ba0aa97182077aa3ab9b3f5611f4e99d1e96baad569f34960425e13991c661ee957475c14e8dc1e77d3deb29f2fabca34c20332598cf43e4fd95ef5b";
    bytes32 _deposit_data_root = 0x0e88949943ac2da1b17b16e680a7d385f1e8598eb6ce434a6dcd992ef2bd4822;

    bytes _pubKey2 = hex"91bebd77cd834b056ff242331dfcd3baecf3b89fcba6d866860a7ace128fb204af9b892cc84dd2d4eb933f6f8d0499b1";
    bytes _signature2 = hex"b62e860ebdd5fa85e9a0c79fe8f9abcd4cdd58af4f05f0525a0c15ddb243946afac6a18528d2d226e75d957a9b7d5b99024d3976f1f2b7b482f86fcec9009a00ca03c7b253a7045280be2ab016b5e778805306299b5a370e6c63652010a3336a";
    bytes32 _deposit_data_root2 = 0xfdf0ad0bae5f3d8d4cd6f14323b00f535a82a6598699f1a088c2b114bae3e5a3;

    bytes _pubKey3 = hex"b6ee6088e5b1dca8a7013f702140ab1f4825d349b20f8c4ba8436af36814dfb3309c13d7423898f60c5e332655a54f17";
    bytes _signature3 = hex"9413c7e260ae520c4554eca2bb8fa646ea8661e907ad8cbe1dbf480ac5c8c5c8fc542af2fbc96bba57a07ed694c4a71506c4baf5333c31d4cf4cac3854083412496ac66d6cd9d0406e8fd955db0cc3fee6237970bb5a44044e706231a3cc562c";
    bytes32 _deposit_data_root3 = 0x2bd142f6d9de4e22badefcd5b350b78c93a8dd25552eb3a39b0381de1ec97c51;

    struct Salt {
        bytes32 storageContract;
        bytes32 implementation;
        bytes32 apEth;
    }

    Salt public salt = Salt({
        storageContract: 0x0000000000000000000000000000000000000000000000000000000000000000,
        implementation: 0x0000000000000000000000000000000000000000000000000000000000000000,
        apEth: 0x0000000000000000000000000000000000000000000000000000000000000000
    });


    // Set up the test environment before running tests
    function setUp() public {
        // Define the owner and alice addresses
        owner = vm.addr(1);
        alice = vm.addr(2);

        //calculate addresses TODO: WRITE CREATE2 SCRIPT TO CALC SALT TO ADD A BUNCH OF A's AT THE BEGINNING OF THE CONTRACTS
        //storage
        storageContractPreDeploy = Create2.computeAddress(
            salt.storageContract,
            keccak256(abi.encodePacked(type(APEthStorage).creationCode)),
            address(this)
        );
        console.log("storage contract pre deploy", storageContractPreDeploy);
        //implementation
        implementationAddressPreDeploy = Create2.computeAddress(
            salt.implementation,
            keccak256(abi.encodePacked(type(APETH).creationCode)),
            address(this)
        );
        console.log("implementation address pre deploy", implementationAddressPreDeploy);
        //wrap as contract to generate the initialization code
        APETH preImplementation = APETH(payable(implementationAddressPreDeploy));
        //apEth(technically the proxy)
        apEthPreDeploy = Create2.computeAddress(
            salt.apEth,
            keccak256(abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementationAddressPreDeploy, abi.encodeCall(preImplementation.initialize, (owner, address(storageContractPreDeploy)))))),
            address(this)
        );
        console.log("proxy address pre deploy", apEthPreDeploy);

        //Deploy storage contract
        if(storageContractPreDeploy.code.length == 0){ //TODO: can this compare for contract changes?
            storageContract = new  APEthStorage{salt: salt.storageContract}();
            console.log("storageContract deployed", address(storageContract));
        } else {
            storageContract = APEthStorage(storageContractPreDeploy);
            console.log("storageContract exists", storageContractPreDeploy);
        }
        console.log("guardian address", storageContract.getGuardian());
        console.log("should match address(this)", address(this));
        //load addresses into storage
        storageContract.setAddress(keccak256(abi.encodePacked("external.contract.address", "DepositContract")), depositContract);
        storageContract.setAddress(keccak256(abi.encodePacked("external.contract.address", "SSVNetwork")), ssvNetwork);
        storageContract.setAddress(keccak256(abi.encodePacked("external.contract.address", "EigenPodManager")), eigenPodManager);
        // Set as apEth in storage
        storageContract.setAPEth(apEthPreDeploy);        
        console.log("storage initialised");

        // Deploy the token implementation
        if(implementationAddressPreDeploy.code.length == 0) {
            implementation = new APETH{salt: salt.implementation}();
            console.log("impementation deloyed", address(implementation));
        } else {
            implementation = APETH(payable(implementationAddressPreDeploy));
            console.log("implementation exists", implementationAddressPreDeploy);
        }
       
        // Deploy the proxy and initialize the proxy
        if(apEthPreDeploy.code.length == 0) {
            proxy = new ERC1967Proxy{salt: salt.apEth}(address(implementation), abi.encodeCall(implementation.initialize, (owner, address(storageContract))));
            // Attach the APETH interface to the deployed proxy
            APEth = APETH(payable(address(proxy)));
            console.log("APEth deployed", (address(proxy)));
        } else {
            //TODO: THIS SHOULD HANDLE THE CASE FOR AN IMPLEMENTATION CHANGE (FOR DEPLOY SCRIPT, NOT FOR TEST)
            APEth = APETH(payable(apEthPreDeploy));
            console.log("APEth exists", apEthPreDeploy);
        }
        
        // Define a new owner address for upgrade tests
        newOwner = address(1);

        console.log("eigen Pod Address", storageContract.getAddress(keccak256(abi.encodePacked("external.contract.address", "EigenPod"))));
        
    }

    // Test the basic ERC20 functionality of the APETH contract
    function testERC20Functionality() public {
        // Impersonate the alice to call mint function
        hoax(alice);
        // Mint 1 eth of tokens and assert the balance
        APEth.mint{value: 1 ether}();
        assertEq(APEth.balanceOf(alice), 1 ether);
    }

    // Test the upgradeability of the APETH contract
    function testUpgradeability() public {
        //TODO: add assertation
        // Upgrade the proxy to a new version; APETHV2
        Upgrades.upgradeProxy(address(proxy), "APETHV2.sol:APETHV2", "", owner);
        emit log_address(address(APEth.apEthStorage()));
    }

    // Test staking (requires using a forked chain with a deposit contract to test.)
    function testStake() public {
        // Impersonate the alice to call mint function
        hoax(alice);
        // Mint 1 eth of tokens and assert the balance
        APEth.mint{value: 33 ether}();
        // Impersonate owner to call stake()
        assertEq(address(APEth).balance, 33 ether);
        vm.prank(owner);
        APEth.stake(
            _pubKey,
            _signature,
            _deposit_data_root
        );

        assertEq(address(APEth).balance, 1 ether);
    }

    // test the accounting. the price should change predictibly when the contract recieves rewards
    function testBasicAccounting() public {
        hoax(alice);
        // Mint 10 eth of tokens and assert the balance
        APEth.mint{value: 10 ether}();
        assertEq(APEth.balanceOf(alice), 10 ether);
        assertEq(address(APEth).balance, 10 ether);
        // Send eth to contract to increase balance
        hoax(owner);
        payable(address(APEth)).transfer(1 ether);
        assertEq(address(APEth).balance, 11 ether);
        //check eth per apeth
        uint256 ethPerAPEth = 11 ether / 10;
        assertEq(APEth.ethPerAPEth(), ethPerAPEth);
        hoax(vm.addr(3));
        // Mint 10 eth of tokens and assert the balance
        APEth.mint{value: 10 ether}();
        uint256 expected = 10 ether * 1 ether / ethPerAPEth;
        assertEq(APEth.balanceOf(vm.addr(3)), expected);
        assertEq(address(APEth).balance, 21 ether);
    }

    function testBasicAccountingWithStaking() public {
        hoax(alice);
        // Mint 50 eth of tokens and assert the balance
        APEth.mint{value: 50 ether}();
        assertEq(APEth.balanceOf(alice), 50 ether);
        assertEq(address(APEth).balance, 50 ether);
        // Send eth to contract to increase balance
        hoax(owner);
        payable(address(APEth)).transfer(1 ether);
        assertEq(address(APEth).balance, 51 ether);
        //check eth per apeth
        uint256 ethPerAPEth = 51 ether / 50;
        assertEq(APEth.ethPerAPEth(), ethPerAPEth);
        vm.prank(owner);
        APEth.stake(
            _pubKey,
            _signature,
            _deposit_data_root
        );
        assertEq(address(APEth).balance, 19 ether);
        assertEq(APEth.ethPerAPEth(), ethPerAPEth);
        hoax(vm.addr(3));
        // Mint 10 eth of tokens and assert the balance
        APEth.mint{value: 10 ether}();
        uint256 expected = 10 ether * 1 ether / ethPerAPEth;
        assertEq(APEth.balanceOf(vm.addr(3)), expected);
        assertEq(address(APEth).balance, 29 ether);
    }

    function testBasicAccountingWithStakingAndFuzzing(uint32 x, uint32 y, uint32 z) public {
        hoax(alice);
        // Mint x eth of tokens and assert the balance
        APEth.mint{value: x}();
        assertEq(APEth.balanceOf(alice), x);
        assertEq(address(APEth).balance, x);
        // Send eth to contract to increase balance
        vm.deal(owner, y);
        vm.prank(owner);
        payable(address(APEth)).transfer(y);
        uint256 balance = uint256(x) + uint256(y);
        assertEq(address(APEth).balance, balance);
        //check eth per apeth
        uint256 ethPerAPEth;
        if(x == 0) {
            ethPerAPEth =  1 ether;
        } else {
            ethPerAPEth = balance * 1 ether / uint256(x);
        }
        assertEq(APEth.ethPerAPEth(), ethPerAPEth);
        uint256 ethInValidators;
        if(balance >= 32 ether) {
            vm.prank(owner);
            APEth.stake(
                _pubKey,
                _signature,
                _deposit_data_root
            );
            ethInValidators += 32 ether;
        }
        if(balance >= 64 ether) {
            vm.prank(owner);
            APEth.stake(
                _pubKey2,
                _signature2,
                _deposit_data_root2
            );
            ethInValidators += 32 ether;
        }
        if(balance >= 96 ether) {
            vm.prank(owner);
            APEth.stake(
                _pubKey3,
                _signature3,
                _deposit_data_root3
            );
            ethInValidators += 32 ether;
        }
        uint256 newBalance = balance - ethInValidators;
        assertEq(address(APEth).balance, newBalance);
        assertEq(APEth.ethPerAPEth(), ethPerAPEth);
        hoax(vm.addr(3));
        // Mint z eth of tokens and assert the balance
        APEth.mint{value: z}();
        uint256 expected = uint256(z) * 1 ether / ethPerAPEth;
        assertEq(APEth.balanceOf(vm.addr(3)), expected);
        assertEq(address(APEth).balance, newBalance + z);
    }
}
