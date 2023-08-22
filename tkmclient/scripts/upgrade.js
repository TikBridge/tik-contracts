// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

const proxyAddr = process.env.PROXY_ADDRESS

async function main() {

  const LightNode = await hre.ethers.getContractFactory("LightNode");

  const lightNode = await LightNode.deploy();

  await lightNode.waitForDeployment();

  const newAddr = await lightNode.getAddress();

  console.log("New Light Node address: ", newAddr);

  let proxy = await hre.ethers.getContractAt('LightNode', proxyAddr);

  console.log('implementation before: ', await proxy.getImplementation());

  await (await proxy.upgradeTo(newAddr)).wait();

  console.log('implementation after: ', await proxy.getImplementation());

  let owner = await proxy.getAdmin();
  console.log("LightNode owner is: ", owner);

  let lastHeight = await proxy.getFunction("lastHeaderHeight").apply();
  console.log("LightNode lastHeight is: ", lastHeight);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
