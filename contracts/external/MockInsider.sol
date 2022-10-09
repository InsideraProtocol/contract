// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "../insider/Insider.sol";

contract MockInsider is Insider {
    function setMethod(address _insider, uint256 _method) external {
        insiders[_insider].method = _method;
    }
}
