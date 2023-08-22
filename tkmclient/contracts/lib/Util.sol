// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

library Util {

    // address to bytes
    function addr2bytes(address a) internal pure returns (bytes memory ret) {
        bytes20 b = bytes20(a);
        ret = new bytes(b.length);
        for (uint i = 0; i< b.length; i++){
            ret[i] = b[i];
        }
    }

    // uint2 to bytes
    function u16to2b(uint16 v) internal pure returns (bytes memory b) {
        b = b2to2b(bytes2(v));
    }

    // uint32 to 4bytes
    function u32to4b(uint32 v) internal pure returns (bytes memory b) {
        b= b4to4b(bytes4(v));
    }

    // uint64 to 8bytes
    function u64to8b(uint64 v) internal pure returns (bytes memory b) {
        b= b8to8b(bytes8(v));
    }

    // uint256 to 32bytes
    function u256to32b(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }

    // uint to bytes
    function uint2bytes(uint x) internal pure returns (bytes memory b) {
        b = u256to32b(x);
    }

    // bytes to bytes20
    function _20b2b20(bytes memory data) internal pure returns (bytes20 part) {
        require(data.length == 0 || data.length == 20, "bytes length should be 0 or 20");
        assembly {
            part := mload(add(data, 20))
        }
    }

    // bytes to bytes32
    function _32b2b32(bytes memory data) internal pure returns (bytes32 part) {
        require(data.length == 0 || data.length == 32, "bytes length should be 0 or 32");
        assembly {
            part := mload(add(data, 32))
        }
    }

    // bytes2 to bytes
    function b2to2b(bytes2 data) internal pure returns (bytes memory ret){
        ret = new bytes(data.length);
        for (uint i = 0; i< data.length; i++){
            ret[i] = data[i];
        }
    }

    // bytes4 to bytes
    function b4to4b(bytes4 data) internal pure returns (bytes memory ret){
        ret = new bytes(data.length);
        for (uint i = 0; i< data.length; i++){
            ret[i] = data[i];
        }
    }

    // bytes8 to bytes
    function b8to8b(bytes8 data) internal pure returns (bytes memory ret){
        ret = new bytes(data.length);
        for (uint i = 0; i< data.length; i++){
            ret[i] = data[i];
        }
    }

    // bytes32 to bytes
    function b20to20b(bytes20 data) internal pure returns (bytes memory ret){
        ret = new bytes(data.length);
        for (uint i = 0; i< data.length; i++){
            ret[i] = data[i];
        }
    }

    // bytes32 to bytes
    function b32to32b(bytes32 data) internal pure returns (bytes memory ret){
        ret = new bytes(data.length);
        for (uint i = 0; i< data.length; i++){
            ret[i] = data[i];
        }
    }

    // bytes32 to address
    function b32toa(bytes32 data) internal pure returns (address addr) {
        bytes memory r = new bytes(20);
        for(uint i=12; i<data.length; i++){
            r[i-12] = data[i];
        }
        assembly {
            addr := mload(add(r,20))
        }
    }

}
