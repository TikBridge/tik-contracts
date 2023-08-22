require('hardhat-gas-reporter');
require('hardhat-spdx-license-identifier');
require('hardhat-deploy');
require('hardhat-deploy-ethers');
require('hardhat-abi-exporter');
require('dotenv/config');
require('@nomiclabs/hardhat-etherscan');
require('hardhat-contract-sizer');
require("hardhat-log-remover");
require("./tasks")


const PRIVATE_KEY = process.env.PRIVATE_KEY;


let accounts = [];

accounts.push(PRIVATE_KEY);


module.exports = {
  solidity: {
    version: "0.8.7",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  abiExporter: {
    path: './abi',
    clear: true,
    flat: true,
    only: [':LightClientManager$'],
    runOnCompile: true,
  },
  networks: {
    RelayTest: {
      chainId: 50001,
      url:"http://127.0.0.1:32021",
      accounts: accounts
    }
  },
  spdxLicenseIdentifier: {
    overwrite: true,
    runOnCompile: true,
  },
  mocha: {
    timeout: 2000000,
  },
}
