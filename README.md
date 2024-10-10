

## Usage

Follow the steps below to test, deploy and upgrade the contracts

### Set Private Key

```shell
cast wallet import defaultKey --interactive
```

### View Public Key for the Private Key stored as "defaultKey"

use this in the .env as DEPLOYER_PUBLIC_KEY
```shell
cast wallet address --account defaultKey
```

### Set Etherscan API Key and RPC keys

populate values in .env.example save as .env 


### Test
locally
```shell
forge clean && forge test 
```
on Holesky
```shell
forge clean && forge test --fork-url holesky
```

## to deploy on forked mainnet:
fill out .env file CONTRACT_OWNER will be contract admin, set DEPLOYER_PUBLIC_KEY to 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (first Anvil account)
```shell
anvil -f mainnet
```
in a seperate window
```shell
forge clean && forge script script/deployToken.s.sol:DeployImplementation --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast -vvvv -g 200
```

```shell
cast create2 --starts-with AAAAAAA --case-sensitive --deployer 0x4e59b44847b379578588920cA78FbF26c0B4956C --init-code-hash <get this from previous deployment logs>
```

UPDATE .env WITH SALT FOR VANITY ADDRESS (Leave 0x0...0 if not using)
```shell
forge clean && forge script script/deployToken.s.sol:DeployProxyWithCreate2 --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast -vvvv -g 200
```
set APEth address in the early deposit contract
```shell
cast rpc anvil_impersonateAccount 0xC8B3BA310daC330E1Fd394021B3cA5747bb3B3E7
cast send 0x9B4F8873090FCB3b9d5e562aFCdcbDf30228F301 \
--from 0xC8B3BA310daC330E1Fd394021B3cA5747bb3B3E7 \
"updateAPEth(address)" <APEth contract (proxy) address> --unlocked
```
bulk mint for first address
```shell
cast send 0x9B4F8873090FCB3b9d5e562aFCdcbDf30228F301 \
--from 0xC8B3BA310daC330E1Fd394021B3cA5747bb3B3E7 \
"mintAPEthBulk(address[])" [0xf379Eb32eDaD17B9a92a03e43aFbA84FB8095eF8] --unlocked
```
check APEth balance of first depositer
```shell
cast call <APEth contract (proxy) address> \
"balanceOf(address)(uint)" 0xf379Eb32eDaD17B9a92a03e43aFbA84FB8095eF8
```


### Deploy
Deploy in 2 parts (3 if you want a vanity address), following the steps below. 

(Note: if you encounter 
Error: 
Failed to get EIP-1559 fees
add --legacy
)

```shell
forge clean && forge script script/deployToken.s.sol:DeployImplementation --rpc-url mainnet --account defaultKey --broadcast --etherscan-api-key mainnet --verify -vvvv -g 200
```

```shell
cast create2 --starts-with AAAAAAA --case-sensitive --deployer 0x4e59b44847b379578588920cA78FbF26c0B4956C --init-code-hash <get this from previous deployment logs>
```

UPDATE .env WITH SALT FOR VANITY ADDRESS (Leave 0x0...0 if not using)
```shell
forge clean && forge script script/deployToken.s.sol:DeployProxyWithCreate2 --rpc-url mainnet --account defaultKey --broadcast --etherscan-api-key mainnet --verify -vvvv -g 200
```

### Upgrade

```shell
forge clean && forge script script/upgradeProxy.s.sol:UpgradeProxy --rpc-url holesky --account defaultKey --broadcast --etherscan-api-key holesky --verify
```

### Transfer Ownership
NOTE: this transfers both the storage guardian and the token contract owner to the CONTRACT_OWNER from the .env file. The guardianship must be accepted in another transaction by the address recieveing it.

```shell
forge clean && forge script script/transferOwnership.s.sol:transferOwnership --rpc-url holesky --account defaultKey --broadcast
```

### Format

```shell
forge fmt
```

