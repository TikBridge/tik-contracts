# Cross-Chain Bridge

## Contracts
- [BSC light node](bscclient) - BSC light node deploy on relay chain, implement [ILightNode](clientmgr/contracts/interface/ILightNode.sol).
- [TKM light node](tkmclient) - TKM light node deploy on relay chain, implement [ILightNode](clientmgr/contracts/interface/ILightNode.sol).
- [RLY light node](rlyclient) - Relay chain light node deploy on asset chain(.e.g TKM, BSC).
- [Light node manager](clientmgr) - Manager deploy on relay chain to register implements of [ILightNode](clientmgr/contracts/interface/ILightNode.sol)(e.g. BSC light node, TKM light node).
- [Service and relay](relaysvc) - Cross-chain service(MOS) on asset chain(.e.g TKM, BSC) and Relay service(MOS Relay) on relay chain.

## Deploy Contracts

- Make sure run `npx hardhat compile` success under directories [BSC light node](bscclient)、[TKM light node](tkmclient)、[RLY light node](rlyclient)、[Light node manager](clientmgr)、[Service and relay](relaysvc). 
- Make sure have the correct `.env` config file in  [BSC light node](bscclient)、[TKM light node](tkmclient)、[RLY light node](rlyclient)、[Light node manager](clientmgr)、[Service and relay](relaysvc).
- Make sure the network was correct configured in `hardhat.config.js(or hardhat.config.ts)` under  [BSC light node](bscclient)、[TKM light node](tkmclient)、[RLY light node](rlyclient)、[Light node manager](clientmgr)、[Service and relay](relaysvc).

### Deploy relay light node on asset chains

#### 1. Deploy relay light node on BSC chain and TKM chain, run the following cmd under [RLY light node](rlyclient)

    npx hardhat run scripts/initializeData.js

    npx hardhat run scripts/deploy.js --network <BSC network name>

    npx hardhat run scripts/deploy.js --network <TKM network name>


### Deploy light node on relay chain

#### 2. Deploy BSC light node on relay chain, run the following cmd under [BSC light node](bscclient)

    npx hardhat run scripts/deploy.ts --network <relay network name>

#### 3. Deploy TKM light node on relay chain, run the following cmd under [TKM light node](tkmclient)

    npx hardhat run scripts/initializeData.js

    npx hardhat run scripts/deploy.js --network <relay network name>

#### 4. Deploy light node manager on relay chain, run the following cmd under [Light node manager](clientmgr)

    npx hardhat deploy --tags LightClientManager --network <relay network name>

#### 5. Register BSC light node in manager, run the following cmd under [Light node manager](clientmgr)

    npx hardhat clientRegister --chain <BSC chainid> --contract <BSC lightnode address> --network <relay network name>

#### 6. Register TKM light node in manager, run the following cmd under [Light node manager](clientmgr)

    npx hardhat clientRegister --chain <TKM chainid> --contract <TKM lightnode address> --network <relay network name>


### Deploy relay service on relay chain

#### 7. Deploy relay service(MOS Relay) on relay chain, run the following cmd under [Service and relay](relaysvc)

    npx hardhat relayDeploy --lightnode <lightnode manager address from step 4> --network <relay network name>

#### 8. Deploy tokenRegister on relay chain, run the following cmd under [Service and relay](relaysvc)

    npx hardhat deploy --tags TokenRegisterV2 --network <relay network name>

#### 9. Relay service(MOS Relay) bind tokenRegister, run the following cmd under [Service and relay](relaysvc)

    npx hardhat relayInit  --tokenmanager <tokenregister address from step 8> --network <relay network name>


### Deploy MOS on asset chains and register to relay chain

Use the following steps(10-13) to deploy MOS and configure MOS relay.

#### 10. Deploy cross-chain service(MOS) on BSC chain and TKM chain, run the following cmd under [Service and relay](relaysvc)

    npx hardhat mosDeploy --lightnode <relay lightnode proxy address on BSC chain from step 1> --network <BSC network name>

    npx hardhat mosDeploy --lightnode <relay lightnode proxy address on TKM chain from step 1> --network <TKM network name>

