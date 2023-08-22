// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../lib/TKM.sol";

interface ILightNode {

    event UpdateBlockHeader(address indexed account, uint64 indexed blockHeight);

    function initialize(
        uint64 _currentEpoch,
        bytes[] memory _currentCommittee,
        bytes[] memory _nextCommittee
    ) external;

    function verifyProofData(bytes memory proofBytes)
        external
        view
        returns (
            bool success,
            string memory message,
            bytes memory logBytes
        );


    function updateCommittee(bytes memory epochCommittee) external returns (bool);

    function resetCommittee(bytes memory epochCommittee) external returns (bool);

    function lastHeaderHeight() external view returns (uint64);

    function checkEpochCommittee(uint64 epoch) external view returns (address[] memory);

}
