
module.exports = async (taskArgs,hre) => {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    let proxy = await hre.deployments.get("MAPOmnichainServiceProxyV2")

    console.log("relayservice address", proxy.address);

    let mos = await ethers.getContractAt('MAPOmnichainServiceRelayV2', proxy.address);

    await (await mos.connect(deployer).setLightClientManager(taskArgs.manager)).wait();

    console.log("set client manager:", taskArgs.manager);
}
