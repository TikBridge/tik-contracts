const { ethers } = require("hardhat");
const { expect } = require("chai");
const mosData = require('./mosData');
require("solidity-coverage");
const { BigNumber} = require("ethers");

describe("MAPOmnichainServiceV2 start test", function () {

    let owner;
    let addr1;
    let addr2;
    let addr3;
    let addr4;
    let addr5;
    let addr6;
    let addr7;
    let addr8;
    let addr9;

    let MOSS;
    let moss;

    let StandardToken;
    let standardToken;

    let UToken;
    let usdt;

    let Wrapped;
    let wrapped;

    let LightNode;
    let lightNode;


    let initData;

    let address2Bytes;

    let receiver = "0x2E784874ddB32cD7975D68565b509412A5B519F4";

    beforeEach(async function () {

        [addr6,owner, addr1, addr2, addr3, addr4, addr5,addr7,addr8,addr9,...addrs] = await ethers.getSigners();

    });

    it("constract deploy init", async function () {

        MOSS = await ethers.getContractFactory("MAPOmnichainServiceV2");
        moss = await MOSS.deploy();
        console.log("moss address:",moss.address);

        StandardToken = await ethers.getContractFactory("MintableToken");
        standardToken = await StandardToken.deploy("MapToken","MP", 18);
        console.log("StandardToken:",standardToken.address);

        UToken = await ethers.getContractFactory("MintableToken");
        usdt = await  UToken.deploy("U Toeken","USDT", 18);
        console.log("UToken:",usdt.address);

        Wrapped = await ethers.getContractFactory("Wrapped");
        wrapped = await Wrapped.deploy();
        console.log("Wrapped:",wrapped.address);

        LightNode = await ethers.getContractFactory("LightNode");
        lightNode = await  LightNode.deploy();

        let data  = await moss.initialize(wrapped.address,lightNode.address);

        initData = data.data;


    });

    it('UUPS test', async function () {
        const MapCrossChainServiceProxy = await ethers.getContractFactory("MAPOmnichainServiceProxyV2");
        let mossp = await MapCrossChainServiceProxy.deploy(moss.address,initData);
        await mossp.deployed()
        moss = MOSS.connect(addr6).attach(mossp.address);
    });

    it('relayservice set', async function () {

        await moss.addMintableToken([standardToken.address]);

        await moss.setRelayContract(212,mosData.mosRelay);

        await moss.registerToken(standardToken.address,34434,"true");
        await moss.registerToken(wrapped.address,34434,"true");

        await moss.registerToken(standardToken.address,212,"true");
        await moss.registerToken(wrapped.address,212,"true");

        await moss.registerToken(standardToken.address,1313161555,"true");
        await moss.registerToken(wrapped.address,1313161555,"true");

        await moss.registerChain(34434,1);
        await moss.registerChain(212,1);
        await moss.registerChain(1313161555,2);


        let mintRole = await standardToken.MINTER_ROLE();

        await standardToken.grantRole(mintRole,moss.address);

        await standardToken.mint(addr1.address,"100000000000000000000000000");

        expect(await standardToken.balanceOf(addr1.address)).to.equal("100000000000000000000000000");
    });

    it('transferOutToken test',async function () {
        //console.log(addr2.address);
        //address2Bytes = await moss._addressToBytes(addr2.address);
        address2Bytes = "0x90F79bf6EB2c4f870365E785982E1f101E93b906";
        //console.log(await moss.getLog("0xf89b94c74bc33a95a62d90672aefaf4ba784285903cf09f863a0ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3efa0000000000000000000000000f7161297cd97e55375eac123fb947fb98e3157a9a0000000000000000000000000b6c1b689291532d11172fb4c204bf13169ec0dcaa000000000000000000000000000000000000000000000000053444835ec580000f89b94c74bc33a95a62d90672aefaf4ba784285903cf09f863a08c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925a0000000000000000000000000f7161297cd97e55375eac123fb947fb98e3157a9a0000000000000000000000000b6c1b689291532d11172fb4c204bf13169ec0dcaa00000000000000000000000000000000000000000033b2e3ab750fabc4a400000f9019d94b6c1b689291532d11172fb4c204bf13169ec0dcaf863a0e23247b10e5cf2e2a6a13352598fae25c889731f3b5eff5fb52184e121b41d54a000000000000000000000000000000000000000000000000000000000000000d4a00000000000000000000000000000000000000000000000000000000000000061b901204540755195affef599882857557eab4f98fd82f23b2fae0d486172841f7e9c09000000000000000000000000c74bc33a95a62d90672aefaf4ba784285903cf0900000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000053444835ec5800000000000000000000000000000000000000000000000000000000000000000014f7161297cd97e55375eac123fb947fb98e3157a90000000000000000000000000000000000000000000000000000000000000000000000000000000000000014f7161297cd97e55375eac123fb947fb98e3157a9000000000000000000000000f89b94c74bc33a95a62d90672aefaf4ba784285903cf09f863a0ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3efa0000000000000000000000000b6c1b689291532d11172fb4c204bf13169ec0dcaa00000000000000000000000000000000000000000000000000000000000000feea0000000000000000000000000000000000000000000000000002386f26fc10000f9023d94b6c1b689291532d11172fb4c204bf13169ec0dcaf863a044ff77018688dad4b245e8ab97358ed57ed92269952ece7ffd321366ce078622a000000000000000000000000000000000000000000000000000000000000000d4a00000000000000000000000000000000000000000000000000000000000000061b901c04540755195affef599882857557eab4f98fd82f23b2fae0d486172841f7e9c0900000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000051e102bd8ece000000000000000000000000000000000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000014c74bc33a95a62d90672aefaf4ba784285903cf090000000000000000000000000000000000000000000000000000000000000000000000000000000000000014f7161297cd97e55375eac123fb947fb98e3157a90000000000000000000000000000000000000000000000000000000000000000000000000000000000000014f7161297cd97e55375eac123fb947fb98e3157a90000000000000000000000000000000000000000000000000000000000000000000000000000000000000014688f3ef5f728995a9dcb299daec849ca2e49dde1000000000000000000000000"))
        await standardToken.connect(addr1).approve(moss.address,"10000000000000000000000000000000000")

        //transferOutToken to "100000000000000000000000"
        await moss.connect(addr1).transferOutToken(standardToken.address,address2Bytes,"100000000000000000000000",34434);

        //MintableToken true totalSupply burn 100000000000000000000000
        expect(await standardToken.totalSupply()).to.equal(BigNumber.from("99900000000000000000000000"));

        expect(await standardToken.balanceOf(moss.address)).to.equal("0")
        await moss.removeMintableToken([standardToken.address]);

        expect(await moss.mintableTokens(standardToken.address)).to.equal(false);

        await moss.connect(addr1).transferOutToken(standardToken.address,address2Bytes,"900000000000000000000000",34434);
        //MintableToken false totalSupply no change
        expect(await standardToken.totalSupply()).to.equal(BigNumber.from("99900000000000000000000000"));
        //addr1 balance 99900000000000000000000000 subtract 900000000000000000000000
        expect(await standardToken.connect(addr1).balanceOf(addr1.address)).to.equal("99000000000000000000000000")

        expect(await standardToken.balanceOf(moss.address)).to.equal("900000000000000000000000");
    });

    it('map transferIn test ', async function () {
        await moss.addMintableToken([standardToken.address]);

        //standardToken transferIn 100000000000000000
        await moss.transferIn(212,mosData.map2ethStandardToken);

        //MintableToken true mint 100000000000000000
        expect(await standardToken.totalSupply()).to.equal("99900000100000000000000000");
        //900000000000000000000000
        expect(await standardToken.balanceOf(moss.address)).to.equal("900000000000000000000000");

        expect(await usdt.balanceOf(moss.address)).to.equal("0");

        expect(await usdt.balanceOf(moss.address)).to.equal("0");

        // await moss.transferIn(212,mosData.map2ethMapToken0);
        //
        // expect(await standardToken.totalSupply()).to.equal("99900000100000000000000000");
        // expect(await usdt.balanceOf(moss.address)).to.equal("0");

        await wrapped.deposit({value:"300000000000000000"});
        await wrapped.transfer(moss.address,"300000000000000000");

        //wtoken transferIn 300000000000000000
        await moss.transferIn(212,mosData.map2ethNative);

        expect(await wrapped.balanceOf(moss.address)).to.equal("0")

        expect(await ethers.provider.getBalance(receiver)).to.equal("300000000000000000")

        await usdt.mint(moss.address,"5000000000000000000")

        // usdt transferIn 5000000000000000000
        await moss.transferIn(212,mosData.map2ethMapToken);
        expect(await usdt.balanceOf(moss.address)).to.equal("0");
        expect(await usdt.balanceOf(receiver)).to.equal("5000000000000000000");
        expect(await usdt.totalSupply()).to.equal("5000000000000000000");

    });

    it('depositOut test', async function () {
        await moss.connect(addr1).depositToken(
            standardToken.address,
            addr3.address,
            "2000000000000000000000"
        )
        expect(await standardToken.balanceOf(addr1.address)).to.equal("98998000000000000000000000");

        console.log( BigNumber.from(await ethers.provider.getBalance(addr2.address)));
        await moss.connect(addr2).depositNative(
            addr4.address,
            {
                value:"1000000000000000000"
            }
        )

        // expect(await ethers.provider.getBalance(moss.address)).to.equal("9998999928426602550800");
        expect(await wrapped.balanceOf(moss.address)).to.equal("1000000000000000000")
    });

    it('near transferIn test ', async function () {
        //250000000000000000
        await usdt.mint(moss.address,"250000000000000000")
        await moss.transferIn(212,mosData.near2ethW);
        expect(await usdt.totalSupply()).to.equal("5250000000000000000");
        expect(await usdt.balanceOf(moss.address)).to.equal("0");
        expect(await standardToken.totalSupply()).to.equal("99898000100000000000000000");

        //250000000000000000
        await moss.transferIn(212,mosData.near2eth001);

        expect(await standardToken.totalSupply()).to.equal("99898000350000000000000000");
        //100000000000000000
        //250000000000000000
        expect(await standardToken.balanceOf(receiver)).to.equal("350000000000000000");

        //250000000000000000
        await moss.transferIn(212,mosData.near2et000);

        expect(await wrapped.balanceOf(moss.address)).to.equal("750000000000000000");

        expect(await ethers.provider.getBalance(receiver)).to.equal("550000000000000000")

    });


    it('transferOutNative', async function () {
        await moss.registerToken(wrapped.address,1313161555,"true");

        let addressNear = "0x70616e646172722e746573746e6574";

        await moss.connect(owner).transferOutNative(addressNear,1313161555,{value:"100000000000000000"});

        //100000000000000000
        expect(await wrapped.balanceOf(moss.address)).to.equal("850000000000000000")

    });

    it('withdraw test', async function () {
        console.log(await ethers.provider.getBalance(moss.address));
        await moss.emergencyWithdraw(
            wrapped.address,
            addr9.address,
            "850000000000000000"
        )
        expect(await ethers.provider.getBalance(moss.address)).to.equal("0");
        expect(await ethers.provider.getBalance(addr9.address)).to.equal("10000850000000000000000");

        await moss.emergencyWithdraw(
            standardToken.address,
            addr5.address,
            "2000000000000000000000"
        )
        expect(await standardToken.balanceOf(moss.address)).to.equal("898000000000000000000000");

        await addr1.sendTransaction({
            to:moss.address,
            value: ethers.utils.parseEther("2")
        })
        expect(await ethers.provider.getBalance(moss.address)).to.equal("2000000000000000000");

        await moss.emergencyWithdraw(
            "0x0000000000000000000000000000000000000000",
            addr9.address,
            "2000000000000000000"
        )

        expect(await ethers.provider.getBalance(addr9.address)).to.equal("10002850000000000000000");

    });

    it('set test', async function () {
        await moss.setPause();
        expect(await moss.paused()).to.equal(true);
        await moss.setUnpause();
        expect(await moss.paused()).to.equal(false);

        await expect(moss.connect(addr3).setPause()).to.be.revertedWith("relayservice :: only admin")
    });

    it('admin test', async function () {

        await expect(moss.changeAdmin("0x0000000000000000000000000000000000000000")).to.be.revertedWith("address is zero")

        await moss.changeAdmin(addr5.address);

        expect(await moss.getAdmin()).to.equal(addr5.address);

    });

    it('Upgrade', async function () {
        let MOSSUpGrade = await ethers.getContractFactory("MAPOmnichainServiceV2");
        // moss = await ethers.getContractAt("MapCrossChainService",mosData.relayservice);
        let mossUpGrade = await MOSSUpGrade.deploy();
        await mossUpGrade.deployed();

        moss.connect(addr5).upgradeTo(mossUpGrade.address);

        expect(await moss.getImplementation()).to.equal(mossUpGrade.address);

        await expect(moss.transferIn(212,mosData.near2et000)).to.be.revertedWith("order exist");

    });
})


