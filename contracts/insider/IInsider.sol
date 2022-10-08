// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

/** @title Insider interface */
interface IInsider {
    event InsiderAdded(address insider, uint256 region, uint256 methods);

    function joinInsider(
        uint256 _region,
        uint256 _methods,
        address _insider
    ) external;

    function insiders(address _insider)
        external
        view
        returns (uint256, uint256);

    function checkInsiderPermission(
        uint256 _region,
        uint256 _methods,
        address _insider
    ) external view returns (bool);

    function isInsider() external view returns (bool);
}
