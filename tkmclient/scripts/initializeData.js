let fs = require("fs");
require("hardhat");
require("dotenv").config();
let request = require('request');

let uri = process.env.TKM_ETH_API_MAIN;
function httpRequest(url, requestData){
    return new Promise((resolve)=>{

        let option ={
            url: url.toString(),
            method: "POST",
            json: true,
            headers: {
                "content-type": "application/json",
            },
            body: requestData
        }
        request(option, function(error, response, body) {
            resolve(body)
        });
    });

}

async function getdata() {
    let requestData = {
        "jsonrpc": "2.0",
        "id": 2192787296,
        "method": "eth_chainLatestComm",
        "params": []

    }
    let response = {
        "currentComm":[],
        "nextComm": [],
        "currentHeight": 0
    }
    let data = await httpRequest(uri, requestData)
    let result = data["result"]
    let h = parseInt(result["height"])
    response["currentComm"] = response["currentComm"].concat(result["currentComm"])
    response["currentHeight"] = h
    if (h % 1000 >= 940) {
        response["nextComm"] = response["nextComm"].concat(result["nextComm"])
    }
    return response
}

async function main() {
    data = await getdata()
    console.log(data)
    let datar = "let initData =" + JSON.stringify(data) + "\n" + "module.exports = initData"

    fs.writeFileSync('./scripts/data.js', datar);

    console.log(`write in epoch  ${data.epoch} success`)
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
