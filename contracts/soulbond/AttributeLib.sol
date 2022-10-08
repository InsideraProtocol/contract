// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

library AttributeLib {
    enum TypeEnums {
        WINNER,
        LOSER
    }

    struct Attribute {
        uint256 courtId;
        TypeEnums status;
    }
}
