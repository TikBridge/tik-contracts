// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interface/ILightNode.sol";
import "./lib/MPT.sol";
import "./lib/TKM.sol";

contract LightNode is UUPSUpgradeable, Initializable, Pausable, ILightNode {

    // owner address
    address private _pendingAdmin;
    // epochNum => committeeMembers
    mapping(uint64 => address[]) public relayChainCommittee;
    // relay chain latest block header
    uint64 public lastHeight;
    // epoch range ends in relayChainCommittee, min endsOfEpoch[0], max endsOfEpoch[1].
    uint64[2] public endsOfEpoch;

    uint64 private epochLength;

    event initializeCommittee(uint64 indexed epoch, bytes[] _currentCommittee);
    event UpdateCommittee(uint64 indexed epoch, bytes32 indexed commHash);
    event ChangePendingAdmin(address indexed previousPending, address indexed newPending);
    event AdminTransferred(address indexed previous, address indexed newAdmin);


    modifier onlyOwner() {
        require(msg.sender == _getAdmin(), "LightNode :: only admin");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor()  {}

    /** initialize  **********************************************************/
    function initialize(
        uint64 _currentHeight,
        bytes[] memory _currentCommittee,
        bytes[] memory _nextCommittee,
        uint64 _epochLength
        )
    external
    override
    initializer {
        require(_currentHeight > 0, "current height invalid");
        require(_currentCommittee.length >= 4, "committee length invalid");
        require(_epochLength >= 1000, "epochLength >= 1000");

        _changeAdmin(tx.origin);

        uint64 _currentEpoch = _currentHeight/_epochLength;
        relayChainCommittee[_currentEpoch] = TKM.pubs2addr(_currentCommittee);
        endsOfEpoch[0] = _currentEpoch;
        endsOfEpoch[1] = _currentEpoch;
        if (_nextCommittee.length >= 4) {
            relayChainCommittee[_currentEpoch+1] = TKM.pubs2addr(_nextCommittee);
            endsOfEpoch[1] = _currentEpoch+1;
        }
        lastHeight = _currentHeight;
        epochLength = _epochLength;

        emit initializeCommittee(_currentEpoch, _currentCommittee);
    }

    function verifyProofData(bytes memory proofBytes)
    external
    view
    override
    returns (bool success, string memory message, bytes memory logBytes) {
        TKM.ReceiptData memory receiptData = abi.decode(proofBytes, (TKM.ReceiptData));
        uint64 epoch = receiptData.height / epochLength;
        require(epoch >= endsOfEpoch[0] && epoch <= endsOfEpoch[1], "epoch invalid");

        require(
            TKM.isHeaderPropertyHash(receiptData.proof, receiptData.chainid, receiptData.height, TKM.BHReceiptRoot),
            "invalid pos"
        );

        if (receiptData.rcpt.Version<2) {
            bytes32 headerRoot = MPT.VerifyProofs(TKM.hashReceipt(receiptData.rcpt), receiptData.proof);
            success = TKM.verifyHeaderSignature(headerRoot, receiptData.sigs, relayChainCommittee[epoch]);
            if (success) {
                logBytes = TKM.encodeReceiptLogs(receiptData.rcpt);
            } else {
                message = "proof verify failed";
            }
        } else {
            (bytes memory oneLogBytes, bytes32 rcptHash) = TKM.hashReceiptV2(receiptData);
            bytes32 headerRoot = MPT.VerifyProofs(rcptHash, receiptData.proof);
            success = TKM.verifyHeaderSignature(headerRoot, receiptData.sigs, relayChainCommittee[epoch]);
            if (success) {
                bytes[] memory listLog = new bytes[](1);
                listLog[0] = oneLogBytes;
                logBytes = RLPEncode.encodeList(listLog);
            } else {
                message = "proof v2 verify failed";
            }
        }
    }

    function updateCommittee(TKM.CommitteeData memory commData) external override whenNotPaused returns (bool){
        require(commData.height > lastHeight, "only update future epoch comm");
        require(commData.committee.length >= 4, "committee length invalid");
        uint64 epoch = commData.height / epochLength;
        require(epoch == endsOfEpoch[1], "only update next epoch comm");
//        require(commData.syncingEpoch <= epoch, "syncing epoch invalid");

        require(
            TKM.isHeaderPropertyHash(commData.proof, commData.chainid, commData.height, TKM.BHElectedNextRoot),
            "invalid pos"
        );

        bytes32 commHash = TKM.hashCommittee(commData.committee);
        bytes32 headerRoot = MPT.VerifyProofs(commHash, commData.proof);
        if (TKM.verifyHeaderSignature(headerRoot, commData.signatures, relayChainCommittee[epoch])) {
            relayChainCommittee[epoch+1] = TKM.pubs2addr(commData.committee);
            endsOfEpoch[1] = epoch+1;
            lastHeight = commData.height;
            if (commData.syncingEpoch > endsOfEpoch[0]){
                uint64 stopEpoch = endsOfEpoch[1];
                if (stopEpoch > commData.syncingEpoch) {
                    stopEpoch = commData.syncingEpoch;
                }
                for (uint64 i=endsOfEpoch[0]; i < stopEpoch; i++) {
                    delete relayChainCommittee[i];
                }
                endsOfEpoch[0] = stopEpoch;
            }
            emit UpdateCommittee(epoch+1, commHash);
            return true;
        }
        revert("signatures verify failed");
    }

    function resetCommittee(uint64 epoch, bytes[] memory committee) external override onlyOwner returns (bool) {
        require(committee.length >= 4, "committee length invalid");
        for(uint64 i = endsOfEpoch[0]; i<= endsOfEpoch[1]; i++) {
            delete relayChainCommittee[i];
        }
        relayChainCommittee[epoch] = TKM.pubs2addr(committee);
        lastHeight = epoch * epochLength;
        endsOfEpoch[0] = epoch;
        endsOfEpoch[1] = epoch;
        return true;
    }

    function lastHeaderHeight() external view override returns (uint64) {
        return lastHeight;
    }

    function checkEpochCommittee(uint64 epoch) external view override returns (address[] memory) {
        require(epoch >= endsOfEpoch[0] && epoch <= endsOfEpoch[1], "epoch not available");
        return relayChainCommittee[epoch];
    }

    function checkEpochLength() external view returns (uint64) {
        return epochLength;
    }

    function togglePause(bool _flag) external onlyOwner returns (bool) {
        if (_flag) {
            _pause();
        } else {
            _unpause();
        }
        return true;
    }

    /** UUPS *********************************************************/
    function _authorizeUpgrade(address) internal view override {
        require(msg.sender == _getAdmin(), "LightNode: only Admin can upgrade");
    }

    function changeAdmin() external {
        require(_pendingAdmin == msg.sender, "only pendingAdmin");
        emit AdminTransferred(_getAdmin(), _pendingAdmin);
        _changeAdmin(_pendingAdmin);
    }

    function pendingAdmin() external view returns (address) {
        return _pendingAdmin;
    }

    function setPendingAdmin(address pendingAdmin_) external onlyOwner {
        require(
            pendingAdmin_ != address(0),
            "Ownable: pendingAdmin is the zero address"
        );
        emit ChangePendingAdmin(_pendingAdmin, pendingAdmin_);
        _pendingAdmin = pendingAdmin_;
    }

    function getAdmin() external view returns (address) {
        return _getAdmin();
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}
