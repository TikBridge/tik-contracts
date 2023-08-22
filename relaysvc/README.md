# MAP Omnichain Service


## Setup Instructions
Edit the .env-example.txt file and save it as .env

The following node and npm versions are required
````
$ node -v
v14.17.1
$ npm -v
6.14.13
````

Configuration file description

PRIVATE_KEY User-deployed private key


## Instruction
MAPOmnichainServiceV2 contract is suitable for evm-compatible chains and implements cross-chain logic

MAPOmnichainServiceRelayV2 contract implements cross-chain logic and basic cross-chain control based on MAP Relay Chain

TokenRegisterV2 contract is used to control the mapping of cross-chain tokens

## Build

```shell
git clone https://github.com/TikBridge/tik-contracts.git
cd tik-contracts/relaysvc/
npm install
```

## Test

```shell
npx hardhat test
```



## Deploy

### MOS Relay
The following steps help to deploy MOS relay contracts on relay chain

1. Deploy Fee Center and Token Register
```
npx hardhat deploy --tags TokenRegister --network <network>
````
2. Deploy MOS Relay

```
npx hardhat relayDeploy --lightnode <lightNodeManager address> --network <network>
````

* `lightNodeManager address` is the light client mananger address deployed on relay chain. See [here](../clientmgr/README.md) for more information.

3. Init MOS Relay
```
npx hardhat relayInit  --tokenmanager <token register address> --network <network>
````


4.  sets fee distribution
````
npx hardhat managerSetDistributeRate --type <0 to the token vault, 1 to specified receiver> --address <fee receiver address> --rate <rate 0-1000000, uni 0.000001> --network <network>
````

### MOS on EVM Chains

1. Deploy
```
npx hardhat mosDeploy --lightnode <lightnode address> --network <network>
```

2. Set MOS Relay Address
   The following command on the EVM compatible chain
```
npx hardhat mosSetRelay --relay <Relay address> --chain <map chainId> --network <network>
```

3. Register
   The following command applies to the cross-chain contract configuration of relay chain
```
npx hardhat relayRegisterChain --address <MAPOmnichainService address> --chain <chain id> --network <network>
```

## Configure

### Deploy Token

1. Deploy a mintable Token
   If want to transfer token through MOS, the token must exist on target chain. Please depoly the mapped mintable token on target chain if it does NOT exist.
````
npx hardhat tokenDeploy --name <token name > --symbol <token symbol> --network <network>
````

2. Grant Mint Role to relay or mos contract
````
npx hardhat tokenGrant --token <token address > --minter <adress/mos> --network <network>
````

### Register Token


1. Relay Chain deploy vault token
Every token has a vault token. The vault token will distribute to the users that provide cross-chain liquidity.
The mos relay contract is manager of all vault tokens.

````
npx hardhat vaultDeploy --token <relaychain token address> --name <vault token name> --symbol <vault token symbol> --network <network>

npx hardhat vaultAddManager --vault <vault token address> --manager <manager address> --network <network>
````

2. Register token
````
npx hardhat relayRegisterToken --token <relaychain mapping token address> --vault <vault token address> --mintable <true/false> --network <network>
````

3. Set fee ratio to relay chain
```
npx hardhat relaySetTokenFee --token <token address> --chain <relay chain id>  --min <minimum fee value> --max <maximum fee value> --rate <fee rate 0-1000000> --network <network>
```

### Add Cross-chain Token

1. Relay Chain Bind the token mapping relationship between the two chains that requires cross-chain
````
npx hardhat relayMapToken --token <relay chain token address> --chain <cross-chain id> --chaintoken <cross-chain token> --decimals <cross-chain token decimals> --network <network>
````

2. Relay Chain sets the token cross-chain fee ratio
````
npx hardhat relaySetTokenFee --token <token address> --chain <chain id>  --min <minimum fee value> --max <maximum fee value> --rate <fee rate 0-1000000> --network <network>
````

3. Asset chains set token mintable
   
````
npx hardhat mosSetMintableToken --token <token address> --mintable <true/false> --network <network>
````

**NOTE:** If set the token mintable, the token must grant the minter role to mos contract.

4. Asset chains set bridge token

````
npx hardhat mosRegisterToken --token <token address> --chains < chain ids,separated by ',' > --network <network>
````



## Upgrade

When upgrade the mos contract through the following commands.

Please execute the following command on the EVM compatible chain

```
npx hardhat deploy --tags MAPOmnichainServiceV2Up --network <network>
```

Please execute the following command on relay chain mainnet or Makalu testnet
```
npx hardhat deploy --tags MAPOmnichainServiceRelayV2Up --network <network>
```

## Token cross-chain transfer deposit

1. token transfer
```
npx hardhat transferOutToken --mos <mos or relay address> --token <token address> --address <receiver address> --value <transfer value> --chain <chain id> --network <network>
```

--address is an optional parameter. If it is not filled in, it will be the default caller's address.


## List token mapped chain

1. relay chain
```
npx hardhat relayList --relay <relay address> --token <token address> --network <network>
```

2. asset chains
```
npx hardhat mosList --mos <relay address> --token <token address> --network <network>
```