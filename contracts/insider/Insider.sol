// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../access/IAccessRestriction.sol";

import "./IInsider.sol";

contract Insider is IInsider, Initializable, UUPSUpgradeable {
    struct InsiderData {
        uint256 region;
        uint256 method;
    }

    mapping(address => InsiderData) public override insiders;

    bool public override isInsider;
    IAccessRestriction public accessRestriction;

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

    function joinInsider(
        uint256 _region,
        uint256 _method,
        address _insider
    ) external override onlyAdmin {
        insiders[_insider] = InsiderData(_region, _method);

        emit InsiderJoined(_insider, _region, _method);
    }

    function checkInsiderPermission(
        uint256 _region,
        uint256 _method,
        address _insider
    ) external view override returns (bool) {
        InsiderData storage insider = insiders[_insider];

        if (
            accessRestriction.isInsider(_insider) &&
            _region == insider.region &&
            _method == insider.method
        ) {
            return true;
        }

        return false;
    }
}
