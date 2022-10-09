// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

/** @title Insider interface */
interface IInsider {
    event RoomCreated(uint256 roomId, uint256 method, address insider);
    event VolunteersJoined(
        uint256 roomId,
        address volunteer,
        uint256 volunteersLength
    );
    event RoomStarted(
        uint256 roomId,
        address firstSender,
        address firstReciever,
        address secondSender,
        address secondReciever
    );
    event ReceiverHashUploaded(
        uint256 roomId,
        string ipfsHash,
        address receiver
    );
    event SenderHashUploaded(uint256 roomId, string ipfsHash, address sender);
    event ReceiverTxVerified(uint256 roomId, string ipfsHash, address receiver);

    event TxCheckedByInsider(
        uint256 roomId,
        uint256 transferIndex,
        bool checked,
        address insider
    );
    event InsiderVerified(
        uint256 roomId,
        address receiver,
        uint256 insiderScore
    );
    event InsiderRejected(uint256 roomId);

    function insiders(address _insider) external view returns (uint256);

    function checkInsiderPermission(uint256 _methods, address _insider)
        external
        view
        returns (bool);

    function isInsider() external view returns (bool);

    function createRoom(uint256 _method) external;

    function joinVolunteers(uint256 _roomId) external;

    function receiverUploadHash(uint256 _roomId, string memory _ipfsHash)
        external;

    function senderUploadHash(uint256 _roomId, string memory _ipfsHash)
        external;

    function receiverVerifyTx(uint256 _roomId, string memory _ipfsHash)
        external;

    function checkTxByInsider(
        uint256 _roomId,
        uint256 _transferIndex,
        bool _checked
    ) external;

    function verifyInsiderByReceiver(uint256 _roomId, bool _isVerified)
        external;

    function setChainLinkContract(address _address) external;

    function callFromRandom(uint256 _requestId, uint256[] memory _randomWords)
        external;
}
