function stringToHex(str) {
    return str.split("").map(function(c) {
        return ("0" + c.charCodeAt(0).toString(16)).slice(-2);
    }).join("");
}

module.exports = async (taskArgs) => {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    let token = await ethers.getContractAt('MintableToken', taskArgs.token);
    let address = taskArgs.address;

    if (taskArgs.address === "") {
        address = deployer.address;
    } else {
        if (taskArgs.address.substr(0,2) != "0x") {
            address = "0x" + stringToHex(taskArgs.address);
        }
    }


    let value = await token.connect(deployer).balanceOf(address)


    console.log(`transfer out token ${token} to ${address} amount ${value} successful`);
}