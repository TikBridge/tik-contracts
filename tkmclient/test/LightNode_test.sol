// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol";

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
import "../contracts/LightNode.sol";
import "../contracts/lib/TKM.sol";
import "../contracts/lib/MPT.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testSuite {

    event Log(bytes32);

    event Log1(TKM.BlockHeader);

    event Log2(address);

    event Log3(bytes);

    event Log4(bytes32[]);

    event Log5(TKM.Receipt);

    TKM.BlockHeader header;


    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        // <instantiate contract>
        Assert.equal(uint(1), uint(1), "1 should be equal to 1");
    }

    function checkReceipt() public {
        TKM.Receipt memory r;

        r.TxHash = hex"0000000000000000000000000000000000000000000000000000000000000000";
        bytes memory b;
        r.PostState = b;
        r.Out = b;
        r.Version = 1;


        emit Log5(r);

        bytes memory bs = TKM.encodeReceipt(r);

        emit Log3(bs);

        bytes32 h = TKM.hashReceipt(r);

        emit Log(h);
    }

    function checkSuccess() public {
        // Use 'Assert' methods: https://remix-ide.readthedocs.io/en/latest/assert_library.html
        // bytes32 h1 = 0x9ab5ee6e7744087d1584c9c537f8ecf96e4fb66f8399309c2170a7cabf988184;
        // bytes32 h2 = 0x04b6803a41704df9768294fcc8507dad2ec676a154b54a88b428c2f959f92b6b;

        // emit Log1(header);

        // bytes memory sig = hex"d951e8ede275d660665c3b27b495f9960c623a0a53a48e4d0fe87ecdc2499f9e0f5af5f6ab39c4adf2676584aebc1db876c74bbf61340aeab2076648b64a8ce601";




        // bytes4 a = 0x0;
        // bytes memory b = Util.b4to4b(a);
        // bytes32 c = keccak256(b);
        // emit Log3(b);
        // emit Log(c);

        // bytes memory hc = Util.u32to4b(header.ChainID);
        // bytes32 hh = keccak256(hc);
        // emit Log3(hc);
        // emit Log(hh);
        // bytes32[] memory list = new bytes32[](5);
        // list[0] =h1;
        // list[1] =h2;
        // list[2] = MPT.NilHashSlice;
        // list[3] = h1;
        // list[4] = MPT.NilHashSlice;

        header.Version = 8;
        header.PreviousHash = hex"fbf08aa590481ec0d66f30c2cb83899bebb9efa7a645cb8b04620baf2da9872d";
        header.HashHistory =hex"ad75a5f7b1144f250084f37dda978cded59aeaf27bd812a75186b2dbfd50c50d";
        header.ChainID = 0;
        header.Height = 29940;
        header.Empty = false;
        header.ParentHeight = 0;
        header.RewardAddress = 0x7857fE4267199C0766A7dA1e1ab66ba01a421A64;
        header.AttendanceHash = hex"c09ce074f9fabce0b8bece6f4a46ca3cf123a6efd8b7850d071ab43225e1be7f";
        header.CommitteeHash = hex"3b3e5859ebb593316f59bca0e2e56d6f5e232b6c51e5b185c492cba3f3fd298d";
        header.ElectedNextRoot = hex"3b3e5859ebb593316f59bca0e2e56d6f5e232b6c51e5b185c492cba3f3fd298d";
        header.NewCommitteeSeed = hex"778fd7925788c8eb44210eba62fd241cc48f6421";
        header.RREra = Util.u64to8b(29);
        header.RRRoot = hex"1944bb47b81d43c1baf7153ff693ddfe6df99dd1eaf30c0cffbb0783724ab2f3";
        header.RRNextRoot = hex"1944bb47b81d43c1baf7153ff693ddfe6df99dd1eaf30c0cffbb0783724ab2f3";
        header.StateRoot = hex"acf1890a60e805815cbf6e93fdb9f7a0184bc51290a39802e0c67e961ab41f35";
        header.ChainInfoRoot = hex"1f17d0958c00f27cc875f5e0315bc912a287e4a850b9bdd2bb6fc0bade721570";
        header.HdsRoot = hex"ab09b91a444c23c53b82224fbe3d4e49901d409238e6f6560419061984d1f200";
        header.TimeStamp= 1688556136;
        header.ElectResultRoot=hex"5fafba1dce5decf45db4c2e60da7169cc286f123a5f06408afa6e12169b64fe6";
        header.ConfirmedRoot=hex"feaaf7c7d250f4aa3830b98a21a8d74ecc71f8792118fbb4cea6f15f899f3eb4";
        header.SeedGenerated = false;

        emit Log1(header);

        bytes32[] memory list = TKM.encodeHeaderToHashList(header);
        emit Log4(list);

        // bytes32 h3 = MPT.MerkleHashComplete(list);
        // emit Log(h3);

        bytes32 ret = TKM.hashBlockHeader(header);
        emit Log(ret);

        // address ad = TKM.recoverSigner(ret, sig);
        // emit Log2(ad);

    }

    // uint32 to 4bytes
    function u32to4b(uint32 x) public pure returns (bytes memory b) {
        b= Util.b4to4b(bytes4(x));
    }

    // uint256 to 32bytes
    function u256to32b(uint256 x) public pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }

    function checkSuccess2() public pure returns (bool) {
        // Use the return value (true or false) to test the contract
        return true;
    }

    function checkFailure() public {
        Assert.notEqual(uint(1), uint(2), "1 should not be equal to 1");
    }

    /// Custom Transaction Context: https://remix-ide.readthedocs.io/en/latest/unittesting.html#customization
    /// #sender: account-1
    /// #value: 100
    function checkSenderAndValue() public payable {
        // account index varies 0-9, value is in wei
        Assert.equal(msg.sender, TestsAccounts.getAccount(1), "Invalid sender");
        Assert.equal(msg.value, 100, "Invalid value");
    }
}
