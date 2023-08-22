import { HardhatUserConfig } from "hardhat/config";
import * as dotenv from "dotenv";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import 'hardhat-deploy';
import "hardhat-abi-exporter";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

const config: HardhatUserConfig ={
  solidity: {
		compilers: [
			{ version: "0.8.7", settings: { optimizer: { enabled: true, runs: 200 } } },
		],
  },
  namedAccounts: {
    deployer: 0,
  },
  networks: {
    RelayTest: {
      chainId: 50001,
      url:"http://127.0.0.1:32021",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  abiExporter:{
    path: './abi',
    clear: true,
    flat: true,
    only: [':LightNode$'],
    runOnCompile: true,
  }
};

export default config;




