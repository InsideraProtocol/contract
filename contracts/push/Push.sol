// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "./IPush.sol";

contract Push {
    function pu() external {
        IPUSHCommInterface(0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa)
            .sendNotification(
                0x2A346532cA75Be7e7227d258C477Da275dca7d67,
                0x2A346532cA75Be7e7227d258C477Da275dca7d67,
                bytes(
                    string(
                        // We are passing identity here: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
                        abi.encodePacked(
                            "0", // this is notification identity: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
                            "+", // segregator
                            "3", // this is payload type: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/payload (1, 3 or 4) = (Broadcast, targetted or subset)
                            "+", // segregator
                            "Title", // this is notificaiton title
                            "+", // segregator
                            "Please submuit" // notification body
                        )
                    )
                )
            );
    }
}
