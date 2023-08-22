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
    RelayTest: {
      url: `http://127.0.0.1:32021`,
      chainId : 50001,
      accounts: [PK],
      gasPrice: 11 * 1000000000
    }
  },
};
