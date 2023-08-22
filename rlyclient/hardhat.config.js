require("@nomicfoundation/hardhat-toolbox");
require("hardhat-abi-exporter");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */

const PK = process.env.PRIVATE_KEY

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
    only: [':LightNode$'],
    runOnCompile: true,
  },
  networks: {
    Bsc: {
      url: `https://bsc-dataseed1.binance.org/`,
      chainId : 56,
      accounts: [PK],
    },
    BscTest: {
      url: `https://bsc-testnet.publicnode.com`,
      chainId : 97,
      accounts: [PK],
      gasPrice: 11 * 1000000000
    },
    Tkm: {
      chainId: 50001,
      url:"http://127.0.0.1:32021",
      accounts: [PK],
    },
    TkmTest: {
      chainId: 50001,
      url:"http://127.0.0.1:32021",
      accounts: [PK],
    }
  },
};
