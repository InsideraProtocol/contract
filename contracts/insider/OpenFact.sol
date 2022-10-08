// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../access/IAccessRestriction.sol";

import "./IInsider.sol";

contract OpenFact is Initializable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

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
        address creator;
        address[] volunteers;
        mapping(uint256 => TransferData) transfer;
        uint8 insiderScore;
    }

    mapping(uint256 => RoomData) public rooms;

    bool public isOpenFact;

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

        isOpenFact = true;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyAdmin
    {}

    function createRoom(uint256 _method) external {
        RoomData storage room = rooms[roomId.current()];

        room.method = _method;
        room.creator = msg.sender;
    }

    function joinVolunteers(uint256 _roomId) external {
        RoomData storage room = rooms[_roomId];

        require(room.status == 0, "room is full.");

        room.volunteers.push(msg.sender);

        if (room.volunteers.length == 4) {
            uint256 firstSender = uint256(
                keccak256(
                    abi.encode(
                        room.creator,
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
        }
    }
}
