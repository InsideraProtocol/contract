// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

/** @title Court interface */
interface ICourt {
    event GovernanceTokenSet(address token);
    event CourtCreated(
        address _address1,
        address _address2,
        uint256 region,
        uint256 method,
        uint256 coinPrice,
        uint256 duration,
        string ipfsData,
        uint256 createdAt
    );
    event Staked(uint256 courtId, uint256 stakeAmount, address staker);
    event GuardianVoted(uint256 courtId, uint8 vote, address voter);
    event InsiderVoted(uint256 courtId, uint8 vote, address voter);
    event CourtSettled(uint256 courtId, address winner, address loser);
    event CourtUnSettled(uint256 courtId);

    function initialize() external;

    function setGovernanceToken(address _token) external;

    function setInsiderContract(address _address) external;

    function setSoulboundContract(address _address) external;

    function createCourt(
        address _address1,
        address _address2,
        uint256 _region,
        uint256 _method,
        uint256 _coinPrice,
        uint256 _duration,
        string calldata _ipfsData
    ) external;

    function stake(uint256 _courtId, uint256 _stakeAmount) external;

    function voteGuardian(uint256 _courtId, uint8 _vote) external;

    function voteInsider(uint256 _courtId, uint8 _vote) external;

    function settleCourt(uint256 _courtId) external;

    function isCourt() external view returns (bool);

    function governanceToken() external view returns (address);

    function courts(uint256 courtId)
        external
        view
        returns (
            address address1,
            address address2,
            uint256 region,
            uint256 method,
            uint256 coinPrice,
            uint256 address1VoteCount,
            uint256 address2VoteCount,
            uint256 duration,
            uint256 createdAt,
            uint8 status,
            string calldata ipfsData
        );

    function stakedAmount(uint256 courtId, address guardian)
        external
        view
        returns (uint256 stakedAmount);

    function voters(uint256 courtId, address voter)
        external
        view
        returns (uint8 status);
}