#### 11. Cross-chain service(MOS) bind relay chain relay service(MOS Relay) address and relay chain id, run the following cmd under [Service and relay](relaysvc)

    npx hardhat mosSetRelay --relay <relay chain relay service(MOS Relay) address from step 7> --chain <relay chainid> --network <BSC network name>

    npx hardhat mosSetRelay --relay <relay chain relay service(MOS Relay) address from step 7> --chain <relay chainid> --network <TKM network name>

#### 12. Relay chain relay service(MOS Relay) register asset chain cross-chain service(MOS) and VM type, run the following cmd under [Service and relay](relaysvc)

    npx hardhat relayRegisterChain --address <BSC cross-chain service(MOS) address from step 10> --chain <BSC chainid> --type 1 --network <relay network name>

    npx hardhat relayRegisterChain --address <TKM cross-chain service(MOS) address from step 10> --chain <TKM chainid> --type 1 --network <relay network name>

#### 13. Cross-chain service(MOS) register VM type of target asset chains, type 1 means EVM, run the following cmd under [Service and relay](relaysvc)

    npx hardhat mosRegisterChain --chains <TKM(or Relay) chainid seperate with ','> --type 1 --network <BSC network name>

    npx hardhat mosRegisterChain --chains <BSC(or Relay) chainid seperate with ','> --type 1 --network <TKM network name>



## Configure cross-chain token

To make an ERC20 token can transfer on bridge, do following steps(14-27) to register a cross-chain token pair at both ends of a bridge.

### Register cross chain ERC20 token on transferOut chain

Here the transferOut chain is BSC, and you can change to your transferOut chain.

#### 14. Deploy an ERC20 token on BSC(If you had one, ignore this step and do next steps), run the following cmd under [Service and relay](relaysvc)

    npx hardhat tokenDeploy --name <token name> --symbol <token symbol> --balance <value> --network <BSC network name>

#### 15. BSC ERC20 token bind a target TKM chain that registered in BSC cross-chain service(MOS), run the following cmd under [Service and relay](relaysvc)

    npx hardhat mosRegisterToken --token <BSC ERC20 token address> --chains <target chainid seperate with ','> --enable true --network <BSC network name>

#### 16. Register BSC ERC20 token mintable and set cross-chain service(MOS) as MINTER_ROLE, run the following cmd under [Service and relay](relaysvc)

If you don't want the ERC20 token mintable, ignore this step.  
Otherwise, make sure the token implement [IMAPToken](relaysvc/contracts/interface/IMAPToken.sol),  
and do the following two things:  
1. Use mosSetMintableToken cmd to register token mintable;
2. Use tokenGrant cmd to register MOS as MINTER_ROLE.

````
   npx hardhat mosSetMintableToken --token <BSC ERC20 token address> --mintable <true/false> --network <BSC network name>

   npx hardhat tokenGrant --token <BSC ERC20 token address> --minter < mos | address > --network <BSC network name>
````

### Register target ERC20 token on transferIn chain

Here the transferIn chain is TKM chain, and you can change to your target chain.

#### 17. Deploy an ERC20 token on TKM(If you had one, ignore this step and do next steps), run the following cmd under [Service and relay](relaysvc)

    npx hardhat tokenDeploy --name <token name> --symbol <token symbol> --network <TKM network name>

#### 18. TKM ERC20 token bind a BSC target chain that registered in TKM cross-chain service(MOS), run the following cmd under [Service and relay](relaysvc)

This step registers the target token can transferOut back to source chain.  
If you don't want the target token transfer back to source chain, ignore this step.

````
    npx hardhat mosRegisterToken --token <TKM ERC20 token address> --chains <source chainid seperate with ','> --enable true --network <TKM network name>
````

#### 19. Register TKM ERC20 token mintable and register cross-chain service(MOS) as MINTER_ROLE, run the following cmd under [Service and relay](relaysvc)

