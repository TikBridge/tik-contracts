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
    mapping(uint64 => address[]) public mainChainCommittee;
    // main chain latest block header
    uint64 public lastHeight;
    // TKM.BlockHeader public lastMainHeader;
    uint64[2] public latest2Epoch;

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
        bytes[] memory _nextCommittee
        )
    external
    override
    initializer {
        require(_currentHeight > 0, "Error ln initializing current height");
        require(_currentCommittee.length >= 4, "Error ln initializing current committee");

        _changeAdmin(tx.origin);

        uint64 _currentEpoch = _currentHeight / TKM.EPOCH_LENGTH;
        mainChainCommittee[_currentEpoch] = TKM.pubs2addr(_currentCommittee);
        latest2Epoch[1] = _currentEpoch;
        if (_nextCommittee.length >= 4) {
            mainChainCommittee[_currentEpoch+1] = TKM.pubs2addr(_nextCommittee);
            latest2Epoch[0] = _currentEpoch;
            latest2Epoch[1] = _currentEpoch+1;
        }

        lastHeight = _currentHeight;

        emit initializeCommittee(_currentEpoch, _currentCommittee);
    }

    function verifyProofData(bytes memory proofBytes)
    external
    view
    override
    returns (bool success, string memory message, bytes memory logBytes) {
        TKM.ReceiptProof memory receiptProof = abi.decode(proofBytes, (TKM.ReceiptProof));
        uint64 epoch = TKM.epochNum(receiptProof.h.Height);
        if (epoch != latest2Epoch[0] && epoch != latest2Epoch[1]) {
            message = "ln epoch invalid";
        } else {
            bytes32 headerHash = TKM.hashBlockHeader(receiptProof.h);
            success = TKM.verifyHeaderSignature(headerHash, receiptProof.s, mainChainCommittee[epoch]);
            if (success) {
                if (receiptProof.r.Version<2) {
                    bytes32 proofRoot = MPT.VerifyProofs(TKM.hashReceipt(receiptProof.r), receiptProof.p);
                    success = (proofRoot == headerHash ||
                        proofRoot == Util._32b2b32(receiptProof.h.HashHistory) ||
                        proofRoot == Util._32b2b32(receiptProof.h.ConfirmedRoot));
                    if (success) {
                        logBytes = TKM.encodeReceiptLogs(receiptProof.r);
                    } else {
                        message = "ln proof verify failed";
                    }
                } else {
                    (bytes memory oneLogBytes, bytes32 rcptHash) = TKM.hashReceiptV2(receiptProof);
                    bytes32 proofRoot = MPT.VerifyProofs(rcptHash, receiptProof.p);
                    success = (proofRoot == headerHash ||
                        proofRoot == Util._32b2b32(receiptProof.h.HashHistory) ||
                        proofRoot == Util._32b2b32(receiptProof.h.ConfirmedRoot));
                    if (success) {
                        bytes[] memory listLog = new bytes[](1);
                        listLog[0] = oneLogBytes;
                        logBytes = RLPEncode.encodeList(listLog);
                    } else {
                        message = "ln proof v2 verify failed";
                    }
                }
            } else {
                message = "ln signature verify failed";
            }
        }
    }

    function updateCommittee(bytes memory _epochCommittee) external override whenNotPaused returns (bool){
        TKM.CommitteeProof memory commProof = abi.decode(_epochCommittee, (TKM.CommitteeProof));
        require(commProof.header.Height > lastHeight, "only update future epoch comm");
        uint64 epoch = TKM.epochNum(commProof.header.Height);
        require(epoch == latest2Epoch[1], "ln only update next epoch comm");
        bytes32 headerHash = TKM.hashBlockHeader(commProof.header);
        if (TKM.verifyHeaderSignature(headerHash, commProof.signatures, mainChainCommittee[epoch])) {
            bytes32 commHash = TKM.hashCommittee(commProof.committee);
            if (commHash == Util._32b2b32(commProof.header.ElectedNextRoot)) {
                mainChainCommittee[epoch+1] = TKM.pubs2addr(commProof.committee);
                delete mainChainCommittee[epoch-1];
                latest2Epoch[0] = epoch;
                latest2Epoch[1] = epoch+1;
                lastHeight = commProof.header.Height;

                emit UpdateBlockHeader(msg.sender, lastHeight);
                emit UpdateCommittee(epoch+1, commHash);
                return true;
            }
            revert("ln comm hash miss match");
        }
        revert("ln signatures verify failed");
    }

    function resetCommittee(bytes memory epochCommittee) external pure override returns (bool) {
        require(epochCommittee.length > 0, "param should be not nil");
        return false;
    }

    function lastHeaderHeight() external view override returns (uint64) {
        return lastHeight;
    }

    function checkEpochCommittee(uint64 epoch) external view override returns (address[] memory) {
        require(epoch == latest2Epoch[0] || epoch == latest2Epoch[1], "ln epoch not available");
        return mainChainCommittee[epoch];
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
