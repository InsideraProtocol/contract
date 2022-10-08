// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/** @title AccessRestriction interface*/

interface IAccessRestriction is IAccessControlUpgradeable {
    function initialize(address _deployer) external;

    /** @return true if AccessRestriction contract has been initialized  */
    function isAccessRestriction() external view returns (bool);

    function ifInsider(address _address) external view;

    function isInsider(address _address) external view returns (bool);

    function ifAdmin(address _address) external view;

    function isAdmin(address _address) external view returns (bool);

    function ifInsiderProtocolContract(address _address) external view;

    function isInsiderProtocolContract(address _address)
        external
        view
        returns (bool);
}
