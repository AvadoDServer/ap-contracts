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
$ export PRIVATE_KEY=YOUR_PRIVATE_KEY
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
$ forge test --ffi
```
if errors try
```shell
$ forge clean && forge build && forge test --ffi
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

```shell
$ forge script script/deployToken.s.sol:DeployTokenImplementation --rpc-url holesky --private-key $PRIVATE_KEY --broadcast --etherscan-api-key $ETHERSCAN_API_KEY --verify
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
