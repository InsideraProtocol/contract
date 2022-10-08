// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "./ICourt.sol";

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../insider/IInsider.sol";
import "../soulbond/ISoulbound.sol";
import "../soulbond/AttributeLib.sol";

import "../access/IAccessRestriction.sol";

/** @title Court Contract */
contract Court is UUPSUpgradeable, ICourt {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct CourtData {
        address address1; //===> onchain payment
        address address2; //===> offchain payment
        uint256 region;
        uint256 method;
        uint256 coinPrice;
        uint256 address1VoteCount;
        uint256 address2VoteCount;
        uint256 duration;
        uint256 createdAt;
        uint8 status; // 1->created 2->settled
        string ipfsData; // encrypt data;
    }

    mapping(uint256 => CourtData) public override courts;

    mapping(uint256 => mapping(address => uint256))
        public
        override stakedAmount; // courtId => user => amount

    mapping(uint256 => mapping(address => uint8)) public override voters; // courtId => insider => status //status=1 -> guardian status=2->insider

    mapping(uint256 => address[]) public voterListPerCourt;

    mapping(address => int256) public voterScore;

    bool public override isCourt;
    address public override governanceToken;

    IInsider public insiderContract;
    ISoulbound public soulboundContract;
    IAccessRestriction public accessRestriction;

    CountersUpgradeable.Counter public courtId;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /** NOTE modifier to check msg.sender has admin role */
    modifier onlyAdmin() {
        accessRestriction.ifAdmin(msg.sender);
        _;
    }

    function initialize(address _accessRestrictionAddress)
        public
        override
        initializer
    {
        __UUPSUpgradeable_init();

        IAccessRestriction candidateContract = IAccessRestriction(
            _accessRestrictionAddress
        );
        require(candidateContract.isAccessRestriction());
        accessRestriction = candidateContract;

        isCourt = true;
    }

    modifier validCourt(uint256 _courtId) {
        require(_courtId > 0 && _courtId < courtId.current(), "Invalid court");

        _;
    }

    function setGovernanceToken(address _token) external override onlyAdmin {
        governanceToken = _token;

        emit GovernanceTokenSet(_token);
    }

    function setInsiderContract(address _address) external override {
        IInsider candidateContract = IInsider(_address);
        require(candidateContract.isInsider());
        insiderContract = candidateContract;
    }

    function setSoulboundContract(address _address) external override {
        ISoulbound candidateContract = ISoulbound(_address);
        require(candidateContract.isSoulbound());
        soulboundContract = candidateContract;
    }

    function createCourt(
        address _address1,
        address _address2,
        uint256 _region,
        uint256 _method,
        uint256 _coinPrice,
        uint256 _duration,
        string calldata _ipfsData
    ) external override {
        courtId.increment();

        CourtData storage courtData = courts[courtId.current()];

        courtData.address1 = _address1;
        courtData.address2 = _address2;
        courtData.region = _region;
        courtData.method = _method;
        courtData.coinPrice = _coinPrice;
        courtData.duration = _duration;
        courtData.ipfsData = _ipfsData;
        courtData.createdAt = block.timestamp;
        courtData.status = 1;

        emit CourtCreated(
            _address1,
            _address2,
            _region,
            _method,
            _coinPrice,
            _duration,
            _ipfsData,
            block.timestamp
        );
    }

    function stake(uint256 _courtId, uint256 _stakeAmount)
        external
        override
        validCourt(_courtId)
    {
        CourtData storage courtData = courts[_courtId];

        require(
            block.timestamp < courtData.createdAt + courtData.duration,
            "Court ended"
        );

        require(
            _stakeAmount >= 10 * courtData.coinPrice,
            "Insufficient stakeAmount"
        );

        require(stakedAmount[_courtId][msg.sender] == 0, "already staked");

        require(voters[_courtId][msg.sender] == 0, "already voted");

        bool success = IERC20Upgradeable(governanceToken).transferFrom(
            msg.sender,
            address(this),
            _stakeAmount
        );

        require(success, "Unsuccessful transfer.");

        stakedAmount[_courtId][msg.sender] = _stakeAmount;

        emit Staked(_courtId, _stakeAmount, msg.sender);
    }

    function voteGuardian(uint256 _courtId, uint8 _vote)
        external
        override
        validCourt(_courtId)
    {
        require(_vote < 2, "invalid vote value");

        CourtData storage courtData = courts[_courtId];

        require(voters[_courtId][msg.sender] == 0, "already voted.");
        require(stakedAmount[_courtId][msg.sender] > 0, "not staked");

        _vote == 0
            ? courtData.address1VoteCount += 1
            : courtData.address2VoteCount += 1;

        voters[_courtId][msg.sender] = 1;

        voterListPerCourt[_courtId].push(msg.sender);

        emit GuardianVoted(_courtId, _vote, msg.sender);
    }

    function voteInsider(uint256 _courtId, uint8 _vote)
        external
        override
        validCourt(_courtId)
    {
        require(voters[_courtId][msg.sender] == 0, "already voted.");

        require(_vote < 2, "invalid vote value");

        CourtData storage courtData = courts[_courtId];

        require(
            insiderContract.checkInsiderPermission(
                courtData.region,
                courtData.method,
                msg.sender
            ),
            "Invalid Insider"
        );

        _vote == 0
            ? courtData.address1VoteCount += 1
            : courtData.address2VoteCount += 1;

        voters[_courtId][msg.sender] = 2;

        voterListPerCourt[_courtId].push(msg.sender);

        emit InsiderVoted(_courtId, _vote, msg.sender);
    }

    function settleCourt(uint256 _courtId)
        external
        override
        validCourt(_courtId)
    {
        CourtData storage courtData = courts[_courtId];

        require(
            block.timestamp > courtData.createdAt + courtData.duration,
            "Court not ended"
        );

        require(courtData.status == 1, "court settled");

        if (courtData.address1VoteCount == courtData.address2VoteCount) {
            courtData.status = 2;
            emit CourtUnSettled(_courtId);
        } else {
            AttributeLib.Attribute memory winnerAttribute = AttributeLib
                .Attribute(_courtId, AttributeLib.TypeEnums.WINNER);

            AttributeLib.Attribute memory loserAttribute = AttributeLib
                .Attribute(_courtId, AttributeLib.TypeEnums.LOSER);

            courtData.status = 3;

            if (courtData.address1VoteCount > courtData.address2VoteCount) {
                soulboundContract.mint(winnerAttribute, courtData.address1);
                soulboundContract.mint(loserAttribute, courtData.address2);

                for (
                    uint256 i = 0;
                    i < voterListPerCourt[_courtId].length;
                    i++
                ) {
                    if (voters[_courtId][voterListPerCourt[_courtId][i]] == 0) {
                        voterScore[voterListPerCourt[_courtId][i]] += 1;
                    } else {
                        voterScore[voterListPerCourt[_courtId][i]] -= 1;
                    }
                }

                emit CourtSettled(
                    _courtId,
                    courtData.address1,
                    courtData.address2
                );
            } else {
                soulboundContract.mint(winnerAttribute, courtData.address2);
                soulboundContract.mint(loserAttribute, courtData.address1);

                for (
                    uint256 i = 0;
                    i < voterListPerCourt[_courtId].length;
                    i++
                ) {
                    if (voters[_courtId][voterListPerCourt[_courtId][i]] == 1) {
                        voterScore[voterListPerCourt[_courtId][i]] += 1;
                    } else {
                        voterScore[voterListPerCourt[_courtId][i]] -= 1;
                    }
                }

                emit CourtSettled(
                    _courtId,
                    courtData.address2,
                    courtData.address1
                );
            }
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyAdmin
    {}
}
