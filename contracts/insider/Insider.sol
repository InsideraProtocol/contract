// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../access/IAccessRestriction.sol";

import "./IInsider.sol";

import "../chainLink/IChainLink.sol";

import "./../push/IPush.sol";

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
        uint8 status; // 0 => pending for witness join // 1 => witness must transfer to each other
        uint256 method;
        address insider;
        address[] witnesses;
        mapping(uint256 => TransferData) transfer;
        uint8 insiderScore;
    }

    mapping(address => InsiderData) public override insiders;

    mapping(uint256 => RoomData) public rooms;

    mapping(uint256 => uint256) public requestIdToRoomId;

    bool public override isInsider;
    IAccessRestriction public accessRestriction;
    IChainLink public chainLinkContract;
    CountersUpgradeable.Counter public roomId;

    modifier onlyAdmin() {
        accessRestriction.ifAdmin(msg.sender);
        _;
    }

    modifier onlyInsiderProtocolContract() {
        accessRestriction.ifInsiderProtocolContract(msg.sender);
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

    function setChainLinkContract(address _address)
        external
        override
        onlyAdmin
    {
        chainLinkContract = IChainLink(_address);
    }

    function createRoom(uint256 _method) external override {
        roomId.increment();

        RoomData storage room = rooms[roomId.current()];

        room.method = _method;
        room.insider = msg.sender;

        emit RoomCreated(roomId.current(), _method, msg.sender);
    }

    function joinWitness(uint256 _roomId) external override {
        RoomData storage room = rooms[_roomId];

        require(room.status == 0, "room is full.");

        room.witnesses.push(msg.sender);

        emit WitnessJoined(_roomId, msg.sender, room.witnesses.length);

        if (room.witnesses.length == 4) {
            room.status = 1;

            uint256 requerstId = chainLinkContract.requestRandomWords();

            requestIdToRoomId[requerstId] = _roomId;
        }
    }

    function callFromRandom(uint256 _requestId, uint256[] memory _randomWords)
        external
        override
        onlyInsiderProtocolContract
    {
        uint256 roomIdLocal = requestIdToRoomId[_requestId];

        RoomData storage room = rooms[roomIdLocal];

        require(room.status == 1, "room is full.");

        uint256 number = _randomWords[0] % 4;

        TransferData storage transferData;

        transferData = room.transfer[0];

        transferData.sender = room.witnesses[number];

        transferData.receiver = room.witnesses[(number + 1) % 4];

        IPUSHCommInterface(0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa)
            .sendNotification(
                0x2A346532cA75Be7e7227d258C477Da275dca7d67,
                transferData.receiver, //==> recipient
                bytes(
                    string(
                        abi.encodePacked(
                            "0", // this is notification identity: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
                            "+", // segregator
                            "3", // this is payload type: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/payload (1, 3 or 4) = (Broadcast, targetted or subset)
                            "+", // segregator
                            "Upload your hash", // this is notificaiton title
                            "+", // segregator
                            "Please upload your account information hash." // notification body
                        )
                    )
                )
            );

        transferData = room.transfer[1];

        transferData.sender = room.witnesses[(number + 2) % 4];

        transferData.receiver = room.witnesses[(number + 3) % 4];

        IPUSHCommInterface(0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa)
            .sendNotification(
                0x2A346532cA75Be7e7227d258C477Da275dca7d67,
                transferData.receiver,
                bytes(
                    string(
                        abi.encodePacked(
                            "0", // this is notification identity: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
                            "+", // segregator
                            "3", // this is payload type: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/payload (1, 3 or 4) = (Broadcast, targetted or subset)
                            "+", // segregator
                            "Upload your hash", // this is notificaiton title
                            "+", // segregator
                            "Please upload your account information hash." // notification body
                        )
                    )
                )
            );

        room.status = 2;

        emit RoomStarted(
            roomIdLocal,
            room.transfer[0].sender,
            room.transfer[0].receiver,
            transferData.sender,
            transferData.receiver
        );
    }

    function receiverUploadHash(uint256 _roomId, string memory _ipfsHash)
        external
        override
    {
        RoomData storage room = rooms[_roomId];

        require(room.status == 2, "room is full.");

        TransferData storage transferData;
        for (uint256 i = 0; i < 2; i++) {
            transferData = room.transfer[i];

            if (transferData.receiver == msg.sender) {
                require(transferData.status == 0, "hash already exist");

                transferData.receiverAccountHash = _ipfsHash;
                transferData.status = 1;

                IPUSHCommInterface(0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa)
                    .sendNotification(
                        0x2A346532cA75Be7e7227d258C477Da275dca7d67,
                        transferData.sender,
                        bytes(
                            string(
                                abi.encodePacked(
                                    "0", // this is notification identity: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
                                    "+", // segregator
                                    "3", // this is payload type: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/payload (1, 3 or 4) = (Broadcast, targetted or subset)
                                    "+", // segregator
                                    "Receiver hash uploaded.", // this is notificaiton title
                                    "+", // segregator
                                    "Please upload tx information hash." // notification body
                                )
                            )
                        )
                    );

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

        require(room.status == 2, "room is full.");

        TransferData storage transferData;
        for (uint256 i = 0; i < 2; i++) {
            transferData = room.transfer[i];

            if (transferData.sender == msg.sender) {
                require(transferData.status == 1, "pending to receiver");

                transferData.senderTxHash = _ipfsHash;
                transferData.status = 2;

                IPUSHCommInterface(0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa)
                    .sendNotification(
                        0x2A346532cA75Be7e7227d258C477Da275dca7d67,
                        transferData.receiver,
                        bytes(
                            string(
                                abi.encodePacked(
                                    "0", // this is notification identity: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
                                    "+", // segregator
                                    "3", // this is payload type: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/payload (1, 3 or 4) = (Broadcast, targetted or subset)
                                    "+", // segregator
                                    "Sender tx hash uploaded.", // this is notificaiton title
                                    "+", // segregator
                                    "Sender payment completed." // notification body
                                )
                            )
                        )
                    );

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

        require(room.status == 2, "room is full.");

        TransferData storage transferData;

        for (uint256 i = 0; i < 2; i++) {
            transferData = room.transfer[i];

            if (transferData.receiver == msg.sender) {
                require(transferData.status == 2, "pending to sender");

                transferData.recieverAccountHashForInsider = _ipfsHash;
                transferData.status = 3;

                IPUSHCommInterface(0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa)
                    .sendNotification(
                        0x2A346532cA75Be7e7227d258C477Da275dca7d67,
                        room.insider,
                        bytes(
                            string(
                                abi.encodePacked(
                                    "0", // this is notification identity: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
                                    "+", // segregator
                                    "3", // this is payload type: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/payload (1, 3 or 4) = (Broadcast, targetted or subset)
                                    "+", // segregator
                                    "You have new tx.", // this is notificaiton title
                                    "+", // segregator
                                    "Please submit your answser." // notification body
                                )
                            )
                        )
                    );

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

        require(room.status == 2, "room is full.");
        require(room.insider == msg.sender, "sender is not room insider");

        TransferData storage transferData = room.transfer[_transferIndex];

        require(transferData.status == 3, "not verified by receiver");

        transferData.insiderAnswer = _checked;
        transferData.status = 4;

        IPUSHCommInterface(0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa)
            .sendNotification(
                0x2A346532cA75Be7e7227d258C477Da275dca7d67,
                transferData.receiver,
                bytes(
                    string(
                        abi.encodePacked(
                            "0", // this is notification identity: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
                            "+", // segregator
                            "3", // this is payload type: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/payload (1, 3 or 4) = (Broadcast, targetted or subset)
                            "+", // segregator
                            "Insider verification.", // this is notificaiton title
                            "+", // segregator
                            "Please verify insider's answer." // notification body
                        )
                    )
                )
            );

        emit TxCheckedByInsider(_roomId, _transferIndex, _checked, msg.sender);
    }

    function verifyInsiderByReceiver(uint256 _roomId, bool _isVerified)
        external
        override
    {
        RoomData storage room = rooms[_roomId];

        require(room.status == 2, "room is full.");

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
                    room.status = 3;

                    emit InsiderRejected(_roomId);
                }
                transferData.status = 5;
                break;
            }
        }

        if (room.insiderScore == 2) {
            accessRestriction.grantInsiderRole(room.insider);

            InsiderData storage insiderData = insiders[room.insider];
            insiderData.method = room.method;

            room.status = 4;
        }
    }

    function getRoomWitnesses(uint256 _roomId, uint256 _index)
        external
        view
        returns (address)
    {
        return rooms[_roomId].witnesses[_index];
    }

    function getRoomTransferData(uint256 _roomId, uint256 _transferId)
        external
        view
        returns (TransferData memory transferData)
    {
        return rooms[_roomId].transfer[_transferId];
    }
}
