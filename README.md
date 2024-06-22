

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
locally
```shell
forge clean && forge test 
```
on Holesky
```shell
forge clean && forge test --fork-url holesky
```

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

