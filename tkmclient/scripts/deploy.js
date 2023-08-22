// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

const  initializeData = require('./data');


async function main() {

  const LightNode = await hre.ethers.getContractFactory("LightNode");

  const lightNode = await LightNode.deploy();

  await lightNode.waitForDeployment();

  const lightNodeAddr =  await lightNode.getAddress();
  console.log("LightNode address is: ", lightNodeAddr);

  const LightNodeProxy = await hre.ethers.getContractFactory("LightNodeProxy");

  let height = initializeData.currentHeight;

  let comm = initializeData.currentComm;

  let nextComm = initializeData.nextComm;

  let data = lightNode.interface.encodeFunctionData("initialize", [height, comm, nextComm]);

  const lightNodeProxy = await LightNodeProxy.deploy(lightNode.getAddress(), data);

  await lightNodeProxy.waitForDeployment();

  const proxyAddr = await lightNodeProxy.getAddress();

  console.log("LightNodeProxy address is: ", proxyAddr)
  console.log("deploy success")

  let proxy = await hre.ethers.getContractAt('LightNode', proxyAddr);

  let owner = await proxy.getAdmin();

  let lastHeight = await proxy.getFunction("lastHeaderHeight").apply();

  console.log("LightNode owner is: ", owner);
  console.log("LightNode lastHeight is: ", lastHeight);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
