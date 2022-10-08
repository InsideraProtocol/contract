// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "./AttributeLib.sol";

interface ISoulbound is IERC721Upgradeable {
    /**
     * @dev initialize AccessRestriction contract, baseURI and set true for isTree
     * @param _accessRestrictionAddress set to the address of AccessRestriction contract
     * @param baseURI_ initial baseURI
     */
    function initialize(
        address _accessRestrictionAddress,
        string calldata baseURI_
    ) external;

    /** @dev admin set {baseURI_} to baseURI */
    function setBaseURI(string calldata baseURI_) external;

    /**
     * @dev mint {_tokenId} to {_to}
     */
    function mint(AttributeLib.Attribute memory _attr, address _to) external;

    /**
     * @return true in case of Tree contract have been initialized
     */
    function isSoulbound() external view returns (bool);

    function baseURI() external view returns (string memory);

    function attributes(uint256 _tokenId)
        external
        view
        returns (uint256 courtId, AttributeLib.TypeEnums status);

    /**
     * @dev check that _tokenId exist or not
     * @param _tokenId id of token to check existance
     * @return true if {_tokenId} exist
     */
    function exists(uint256 _tokenId) external view returns (bool);
}
