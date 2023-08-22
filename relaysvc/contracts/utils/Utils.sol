// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

//import "hardhat/console.sol";

library Utils {
    uint constant MIN_NEAR_ADDRESS_LEN = 2;
    uint constant MAX_NEAR_ADDRESS_LEN = 64;

    function checkBytes(bytes memory b1, bytes memory b2) internal pure returns (bool){
        return keccak256(b1) == keccak256(b2);
    }

    function fromBytes(bytes memory bys) internal pure returns (address addr){
        assembly {
            addr := mload(add(bys, 20))
        }
    }


    function toBytes(address self) internal pure returns (bytes memory b) {
        b = abi.encodePacked(self);
    }

    function splitExtra(bytes memory extra)
    internal
    pure
    returns (bytes memory newExtra){
        require(extra.length >= 64, "Invalid extra result type");
        newExtra = new bytes(64);
        for (uint256 i = 0; i < 64; i++) {
            newExtra[i] = extra[i];
        }
    }


    function hexStrToBytes(bytes memory _hexStr)
    internal
    pure
    returns (bytes memory)
    {
        //Check hex string is valid
        if (
            _hexStr.length % 2 != 0 ||
            _hexStr.length < 4
        ) {
            revert("hexStrToBytes: invalid input");
        }

        bytes memory bytes_array = new bytes(_hexStr.length / 2 - 32);

        for (uint256 i = 64; i < _hexStr.length; i += 2) {
            uint8 tetrad1 = 16;
            uint8 tetrad2 = 16;

            //left digit
            if (
                uint8(_hexStr[i]) >= 48 && uint8(_hexStr[i]) <= 57
            ) tetrad1 = uint8(_hexStr[i]) - 48;

            //right digit
            if (
                uint8(_hexStr[i + 1]) >= 48 &&
                uint8(_hexStr[i + 1]) <= 57
            ) tetrad2 = uint8(_hexStr[i + 1]) - 48;

            //left A->F
            if (
                uint8(_hexStr[i]) >= 65 && uint8(_hexStr[i]) <= 70
            ) tetrad1 = uint8(_hexStr[i]) - 65 + 10;

            //right A->F
            if (
                uint8(_hexStr[i + 1]) >= 65 &&
                uint8(_hexStr[i + 1]) <= 70
            ) tetrad2 = uint8(_hexStr[i + 1]) - 65 + 10;

            //left a->f
            if (
                uint8(_hexStr[i]) >= 97 &&
                uint8(_hexStr[i]) <= 102
            ) tetrad1 = uint8(_hexStr[i]) - 97 + 10;

            //right a->f
            if (
                uint8(_hexStr[i + 1]) >= 97 &&
                uint8(_hexStr[i + 1]) <= 102
            ) tetrad2 = uint8(_hexStr[i + 1]) - 97 + 10;

            //Check all symbols are allowed
            if (tetrad1 == 16 || tetrad2 == 16)
                revert("hexStrToBytes: invalid input");

            bytes_array[i / 2 - 32] = bytes1(16 * tetrad1 + tetrad2);
        }

        return bytes_array;
    }


    function isValidNearAddress(bytes memory _addr) internal pure returns (bool){
        if (_addr.length < MIN_NEAR_ADDRESS_LEN || _addr.length > MAX_NEAR_ADDRESS_LEN) {
            return false;
        }
        bool last_char_is_separator = true;
        for (uint i = 0; i < _addr.length; i++) {
            uint8 char = uint8(_addr[i]);
            bool current_char_is_separator = false;

            //char 97-122 is a-z, 48-57 is 0-9 , 45 is - ,46 is .,95 is _
            if ((char >= 97 && char <= 122) || (char >= 48 && char <= 57) || (char == 45 || char == 46 || char == 95)) {
                if ((char == 45 || char == 46 || char == 95)) {
                    current_char_is_separator = true;
                }
            } else {
                return false;
            }

            if (current_char_is_separator && last_char_is_separator) {
                return false;
            }

            last_char_is_separator = current_char_is_separator;
        }
        return !last_char_is_separator;
    }

    function isValidEvmAddress(bytes memory _addr) internal pure returns (bool){
        return _addr.length == 20;
    }

    function isValidAddress(bytes memory _addr, uint chainType) internal pure returns (bool){
        if (chainType == 1) return isValidEvmAddress(_addr);
        if (chainType == 2) return isValidNearAddress(_addr);
        return false;
    }
}