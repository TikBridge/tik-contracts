# Light node management contracts

## Introduction

### Light client manager
The contract deployed on the Relay Chain is responsible for managing light clients, it helps:
- Register light client
- Verify cross chain proof
- Get light client verification range


## Compile

Build using the following commands:

```shell
git clone url
cd clientmgr
npm install
npx hardhat compile
```


## Test

```shell
npx hardhat test
```

## Deploy

```shell
npx hardhat deploy --tags LightClientManager --network <network>
```

## Upgrade

```shell
npx hardhat deploy --tags LightClientManagerUp --network <network>
```


## Useage

### Register a light client

cmd
```shell
npx hardhat clientRegister --chain <chain id for light client> --contract <contract for light client>  --network <network>
```

example
```shell
  npx hardhat LightClientRegister --chain 1 --contract "0x366db0D543b709434Cb91113270521e50fC2fe49" --network Map
```

