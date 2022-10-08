// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "../access/IAccessRestriction.sol";

import "./ISoulbound.sol";

import "./AttributeLib.sol";

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Soulbound is ERC721Upgradeable, ISoulbound, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bool public override isSoulbound;
    string public override baseURI;

    IAccessRestriction public accessRestriction;

    CountersUpgradeable.Counter private tokenId_;

    /** NOTE mapping of tokenId to attributes */
    mapping(uint256 => AttributeLib.Attribute) public override attributes;

    /** NOTE modifier to check msg.sender has admin role */
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

    /// @inheritdoc ISoulbound
    function initialize(
        address _accessRestrictionAddress,
        string calldata baseURI_
    ) public override initializer {
        isSoulbound = true;

        __UUPSUpgradeable_init();

        __ERC721_init("Soulbound contract", "SoulBound");

        baseURI = baseURI_;

        IAccessRestriction candidateContract = IAccessRestriction(
            _accessRestrictionAddress
        );
        require(candidateContract.isAccessRestriction());
        accessRestriction = candidateContract;
    }

    /// @inheritdoc ISoulbound
    function setBaseURI(string calldata baseURI_) external override onlyAdmin {
        baseURI = baseURI_;
    }

    /// @inheritdoc ISoulbound
    function mint(AttributeLib.Attribute memory _attr, address _to)
        external
        override
        onlyInsiderProtocolContract
    {
        uint256 tokenId = tokenId_.current();

        _mint(_to, tokenId);

        attributes[tokenId] = _attr;

        tokenId_.increment();
    }

    /// @inheritdoc ISoulbound
    function exists(uint256 _tokenId) external view override returns (bool) {
        return _exists(_tokenId);
    }

    /** @return return baseURI */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(
            from == address(0),
            "NonTransferrableERC721Token: non transferrable"
        );
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyAdmin
    {}
}
