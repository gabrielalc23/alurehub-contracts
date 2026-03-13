// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Types } from "src/libraries/Types.sol";

interface ISubscriptionManager {
    function createPlan(
        uint96 price,
        address paymentToken,
        uint32 duration
    ) external returns (uint256 planId);

    function updatePlanPrice(
        uint256 planId,
        uint96 newPrice
    ) external;

    function setPlanStatus(
        uint256 planId,
        bool active
    ) external;

    function subscribe(
        uint256 planId
    ) external payable returns (uint256 expiresAt);

    function renewSubscription(
        uint256 planId
    ) external payable returns (uint256 expiresAt);

    function planExists(
        uint256 planId
    ) external view returns (bool);

    function getPlan(
        uint256 planId
    ) external view returns (Types.SubscriptionPlan memory);

    function getCreatorPlanIds(
        address creator
    ) external view returns (uint256[] memory);

    function getSubscription(
        uint256 planId,
        address subscriber
    ) external view returns (Types.SubscriptionRecord memory);

    function getSubscriptionExpiry(
        uint256 planId,
        address subscriber
    ) external view returns (uint256);

    function creatorAccessExpiry(
        address creator,
        address subscriber
    ) external view returns (uint256);

    function hasActiveSubscription(
        uint256 planId,
        address subscriber
    ) external view returns (bool);

    function hasActiveAccess(
        address creator,
        address subscriber
    ) external view returns (bool);
}
