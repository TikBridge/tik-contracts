
require('hardhat-gas-reporter')
require('hardhat-spdx-license-identifier')
require('hardhat-deploy')
require('hardhat-abi-exporter')
require('@nomiclabs/hardhat-ethers')
require('dotenv/config')
require('@nomiclabs/hardhat-etherscan')
require('@nomiclabs/hardhat-waffle')
require('solidity-coverage')
require('./tasks')

const { PRIVATE_KEY } = process.env;
let accounts = [];
accounts.push(PRIVATE_KEY);


module.exports = {
  defaultNetwork: 'hardhat',
  abiExporter: {
    path: './abi',
    clear: true,
    flat: true,
    only: [':MAPOmnichainService', 'Token', ':Light', ':Wrapped'],
    runOnCompile: true,
  },
  networks: {
    hardhat: {
      forking: {
        enabled: false,
        url: `https://data-seed-prebsc-1-s1.binance.org:8545`
      },
      allowUnlimitedContractSize: true,
      live: true,
      saveDeployments: false,
      tags: ['local'],
      timeout: 2000000,
      chainId:212
    },
    RelayTest: {
      chainId: 50001,
      url:"http://127.0.0.1:32021",
      accounts: accounts
    },
    TkmTest: {
      chainId: 50001,
      url:"http://127.0.0.1:32021",
      accounts: accounts
    },
    Bsc: {
      url: `https://bsc-dataseed1.binance.org/`,
      chainId : 56,
      accounts: accounts
    },
    BscTest: {
      url: `https://bsc-testnet.publicnode.com`,
      chainId : 97,
      accounts: accounts
    }
  },
  solidity: {
    compilers: [
      {
        version: '0.8.7',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: '0.4.22',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ]
  },
  spdxLicenseIdentifier: {
    overwrite: true,
    runOnCompile: false
  },
  mocha: {
    timeout: 2000000
  }
}
