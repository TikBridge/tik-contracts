// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../lib/TKM.sol";

interface ILightNode {

    function initialize(
        uint64 _currentHeight,
        bytes[] memory _currentCommittee,
        bytes[] memory _nextCommittee,
        uint64 _epochLength
    ) external;

    function verifyProofData(bytes memory proofBytes)
        external
        view
        returns (
            bool success,
            string memory message,
            bytes memory logBytes
        );


    function updateCommittee(TKM.CommitteeData memory commData) external returns (bool);

    function resetCommittee(uint64 epoch, bytes[] memory committee) external returns (bool);

    function lastHeaderHeight() external view returns (uint64);

    function checkEpochCommittee(uint64 epoch) external view returns (address[] memory);

}
