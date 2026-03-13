// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { IContentAccess } from "src/interfaces/IContentAccess.sol";
import { ICreatorRegistry } from "src/interfaces/ICreatorRegistry.sol";
import { ISubscriptionManager } from "src/interfaces/ISubscriptionManager.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Types } from "src/libraries/Types.sol";

/// @title ContentAccess
/// @notice Thin view layer for backend/frontend checks against subscription and creator availability state.
contract ContentAccess is IContentAccess {
    ICreatorRegistry public immutable creatorRegistry;
    ISubscriptionManager public immutable subscriptionManager;

    constructor(
        address creatorRegistry_,
        address subscriptionManager_
    ) {
        if (creatorRegistry_ == address(0) || subscriptionManager_ == address(0)) {
            revert Errors.ZeroAddress();
        }

        creatorRegistry = ICreatorRegistry(creatorRegistry_);
        subscriptionManager = ISubscriptionManager(subscriptionManager_);
    }

    /// @inheritdoc IContentAccess
    function hasCreatorAccess(
        address creator,
        address subscriber
    ) external view returns (bool) {
        return creatorRegistry.isCreatorActive(creator)
            && subscriptionManager.hasActiveAccess(creator, subscriber);
    }

    /// @inheritdoc IContentAccess
    function hasPlanAccess(
        uint256 planId,
        address subscriber
    ) external view returns (bool) {
        if (!subscriptionManager.planExists(planId)) return false;

        Types.SubscriptionPlan memory plan = subscriptionManager.getPlan(planId);
        return creatorRegistry.isCreatorActive(plan.creator)
            && subscriptionManager.hasActiveSubscription(planId, subscriber);
    }

    /// @inheritdoc IContentAccess
    function getCreatorAccessExpiry(
        address creator,
        address subscriber
    ) external view returns (uint256) {
        return subscriptionManager.creatorAccessExpiry(creator, subscriber);
    }

    /// @inheritdoc IContentAccess
    function getPlanAccessExpiry(
        uint256 planId,
        address subscriber
    ) external view returns (uint256) {
        return subscriptionManager.getSubscriptionExpiry(planId, subscriber);
    }

    /// @inheritdoc IContentAccess
    function getAccessState(
        uint256 planId,
        address subscriber
    ) external view returns (Types.AccessState memory state) {
        if (!subscriptionManager.planExists(planId)) {
            return state;
        }

        Types.SubscriptionPlan memory plan = subscriptionManager.getPlan(planId);
        uint256 creatorExpiry = subscriptionManager.creatorAccessExpiry(plan.creator, subscriber);
        uint256 planExpiry = subscriptionManager.getSubscriptionExpiry(planId, subscriber);
        bool creatorActive = creatorRegistry.isCreatorActive(plan.creator);

        state = Types.AccessState({
            creatorHasAccess: creatorActive && creatorExpiry > block.timestamp,
            planHasAccess: creatorActive && planExpiry > block.timestamp,
            creatorAccessExpiry: creatorExpiry,
            planAccessExpiry: planExpiry
        });
    }
}
