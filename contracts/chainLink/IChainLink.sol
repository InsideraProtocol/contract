// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

/** @title Insider interface */
interface IChainLink {
    function requestRandomWords() external returns (uint256 requestId);
}
