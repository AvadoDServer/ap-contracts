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

```shell
$ cast wallet address --account defaultKey
```

### Set Etherscan API Key

```shell
$ export ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test --ffi --fork-url https://ethereum-holesky.publicnode.com
```
if errors try
```shell
$ forge clean && forge test --ffi --fork-url https://ethereum-holesky.publicnode.com
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
$ forge script script/deployStorage.s.sol:DeployStorageContract --rpc-url holesky --account defaultKey --sender <public key of defaultKey> --broadcast --etherscan-api-key $ETHERSCAN_API_KEY --verify
```
```shell
$ forge script script/deployToken.s.sol:DeployTokenImplementation --rpc-url holesky --account defaultKey --sender <public key of defaultKey> --broadcast --etherscan-api-key $ETHERSCAN_API_KEY --verify
```

### Upgrade
NOTE: currently set to upgrade to APETHV2 - change script/upgradeProxy.sol to change this

```shell
$ forge script script/upgradeProxy.s.sol:UpgradeProxy --rpc-url holesky --account defaultKey --sender <public key of defaultKey> --broadcast --etherscan-api-key $ETHERSCAN_API_KEY --verify --ffi
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
