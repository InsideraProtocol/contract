// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../access/IAccessRestriction.sol";

import "./IInsider.sol";

contract Insider is IInsider, Initializable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct InsiderData {
        uint256 method;
    }

    struct TransferData {
        address sender;
        address receiver;
        uint8 status; // 0-> pending for recieiver upload hash 1-> receiver uploaded hash
        string receiverAccountHash;
        string senderTxHash;
        string recieverAccountHashForInsider;
        bool insiderAnswer;
    }

    struct RoomData {
        uint8 status; // 0 => pending for volunteers join // 1 => volunteers must transfer to each other
        uint256 method;
        address insider;
        address[] volunteers;
        mapping(uint256 => TransferData) transfer;
        uint8 insiderScore;
    }

    mapping(address => InsiderData) public override insiders;

    mapping(uint256 => RoomData) public rooms;

    bool public override isInsider;
    IAccessRestriction public accessRestriction;
    CountersUpgradeable.Counter public roomId;

    modifier onlyAdmin() {
        accessRestriction.ifAdmin(msg.sender);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _accessRestrictionAddress) public initializer {
        __UUPSUpgradeable_init();

        IAccessRestriction candidateContract = IAccessRestriction(
            _accessRestrictionAddress
        );
        require(candidateContract.isAccessRestriction());
        accessRestriction = candidateContract;

        isInsider = true;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyAdmin
    {}

    function checkInsiderPermission(uint256 _method, address _insider)
        external
        view
        override
        returns (bool)
    {
        InsiderData storage insider = insiders[_insider];

        if (
            accessRestriction.isInsider(_insider) && _method == insider.method
        ) {
            return true;
        }

        return false;
    }

    function createRoom(uint256 _method) external override {
        roomId.increment();

        RoomData storage room = rooms[roomId.current()];

        room.method = _method;
        room.insider = msg.sender;

        emit RoomCreated(roomId.current(), _method, msg.sender);
    }

    function joinVolunteers(uint256 _roomId) external override {
        RoomData storage room = rooms[_roomId];

        require(room.status == 0, "room is full.");

        room.volunteers.push(msg.sender);

        emit VolunteersJoined(_roomId, msg.sender, room.volunteers.length);

        if (room.volunteers.length == 4) {
            uint256 firstSender = uint256(
                keccak256(
                    abi.encode(
                        room.insider,
                        room.volunteers[0],
                        room.volunteers[1],
                        room.volunteers[2],
                        room.volunteers[3]
                    )
                )
            ) % 4;

            TransferData storage transferData;

            transferData = room.transfer[0];

            transferData.sender = room.volunteers[firstSender];

            transferData.receiver = room.volunteers[(firstSender + 1) % 4];

            transferData = room.transfer[1];

            transferData.sender = room.volunteers[(firstSender + 2) % 4];

            transferData.receiver = room.volunteers[(firstSender + 3) % 4];

            room.status = 1;

            emit RoomStarted(
                _roomId,
                room.transfer[0].sender,
                room.transfer[0].receiver,
                transferData.sender,
                transferData.receiver
            );
        }
    }

    function receiverUploadHash(uint256 _roomId, string memory _ipfsHash)
        external
        override
    {
        RoomData storage room = rooms[_roomId];

        require(room.status == 1, "room is full.");

        TransferData storage transferData;
        for (uint256 i = 0; i < 2; i++) {
            transferData = room.transfer[i];

            if (transferData.receiver == msg.sender) {
                require(transferData.status == 0, "hash already exist");

                transferData.receiverAccountHash = _ipfsHash;
                transferData.status = 1;

                emit ReceiverHashUploaded(_roomId, _ipfsHash, msg.sender);

                break;
            }
        }
    }

    function senderUploadHash(uint256 _roomId, string memory _ipfsHash)
        external
        override
    {
        RoomData storage room = rooms[_roomId];

        require(room.status == 1, "room is full.");

        TransferData storage transferData;
        for (uint256 i = 0; i < 2; i++) {
            transferData = room.transfer[i];

            if (transferData.sender == msg.sender) {
                require(transferData.status == 1, "pending to receiver");

                transferData.senderTxHash = _ipfsHash;
                transferData.status = 2;
                emit SenderHashUploaded(_roomId, _ipfsHash, msg.sender);
                break;
            }
        }
    }

    function receiverVerifyTx(uint256 _roomId, string memory _ipfsHash)
        external
        override
    {
        RoomData storage room = rooms[_roomId];

        require(room.status == 1, "room is full.");

        TransferData storage transferData;

        for (uint256 i = 0; i < 2; i++) {
            transferData = room.transfer[i];

            if (transferData.receiver == msg.sender) {
                require(transferData.status == 2, "pending to sender");

                transferData.recieverAccountHashForInsider = _ipfsHash;
                transferData.status = 3;

                emit ReceiverTxVerified(_roomId, _ipfsHash, msg.sender);
                break;
            }
        }
    }

    function checkTxByInsider(
        uint256 _roomId,
        uint256 _transferIndex,
        bool _checked
    ) external override {
        RoomData storage room = rooms[_roomId];

        require(room.status == 1, "room is full.");
        require(room.insider == msg.sender, "sender is not room insider");

        TransferData storage transferData = room.transfer[_transferIndex];

        require(transferData.status == 3, "not verified by receiver");

        transferData.insiderAnswer = _checked;
        transferData.status = 4;
        emit TxCheckedByInsider(_roomId, _transferIndex, _checked, msg.sender);
    }

    function verifyInsiderByReceiver(uint256 _roomId, bool _isVerified)
        external
        override
    {
        RoomData storage room = rooms[_roomId];

        require(room.status == 1, "room is full.");

        TransferData storage transferData;

        for (uint256 i = 0; i < 2; i++) {
            transferData = room.transfer[i];

            if (transferData.receiver == msg.sender) {
                require(transferData.status == 4, "pending to insider");
                if (_isVerified) {
                    room.insiderScore += 1;

                    emit InsiderVerified(
                        _roomId,
                        msg.sender,
                        room.insiderScore
                    );
                } else {
                    room.status = 2;

                    emit InsiderRejected(_roomId);
                }
                transferData.status = 5;
                break;
            }
        }

        if (room.insiderScore == 2) {
            accessRestriction.grantInsiderRole(room.insider);
            room.status = 3;
        }
    }

    function getRoomVolunteers(uint256 _roomId, uint256 _index)
        external
        view
        returns (address)
    {
        return rooms[_roomId].volunteers[_index];
    }

    function getRoomTransferData(uint256 _roomId, uint256 _transferId)
        external
        view
        returns (TransferData memory transferData)
    {
        return rooms[_roomId].transfer[_transferId];
    }
}
