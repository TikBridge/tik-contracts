// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

library MPT {

    bytes32 constant NilHashSlice = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    struct MerkleProof {
        bytes32 Hash;
        bool    Pos;  // left true
        uint8   Repeat;
    }


    function MerkleHashComplete(bytes32[] memory hashList) internal pure returns (bytes32) {
        if (hashList.length == 0) {
            return NilHashSlice;
        }

        // Find the smallest power value of 2 greater than the length of hashList and fill it with
        // NilHash value, which is used as the leaf node of balanced binary tree
        uint256 max = 2;
        for (;max < hashList.length;) {
            max <<= 1;
        }

        uint l =  max>>1;
        bytes32[] memory b = new bytes32[](l);

        // var hh []byte

        for (;max > 1;) {
            // Calculate the value of each layer of the balanced binary tree from bottom to top
            max >>= 1;
            // b := make([][]byte, max)
            for (uint i = 0; i < max; i++) {
                uint p1 = i << 1;
                uint p2 = p1 + 1;
                bytes32 ba = NilHashSlice;
                bytes32 bb = NilHashSlice;
                if (p1 < hashList.length) {
                    ba = hashList[p1];
                }
                if (p2 < hashList.length) {
                    bb = hashList[p2];
                }
                b[i] = HashPair(ba, bb);
            }
            hashList = b;
        }
        return hashList[0];
    }

    function HashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(a,b));
    }

    function HashWithProof(bytes32 a, MerkleProof memory p) internal pure returns (bytes32) {
        bytes32 ret = a;
        for (uint i=0; i<=p.Repeat; i++ ) {
            if (p.Pos) {
                ret = HashPair(p.Hash, ret);
            } else {
                ret = HashPair(ret, p.Hash);
            }
        }
        return ret;
    }

    function VerifyProofs(bytes32 toBeProof, MerkleProof[] memory mps) internal pure returns (bytes32) {
        if (mps.length == 0) {
            return toBeProof;
        }
        bytes32 ret = toBeProof;
        for (uint i=0; i<mps.length; i++) {
            ret = HashWithProof(ret, mps[i]);
        }
        return ret;
    }

}