If you don't want the target chain ERC20 token mintable, ignore this step.  
Otherwise, make sure the token implement [IMAPToken](relaysvc/contracts/interface/IMAPToken.sol),  
and do the following two things:
1. Use mosSetMintableToken cmd to register token mintable;
2. Use tokenGrant cmd register MOS as MINTER_ROLE.

````
    npx hardhat mosSetMintableToken --token <TKM ERC20 token address> --mintable <true/false> --network <TKM network name>

    npx hardhat tokenGrant --token <TKM ERC20 token address> --minter mos --network <TKM network name>
````

### Register cross chain token pair in relay chain relay service(MOS Relay)

#### 20. Deploy a mapping ERC20 token on relay chain, run the following cmd under [Service and relay](relaysvc)

    npx hardhat tokenDeploy --name <token name> --symbol <token symbol> --network <relay network name>

#### 21. Mapping ERC20 token register relay service(MOS Relay) as MINTER_ROLE on relay chain, run the following cmd under [Service and relay](relaysvc)

    npx hardhat tokenGrant --token <mapping ERC20 token address> --minter mos --network <relay network name>

#### 22. Deploy vault token on transferIn chain, run the following cmd under [Service and relay](relaysvc)

    npx hardhat vaultDeploy --token <mapping ERC20 token address> --name <vault token name> --symbol <vault token symbol> --network <relay network name>

#### 23. Vault token add relay service(MOS Relay) as a role of manager, run the following cmd under [Service and relay](relaysvc)

    npx hardhat vaultAddManager --vault <vault token address> --manager < relay | address > --network <relay network name>

#### 24. Relay service(MOS Relay) register token, run the following cmd under [Service and relay](relaysvc)

    npx hardhat relayRegisterToken --token <mapping ERC20 token address> --vault <vault token address> --mintable true --network <relay network name>

#### 25. Bind TKM token and BSC token, run the following cmd under [Service and relay](relaysvc)

    npx hardhat relayMapToken --token <mapping ERC20 token address> --chain <BSC chainid> --chaintoken <BSC ERC20 token address> --decimals 18 --network <relay network name>

    npx hardhat relayMapToken --token <mapping ERC20 token address> --chain <TKM chainid> --chaintoken <TKM ERC20 token address> --decimals 18 --network <relay network name>

#### 26. Set token fee of transferOut to target chain, run the following cmd under [Service and relay](relaysvc)

    npx hardhat relaySetTokenFee --token <mapping ERC20 token address> --chain <BSC chainid>  --min <minimum fee value> --max <maximum fee value> --rate <fee rate 0-1000000> --network <relay network name>

    npx hardhat relaySetTokenFee --token <mapping ERC20 token address> --chain <TKM chainid>  --min <minimum fee value> --max <maximum fee value> --rate <fee rate 0-1000000> --network <relay network name>

#### 27. Relay service(MOS Relay) sets fee distribute rate

    npx hardhat managerSetDistributeRate --type <0 to the token vault, 1 to specified receiver, 2 to protocol> --address <fee receiver address> --rate <rate 0-1000000, uni 0.000001> --network <relay network name>


### Approve and transfer out token on from chain

#### 28. ERC20 token on from chain approve MOS(MOS Relay) transferFrom/burnFrom amount, run the following cmd under [Service and relay](relaysvc)

````
   npx hardhat tokenApprove --address <mos | mos address on from chain> --amount <value> --token <ERC20 token address on from chain> --network <from chain network name> 
````

#### 29. Transfer out ERC20 token on from chain to target chain, run the following cmd under [Service and relay](relaysvc)  

```
    npx hardhat transferOutToken --mos <mos address or mos relay address on from chain> --token <ERC20 token address on from chain> --address <receiver address> --value <transfer value> --chain <target chain id> --network <from chain network name>
```
--address is an optional parameter. If it is not filled in, it will be the default caller's address.

    