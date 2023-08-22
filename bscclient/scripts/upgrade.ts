import { ethers } from "hardhat";

const proxyAddr = process.env.PROXY_ADDRESS;


async function main() {

  let [wallet] = await ethers.getSigners();

  console.log("begin ...");

  const LightNode = await ethers.getContractFactory("LightNode");

  const lightNode = await LightNode.deploy();

  await lightNode.connect(wallet).deployed();

  console.log("new lightNode Implementation deployed on:", lightNode.address);

  // @ts-ignore
  let lightNodeProxy = await ethers.getContractAt("LightNode", proxyAddr);

  console.log('implementation before: ', await lightNodeProxy.getImplementation());

  await (await lightNodeProxy.upgradeTo(lightNode.address)).wait();

  console.log('implementation after: ', await lightNodeProxy.getImplementation());

  console.log("light node proxy address is: ", lightNodeProxy.address);

  let owner = await lightNodeProxy.getAdmin();

  console.log("New LightNode owner is: ", owner);


}



// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
