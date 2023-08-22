module.exports = async (taskArgs,hre) => {
    const {deploy} = hre.deployments
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    let token = await ethers.getContractAt('MintableToken', taskArgs.token);

    console.log("Mintable Token address:",token.address);

    let minter = taskArgs.minter;
    if (taskArgs.address === "mos") {
        let proxy = await ethers.getContract('MAPOmnichainServiceProxyV2');
        minter = proxy.address;
    }

    await token.approve(minter, taskArgs.amount)

    console.log("approve token ", token.address, " amount", taskArgs.amount)
}