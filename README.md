

## Usage

Follow the steps below to test, deploy and upgrade the contracts

### Set Private Key

```shell
cast wallet import defaultKey --interactive
```

### View Public Key for the Private Key stored as "defaultKey"

use this in the .env as sender
```shell
cast wallet address --account defaultKey
```

### Set Etherscan API Key and RPC keys

populate values in .env.example save as .env 


### Test

on Mainnet
```shell
forge clean && forge test -f mainnet
```

### To Run on Anvil

We are using chainID 9753 to avoid accidental replays on mainnet
Copy the input values from mainnet to our new chain-ID

```shell
cp -Rp ./script/input/1 ./script/input/9753
```


```shell
anvil -f mainnet --hardfork shanghai --chain-id 9753
```

Then in another terminal fund the owner account with some ETH to do the upgrades

```shell
cast send --rpc-url http://127.0.0.1:8545 --legacy --unlocked --from 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --value 1ether 0x42B3B0C3741696d8fBb4E46f0dA16e676133Fc84
```

Then impersonate this account

```shell
cast rpc anvil_impersonateAccount 0x42B3B0C3741696d8fBb4E46f0dA16e676133Fc84
```

And run the deploy script as this account

```shell
forge clean && forge script script/Deploy.s.sol:Deploy --sender 0x42B3B0C3741696d8fBb4E46f0dA16e676133Fc84 --broadcast -vvv --unlocked --rpc-url http://127.0.0.1:8545
```

To interact through the wallet dapp using Metamask, add a custom network with these settings:

- network name: "anvil"
- default RPC URL: http://localhost:8545
- chain ID : 9753
- currency symbol: anvil-eth

And you can now use the dapp with the settings


### Deploy
Deploy in 2 parts (3 if you want a vanity address), following the steps below. 

(Note: if you encounter 
Error: 
Failed to get EIP-1559 fees
add --legacy
)

```shell
forge clean && forge script script/deployStorage.s.sol:DeployStorageContract --rpc-url holesky --account defaultKey --broadcast --etherscan-api-key holesky --verify
```
for vanity address (deployer address here is the Create2 contract, modify --starts-with and --case-sensitive as required):
```shell
cast create2 --starts-with AAAAAAA --case-sensitive --deployer 0x4e59b44847b379578588920cA78FbF26c0B4956C --init-code-hash <get this from previous deployment logs>
```

UPDATE .env WITH SALT FOR VANITY ADDRESS (Leave 0x0...0 if not using)
```shell
forge clean && forge script script/deployToken.s.sol:DeployProxy --rpc-url holesky --account defaultKey --broadcast --etherscan-api-key holesky --verify
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

