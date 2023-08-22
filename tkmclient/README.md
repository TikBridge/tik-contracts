# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
# get init data
npx run scripts/initializeData.js
npx hardhat node
npx hardhat run scripts/deploy.js

// depoy LightNode with LightNodeProxy to a named network using scripts/deploy.js 
// you should config an owner PRIVATE_KEY in .env first
npx hardhat run --network BscTest scripts/deploy.js

// upgrade LightNode on a named network using scripts/upgrade.js
// you should config the PROXY_ADDRESS of LightNodeProxy in .env before run the cmd
npx hardhat run --network BscTest scripts/upgrade.js
```
