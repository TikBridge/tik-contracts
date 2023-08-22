// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./MPT.sol";
import "./RLPReader.sol";
import "./RLPEncode.sol";
import "./Util.sol";

library TKM {

//    using RLPReader for bytes;
//    using RLPReader for uint256;
//    using RLPReader for RLPReader.RLPItem;
//    using RLPReader for RLPReader.Iterator;

    uint64 internal constant EPOCH_LENGTH = 1000;

    uint8 internal constant BHPreviousHash     = 0;
    uint8 internal constant BHHashHistory      = 1;
    uint8 internal constant BHChainID          = 2;
    uint8 internal constant BHHeight           = 3;
    uint8 internal constant BHEmpty            = 4;
    uint8 internal constant BHParentHeight     = 5;
    uint8 internal constant BHParentHash       = 6;
    uint8 internal constant BHRewardAddress    = 7;
    uint8 internal constant BHCommitteeHash    = 8;
    uint8 internal constant BHElectedNextRoot  = 9;
    uint8 internal constant BHNewCommitteeSeed = 10;
    uint8 internal constant BHMergedDeltaRoot  = 11;
    uint8 internal constant BHBalanceDeltaRoot = 12;
    uint8 internal constant BHStateRoot        = 13;
    uint8 internal constant BHChainInfoRoot    = 14;
    uint8 internal constant BHWaterlinesRoot   = 15;
    uint8 internal constant BHVCCRoot          = 16;
    uint8 internal constant BHCashedRoot       = 17;
    uint8 internal constant BHTransactionRoot  = 18;
    uint8 internal constant BHReceiptRoot      = 19;
    uint8 internal constant BHHdsRoot          = 20;
    uint8 internal constant BHTimeStamp        = 21;
    uint8 internal constant BHAttendanceHash   = 22;
    uint8 internal constant BHRewardedCursor   = 23;
    uint8 internal constant BHRREra            = 24;
    uint8 internal constant BHRRRoot           = 25;
    uint8 internal constant BHRRNextRoot       = 26;
    uint8 internal constant BHRRChangingRoot   = 27;
    uint8 internal constant BHElectResultRoot  = 28;
    uint8 internal constant BHPreElectedRoot   = 29;
    uint8 internal constant BHFactorRoot       = 30;
    uint8 internal constant BHRRReceiptRoot    = 31;
    uint8 internal constant BHVersion          = 32;
    uint8 internal constant BHConfirmedRoot    = 33;
    uint8 internal constant BHRewardedEra      = 34;
    uint8 internal constant BHBridgeRoot       = 35;
    uint8 internal constant BHRandomHash       = 36;
    uint8 internal constant BHSeedGenerated    = 37;
    uint8 internal constant BHTxParams         = 38;
    uint8 internal constant BHSize             = 39;



    struct Log {
        address   Address;
        bytes32[] Topics;
        bytes     Data;
        uint64    BlockNumber;
        bytes32   TxHash;
        uint32    TxIndex;
        uint32    Index;
        bytes32   BlockHash;
    }

    struct Bonus {
        address Winner;
        uint256 Val;
    }

    struct Receipt {
        bytes   PostState;
        uint64  Status;
        uint64  CumulativeGasUsed ;
        Log[]   Logs;
        bytes   TxHash;
        address ContractAddress;
        uint64  GasUsed;
        bytes   Out;
        string  Error;
        Bonus[] GasBonuses;
        uint16  Version;
    }

    struct BlockHeader {
        bytes   PreviousHash;
        bytes   HashHistory;
        uint32  ChainID;
        uint64  Height;
        bool    Empty;
        uint64  ParentHeight;
        bytes   ParentHash;
        address RewardAddress;
        bytes   AttendanceHash;
        bytes   RewardedCursor;
        bytes   CommitteeHash;
        bytes   ElectedNextRoot;
        bytes   NewCommitteeSeed;
        bytes   RREra;
        bytes   RRRoot;
        bytes   RRNextRoot;
        bytes   RRChangingRoot;
        bytes   MergedDeltaRoot;
        bytes   BalanceDeltaRoot;
        bytes   StateRoot;
        bytes   ChainInfoRoot;
        bytes   WaterlinesRoot;
        bytes   VCCRoot;
        bytes   CashedRoot;
        bytes   TransactionRoot;
        bytes   ReceiptRoot;
        bytes   HdsRoot;
        uint64  TimeStamp;
        bytes   ElectResultRoot;
        bytes   PreElectRoot;
        bytes   FactorRoot;
        bytes   RRReceiptRoot;
        uint16  Version;
        bytes   ConfirmedRoot;
        bytes   RewardedEra;
        bytes   BridgeRoot;
        bytes   RandomHash;
        bool    SeedGenerated;
        bytes   TxParamsRoot;
    }

    struct ReceiptProof {
        Receipt r;
        Log log;
        MPT.MerkleProof[] logProof;
        MPT.MerkleProof[] p;
        BlockHeader h;
        bytes[] s;
    }

    struct CommitteeProof {
        BlockHeader header;
        bytes[] committee;
        bytes[] signatures;
    }

    function epochNum(uint64 h) internal pure returns (uint64) {
        return h / EPOCH_LENGTH;
    }

    function hashBlockHeader(BlockHeader memory h) internal pure returns (bytes32) {
        bytes32[] memory list = encodeHeaderToHashList(h);
        return MPT.MerkleHashComplete(list);
    }

    function hashReceipt(Receipt memory r) internal pure returns (bytes32) {
        bytes memory b = encodeReceipt(r);
        return keccak256(b);
    }

    function hashCommittee(bytes[] memory committee) internal pure returns (bytes32) {
        if (committee.length == 0) {
            return MPT.NilHashSlice;
        }
        bytes32[] memory hashList = new bytes32[](committee.length);
        for (uint i=0; i<committee.length; i++) {
            hashList[i] = keccak256(committee[i]);
        }
        return MPT.MerkleHashComplete(hashList);
    }

    function verifyHeaderSignature(
        bytes32 hash,
        bytes[] memory signatures,
        address[] memory committee
    ) internal pure returns (bool) {
        require(committee.length > 0, "committee missing");
        uint checkSigCount = 0;
        address[] memory miners = new address[](committee.length);
        for (uint i=0; i<signatures.length; i++) {
            address signer = recoverSigner(hash, signatures[i]);
            if (signer != address(0) && checkInComm(signer, committee) && !isRepeat(miners, signer, i)) {
                miners[i]=signer;
                checkSigCount++;
            }
        }
        // more than 2/3 committee signed
        return checkSigCount >= committee.length / 3 * 2 + 1;
    }

    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        if (v <= 1) {
            v = v + 27;
        }
        return ecrecover(hash, v, r, s);
    }

    function checkInComm(address signer, address[] memory comm) internal pure returns (bool) {
        for (uint i=0; i<comm.length; i++){
            if (signer == comm[i]) {
                return true;
            }
        }
        return false;
    }

    function isRepeat(address[] memory miners, address miner, uint limit) internal pure returns (bool) {
        for (uint i = 0; i < limit; i++) {
            if (miners[i] == miner) {
                return true;
            }
        }
        return false;
    }

    function pub2addr(bytes memory pub) internal pure returns (address a) {
        bytes32 b = keccak256(pub);
        return Util.b32toa(b);
    }

    function pubs2addr(bytes[] memory comm) internal pure returns (address[] memory ret) {
        ret = new address[](comm.length);
        for(uint i=0; i<comm.length; i++){
            ret[i] = pub2addr(comm[i]);
        }
    }


    function headerIndexHash(bytes memory posBuffer, uint8 index) internal pure returns (bytes32) {
        bytes memory n = new bytes(13);
        for(uint i =0; i<12; i++) {
            n[i] = posBuffer[i];
        }
        n[12] = bytes1(index);
        return keccak256(n);
    }

    function hashIndexProperty(bytes memory posBuffer, uint8 index ,bytes32 h) internal pure returns (bytes32) {
        bytes32 indexHash = headerIndexHash(posBuffer, index);
        return MPT.HashPair(indexHash, h);
    }

    function hashBytesIndexProperty(bytes memory posBuffer, uint8 index ,bytes memory h) internal pure returns (bytes32) {
        bytes32 indexHash = headerIndexHash(posBuffer, index);
        return MPT.HashPair(indexHash, Util._32b2b32(h));
    }

    function nilHashOrSelf(bytes memory h) internal pure returns (bytes32) {
        require(h.length==0 || h.length==32, "hash length should be 0 or 32");
        if (h.length == 0) {
            return MPT.NilHashSlice;
        } else {
            return Util._32b2b32(h);
        }
    }

    function nilHashOrSeedHash(bytes memory s) internal pure returns (bytes32) {
        require(s.length==0 || s.length==20, "seed length should be 0 or 20");
        if (s.length == 0) {
            return MPT.NilHashSlice;
        } else {
            return keccak256(s);
        }
    }

    function nilHashOrUint64Hash(bytes memory h) internal pure returns (bytes32) {
        require(h.length==0 || h.length==8, "uint64 bytes length should be 0 or 8");
        if (h.length == 0) {
            return MPT.NilHashSlice;
        } else {
            return keccak256(h);
        }
    }

    function hashBool(bool b) internal pure returns (bytes32) {
        bytes memory r = new bytes(1);
        if (b) {
            r[0] = 0x01;
        } else {
            r[0] = 0;
        }
        return keccak256(r);
    }

    function encodeHeaderToHashList(BlockHeader memory h) internal pure returns (bytes32[] memory) {
        bytes memory posBuffer = abi.encodePacked(bytes4(h.ChainID), bytes8(h.Height));
        // posBuffer.length = 13;

        bytes32[] memory hashList = new bytes32[](39);
        hashList[0] = hashBytesIndexProperty(posBuffer, BHPreviousHash, h.PreviousHash);
        hashList[1] = hashBytesIndexProperty(posBuffer, BHHashHistory, h.HashHistory);

        bytes memory hc = Util.u32to4b(h.ChainID);
        hashList[2] = hashIndexProperty(posBuffer, BHChainID, keccak256(hc));

        bytes memory hh = Util.u64to8b(h.Height);
        hashList[3] = hashIndexProperty(posBuffer, BHHeight, keccak256(hh));

        hashList[4] = hashIndexProperty(posBuffer, BHEmpty, hashBool(h.Empty));

        bytes memory hp = Util.u64to8b(h.ParentHeight);
        hashList[5] = hashIndexProperty(posBuffer, BHParentHeight, keccak256(hp));

        hashList[6] = hashIndexProperty(posBuffer, BHParentHash, nilHashOrSelf(h.ParentHash));
        hashList[7] = hashIndexProperty(posBuffer, BHRewardAddress, keccak256(Util.addr2bytes(h.RewardAddress)));
        hashList[8] = hashIndexProperty(posBuffer, BHCommitteeHash, nilHashOrSelf(h.CommitteeHash));
        hashList[9] = hashIndexProperty(posBuffer, BHElectedNextRoot, nilHashOrSelf(h.ElectedNextRoot));

        hashList[10] = hashIndexProperty(posBuffer, BHNewCommitteeSeed, nilHashOrSeedHash(h.NewCommitteeSeed));

        hashList[11] = hashIndexProperty(posBuffer, BHMergedDeltaRoot, nilHashOrSelf(h.MergedDeltaRoot));
        hashList[12] = hashIndexProperty(posBuffer, BHBalanceDeltaRoot, nilHashOrSelf(h.BalanceDeltaRoot));
        hashList[13] = hashBytesIndexProperty(posBuffer, BHStateRoot, h.StateRoot);
        hashList[14] = hashIndexProperty(posBuffer, BHChainInfoRoot, nilHashOrSelf(h.ChainInfoRoot));
        hashList[15] = hashIndexProperty(posBuffer, BHWaterlinesRoot, nilHashOrSelf(h.WaterlinesRoot));
        hashList[16] = hashIndexProperty(posBuffer, BHVCCRoot, nilHashOrSelf(h.VCCRoot));
        hashList[17] = hashIndexProperty(posBuffer, BHCashedRoot, nilHashOrSelf(h.CashedRoot));
        hashList[18] = hashIndexProperty(posBuffer, BHTransactionRoot, nilHashOrSelf(h.TransactionRoot));
        hashList[19] = hashIndexProperty(posBuffer, BHReceiptRoot, nilHashOrSelf(h.ReceiptRoot));
        hashList[20] = hashIndexProperty(posBuffer, BHHdsRoot, nilHashOrSelf(h.HdsRoot));
        hashList[21] = hashIndexProperty(posBuffer, BHTimeStamp, keccak256(Util.u64to8b(h.TimeStamp)));

        hashList[22] = hashIndexProperty(posBuffer, BHAttendanceHash, nilHashOrSelf(h.AttendanceHash));
        hashList[23] = hashIndexProperty(posBuffer, BHRewardedCursor, nilHashOrUint64Hash(h.RewardedCursor));
        hashList[24] = hashIndexProperty(posBuffer, BHRREra, nilHashOrUint64Hash(h.RREra));
        hashList[25] = hashIndexProperty(posBuffer, BHRRRoot, nilHashOrSelf(h.RRRoot));
        hashList[26] = hashIndexProperty(posBuffer, BHRRNextRoot, nilHashOrSelf(h.RRNextRoot));
        hashList[27] = hashIndexProperty(posBuffer, BHRRChangingRoot, nilHashOrSelf(h.RRChangingRoot));
        hashList[28] = hashIndexProperty(posBuffer, BHElectResultRoot, nilHashOrSelf(h.ElectResultRoot));
        hashList[29] = hashIndexProperty(posBuffer, BHPreElectedRoot, nilHashOrSelf(h.PreElectRoot));
        hashList[30] = hashIndexProperty(posBuffer, BHFactorRoot, nilHashOrSelf(h.FactorRoot));
        hashList[31] = hashIndexProperty(posBuffer, BHRRReceiptRoot, nilHashOrSelf(h.RRReceiptRoot));
        hashList[32] = hashIndexProperty(posBuffer, BHVersion, keccak256(Util.u16to2b(h.Version)));

        hashList[33] = hashIndexProperty(posBuffer, BHConfirmedRoot, nilHashOrSelf(h.ConfirmedRoot));
        hashList[34] = hashIndexProperty(posBuffer, BHRewardedEra, nilHashOrUint64Hash(h.RewardedEra));
        hashList[35] = hashIndexProperty(posBuffer, BHBridgeRoot, nilHashOrSelf(h.BridgeRoot));
        hashList[36] = hashIndexProperty(posBuffer, BHRandomHash, nilHashOrSelf(h.RandomHash));
        hashList[37] = hashIndexProperty(posBuffer, BHSeedGenerated, hashBool(h.SeedGenerated));
        hashList[38] = hashIndexProperty(posBuffer, BHTxParams, nilHashOrSelf(h.TxParamsRoot));

        return hashList;
    }

    function encodeReceipt(Receipt memory _txReceipt)
    internal
    pure
    returns (bytes memory output)
    {
        bytes[] memory list = new bytes[](11);
        list[0] = RLPEncode.encodeBytes(_txReceipt.PostState);
        list[1] = RLPEncode.encodeUint(_txReceipt.Status);
        list[2] = RLPEncode.encodeUint(_txReceipt.CumulativeGasUsed);
        bytes[] memory listLog = new bytes[](_txReceipt.Logs.length);
        bytes[] memory loglist = new bytes[](8);
        for (uint256 j = 0; j < _txReceipt.Logs.length; j++) {
            loglist[0] = RLPEncode.encodeAddress(_txReceipt.Logs[j].Address);
            bytes[] memory loglist1 = new bytes[](_txReceipt.Logs[j].Topics.length);

            for (uint256 i = 0; i < _txReceipt.Logs[j].Topics.length; i++) {
                loglist1[i] = RLPEncode.encodeBytes(Util.b32to32b(_txReceipt.Logs[j].Topics[i]));
            }
            loglist[1] = RLPEncode.encodeList(loglist1);
            loglist[2] = RLPEncode.encodeBytes(_txReceipt.Logs[j].Data);
            loglist[3] = RLPEncode.encodeUint(_txReceipt.Logs[j].BlockNumber);
            loglist[4] = RLPEncode.encodeBytes(Util.b32to32b(_txReceipt.Logs[j].TxHash));
            loglist[5] = RLPEncode.encodeUint(_txReceipt.Logs[j].TxIndex);
            loglist[6] = RLPEncode.encodeUint(_txReceipt.Logs[j].Index);
            loglist[7] = RLPEncode.encodeBytes(Util.b32to32b(_txReceipt.Logs[j].BlockHash));
            bytes memory logBytes = RLPEncode.encodeList(loglist);
            listLog[j] = logBytes;
        }
        list[3] = RLPEncode.encodeList(listLog);
        list[4] = RLPEncode.encodeBytes(_txReceipt.TxHash);
        list[5] = RLPEncode.encodeAddress(_txReceipt.ContractAddress);
        list[6] = RLPEncode.encodeUint(_txReceipt.GasUsed);
        list[7] = RLPEncode.encodeBytes(_txReceipt.Out);
        list[8] = RLPEncode.encodeString(_txReceipt.Error);
        bytes[] memory listBonus = new bytes[](_txReceipt.GasBonuses.length);
        bytes[] memory bnList = new bytes[](2);
        for (uint256 j = 0; j < _txReceipt.GasBonuses.length; j++) {
            bnList[0] = RLPEncode.encodeAddress(_txReceipt.GasBonuses[j].Winner);
            bnList[1] = RLPEncode.encodeUint(_txReceipt.GasBonuses[j].Val);
            listBonus[j] =  RLPEncode.encodeList(bnList);
        }
        list[9] = RLPEncode.encodeList(listBonus);
        list[10] = RLPEncode.encodeUint(_txReceipt.Version);
        output = RLPEncode.encodeList(list);
    }

    function encodeReceiptLogs(Receipt memory _txReceipt)
    internal
    pure
    returns (bytes memory output) {
        bytes[] memory listLog = new bytes[](_txReceipt.Logs.length);
        bytes[] memory loglist = new bytes[](8);
        for (uint256 j = 0; j < _txReceipt.Logs.length; j++) {
            loglist[0] = RLPEncode.encodeAddress(_txReceipt.Logs[j].Address);
            bytes[] memory loglist1 = new bytes[](_txReceipt.Logs[j].Topics.length);

            for (uint256 i = 0; i < _txReceipt.Logs[j].Topics.length; i++) {
                loglist1[i] = RLPEncode.encodeBytes(Util.b32to32b(_txReceipt.Logs[j].Topics[i]));
            }
            loglist[1] = RLPEncode.encodeList(loglist1);
            loglist[2] = RLPEncode.encodeBytes(_txReceipt.Logs[j].Data);
            loglist[3] = RLPEncode.encodeUint(_txReceipt.Logs[j].BlockNumber);
            loglist[4] = RLPEncode.encodeBytes(Util.b32to32b(_txReceipt.Logs[j].TxHash));
            loglist[5] = RLPEncode.encodeUint(_txReceipt.Logs[j].TxIndex);
            loglist[6] = RLPEncode.encodeUint(_txReceipt.Logs[j].Index);
            loglist[7] = RLPEncode.encodeBytes(Util.b32to32b(_txReceipt.Logs[j].BlockHash));
            bytes memory logBytes = RLPEncode.encodeList(loglist);
            listLog[j] = logBytes;
        }
        output = RLPEncode.encodeList(listLog);
    }

    function encodeReceiptV2(Receipt memory _txReceipt, bytes32 logRoot) internal pure returns (bytes memory output) {
        bytes[] memory list = new bytes[](11);
        list[0] = RLPEncode.encodeBytes(_txReceipt.PostState);
        list[1] = RLPEncode.encodeUint(_txReceipt.Status);
        list[2] = RLPEncode.encodeUint(_txReceipt.CumulativeGasUsed);
        list[3] = RLPEncode.encodeBytes(Util.b32to32b(logRoot));
        list[4] = RLPEncode.encodeBytes(_txReceipt.TxHash);
        list[5] = RLPEncode.encodeAddress(_txReceipt.ContractAddress);
        list[6] = RLPEncode.encodeUint(_txReceipt.GasUsed);
        list[7] = RLPEncode.encodeBytes(_txReceipt.Out);
        list[8] = RLPEncode.encodeString(_txReceipt.Error);
        bytes[] memory listBonus = new bytes[](_txReceipt.GasBonuses.length);
        bytes[] memory bnList = new bytes[](2);
        for (uint256 j = 0; j < _txReceipt.GasBonuses.length; j++) {
            bnList[0] = RLPEncode.encodeAddress(_txReceipt.GasBonuses[j].Winner);
            bnList[1] = RLPEncode.encodeUint(_txReceipt.GasBonuses[j].Val);
            listBonus[j] =  RLPEncode.encodeList(bnList);
        }
        list[9] = RLPEncode.encodeList(listBonus);
        list[10] = RLPEncode.encodeUint(_txReceipt.Version);
        output = RLPEncode.encodeList(list);
    }

    function encodeLog(Log memory _log) internal pure returns (bytes memory output) {
        bytes[] memory loglist = new bytes[](8);
        loglist[0] = RLPEncode.encodeAddress(_log.Address);
        bytes[] memory loglist1 = new bytes[](_log.Topics.length);
        for (uint256 i = 0; i < _log.Topics.length; i++) {
            loglist1[i] = RLPEncode.encodeBytes(Util.b32to32b(_log.Topics[i]));
        }
        loglist[1] = RLPEncode.encodeList(loglist1);
        loglist[2] = RLPEncode.encodeBytes(_log.Data);
        loglist[3] = RLPEncode.encodeUint(_log.BlockNumber);
        loglist[4] = RLPEncode.encodeBytes(Util.b32to32b(_log.TxHash));
        loglist[5] = RLPEncode.encodeUint(_log.TxIndex);
        loglist[6] = RLPEncode.encodeUint(_log.Index);
        loglist[7] = RLPEncode.encodeBytes(Util.b32to32b(_log.BlockHash));
        output = RLPEncode.encodeList(loglist);
    }

    function hashReceiptV2(ReceiptProof memory receiptData) internal pure returns (bytes memory logBytes, bytes32 rcptHash) {
        require(receiptData.r.Version>=2, "receipt version should be v2");
        logBytes = encodeLog(receiptData.log);
        bytes32 logHash = keccak256(logBytes);
        bytes32 logRoot = MPT.VerifyProofs(logHash, receiptData.logProof);
        bytes memory rcptBytes = encodeReceiptV2(receiptData.r, logRoot);
        rcptHash = keccak256(rcptBytes);
    }
}
