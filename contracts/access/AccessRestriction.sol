// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./IAccessRestriction.sol";

/** @title AccessRestriction contract */

contract AccessRestriction is
    AccessControlUpgradeable,
    IAccessRestriction,
    UUPSUpgradeable
{
    bytes32 public constant INSIDER_ROLE = keccak256("INSIDER_ROLE");
    bytes32 public constant INSIDER_PROTOCOL_CONTRACT_ROLE =
        keccak256("INSIDER_PROTOCOL_CONTRACT_ROLE");

    /** NOTE {isAccessRestriction} set inside the initialize to {true} */
    bool public override isAccessRestriction;

    /** NOTE modifier to check msg.sender has admin role */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller not admin");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @inheritdoc IAccessRestriction
    function initialize(address _deployer) external override initializer {
        __UUPSUpgradeable_init();

        AccessControlUpgradeable.__AccessControl_init();

        isAccessRestriction = true;

        if (!hasRole(DEFAULT_ADMIN_ROLE, _deployer)) {
            _setupRole(DEFAULT_ADMIN_ROLE, _deployer);
        }
    }

    /// @inheritdoc IAccessRestriction
    function ifInsider(address _address) external view override {
        require(isInsider(_address), "Caller not insider");
    }

    /// @inheritdoc IAccessRestriction
    function ifAdmin(address _address) external view override {
        require(isAdmin(_address), "Caller not admin");
    }

    /// @inheritdoc IAccessRestriction
    function ifInsiderProtocolContract(address _address)
        external
        view
        override
    {
        require(
            isInsiderProtocolContract(_address),
            "Caller not insider contract"
        );
    }

    /// @inheritdoc IAccessRestriction
    function isInsider(address _address) public view override returns (bool) {
        return hasRole(INSIDER_ROLE, _address);
    }

    /// @inheritdoc IAccessRestriction
    function isAdmin(address _address) public view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    /// @inheritdoc IAccessRestriction
    function isInsiderProtocolContract(address _address)
        public
        view
        override
        returns (bool)
    {
        return hasRole(INSIDER_PROTOCOL_CONTRACT_ROLE, _address);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyAdmin
    {}
}
