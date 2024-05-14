## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Set Private Key

```shell
$ cast wallet import defaultKey --interactive
```

### View Public Key for the Private Key stored as "defaultKey"

use this in the .env as sender
```shell
$ cast wallet address --account defaultKey
```

### Set Etherscan API Key and RPC keys

populate values in .env.expample save as .env

### Build

```shell
$ forge build
```

### Test
locally
```shell
$ forge clean && forge test --ffi
```
on Holesky
```shell
$ forge clean && forge test --ffi --fork-url holesky
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy
Deploy in 2 parts:

```shell
$ forge clean && forge script script/deployStorage.s.sol:DeployStorageContract --rpc-url holesky --account defaultKey --broadcast --etherscan-api-key holesky --verify
```
for vanity address (deployer address here is the Create2 contract):
```shell
$ cast create2 --starts-with AAAAAAA --case-sensitive --deployer 0x4e59b44847b379578588920cA78FbF26c0B4956C --init-code-hash <get this from previous deployment logs>
```

UPDATE DeployToken.s.sol WITH CONTRACT VALUES FROM THE PREVIOUSLY DEPLOYED CONTRACTS
```shell
$ forge clean && forge script script/deployToken.s.sol:DeployProxy --rpc-url holesky --account defaultKey --broadcast --etherscan-api-key holesky --verify
```

### Upgrade
NOTE: check the implementation and the proxy address in script/upGradeProxy

```shell
$ forge clean && forge script script/upgradeProxy.s.sol:UpgradeProxy --rpc-url holesky --account defaultKey --broadcast --etherscan-api-key holesky --verify --ffi
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
