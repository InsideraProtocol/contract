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
        uint256 methods;
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

    function initialize() public initializer {
        __UUPSUpgradeable_init();

        isInsider = true;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyAdmin
    {}

    function joinInsider(
        uint256 _region,
        uint256 _methods,
        address _insider
    ) external override onlyAdmin {
        insiders[_insider] = InsiderData(_region, _methods);
    }

    function checkInsiderPermission(
        uint256 _region,
        uint256 _methods,
        address _insider
    ) external view override returns (bool) {
        InsiderData storage insider = insiders[_insider];

        if (
            accessRestriction.isInsider(_insider) &&
            _region == insider.region &&
            _methods == insider.methods
        ) {
            return true;
        }

        return false;
    }
}
