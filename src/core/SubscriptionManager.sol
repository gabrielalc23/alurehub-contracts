// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { ICreatorRegistry } from "src/interfaces/ICreatorRegistry.sol";
import { IPaymentRouter } from "src/interfaces/IPaymentRouter.sol";
import { ISubscriptionManager } from "src/interfaces/ISubscriptionManager.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { Types } from "src/libraries/Types.sol";

/// @title SubscriptionManager
/// @notice Owns plan lifecycle and subscription state while delegating payment settlement to PaymentRouter.
contract SubscriptionManager is ISubscriptionManager, Ownable2Step, Pausable, ReentrancyGuard {
    ICreatorRegistry public immutable creatorRegistry;
    IPaymentRouter public immutable paymentRouter;

    uint256 private _nextPlanId = 1;

    mapping(uint256 planId => Types.SubscriptionPlan plan) private _plans;
    mapping(address creator => uint256[] planIds) private _creatorPlanIds;
    mapping(
        uint256 planId => mapping(address subscriber => Types.SubscriptionRecord subscription)
    ) private _subscriptions;
    mapping(address creator => mapping(address subscriber => uint64 expiresAt)) private
        _creatorAccessExpiries;

    constructor(
        address initialOwner,
        address creatorRegistry_,
        address paymentRouter_
    ) Ownable(initialOwner) {
        if (
            initialOwner == address(0) || creatorRegistry_ == address(0)
                || paymentRouter_ == address(0)
        ) {
            revert Errors.ZeroAddress();
        }

        creatorRegistry = ICreatorRegistry(creatorRegistry_);
        paymentRouter = IPaymentRouter(paymentRouter_);
    }

    /// @notice Pauses subscribe and renew entrypoints during emergencies.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Re-enables subscribe and renew entrypoints after an emergency is resolved.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @inheritdoc ISubscriptionManager
    function createPlan(
        uint96 price,
        address paymentToken,
        uint32 duration
    ) external returns (uint256 planId) {
        if (!creatorRegistry.isCreatorActive(msg.sender)) {
            revert Errors.CreatorInactive(msg.sender);
        }
        if (price == 0) revert Errors.InvalidAmount();
        if (duration == 0) revert Errors.InvalidDuration();
        if (paymentToken != address(0) && paymentToken.code.length == 0) {
            revert Errors.InvalidPaymentToken(paymentToken);
        }

        planId = _nextPlanId;
        unchecked {
            ++_nextPlanId;
        }

        uint64 timestamp = uint64(block.timestamp);
        _plans[planId] = Types.SubscriptionPlan({
            creator: msg.sender,
            paymentToken: paymentToken,
            price: price,
            duration: duration,
            active: true,
            createdAt: timestamp,
            updatedAt: timestamp
        });
        _creatorPlanIds[msg.sender].push(planId);

        emit Events.PlanCreated(planId, msg.sender, paymentToken, price, duration);
    }

    /// @inheritdoc ISubscriptionManager
    function updatePlanPrice(
        uint256 planId,
        uint96 newPrice
    ) external {
        if (newPrice == 0) revert Errors.InvalidAmount();

        Types.SubscriptionPlan storage plan = _requireCreatorPlan(planId, msg.sender);
        uint96 previousPrice = plan.price;

        plan.price = newPrice;
        plan.updatedAt = uint64(block.timestamp);

        emit Events.PlanPriceUpdated(planId, previousPrice, newPrice);
    }

    /// @inheritdoc ISubscriptionManager
    function setPlanStatus(
        uint256 planId,
        bool active
    ) external {
        Types.SubscriptionPlan storage plan = _requireCreatorPlan(planId, msg.sender);

        plan.active = active;
        plan.updatedAt = uint64(block.timestamp);

        emit Events.PlanStatusUpdated(planId, active);
    }

    /// @inheritdoc ISubscriptionManager
    function subscribe(
        uint256 planId
    ) external payable whenNotPaused nonReentrant returns (uint256 expiresAt) {
        Types.SubscriptionRecord storage existingSubscription = _subscriptions[planId][msg.sender];
        if (existingSubscription.expiresAt > block.timestamp) {
            revert Errors.SubscriptionAlreadyActive(
                planId, msg.sender, existingSubscription.expiresAt
            );
        }

        expiresAt = _purchase(planId, false);
    }

    /// @inheritdoc ISubscriptionManager
    function renewSubscription(
        uint256 planId
    ) external payable whenNotPaused nonReentrant returns (uint256 expiresAt) {
        if (_subscriptions[planId][msg.sender].startedAt == 0) {
            revert Errors.SubscriptionNotFound(planId, msg.sender);
        }

        expiresAt = _purchase(planId, true);
    }

    /// @inheritdoc ISubscriptionManager
    function planExists(
        uint256 planId
    ) external view returns (bool) {
        return _planExists(planId);
    }

    /// @inheritdoc ISubscriptionManager
    function getPlan(
        uint256 planId
    ) external view returns (Types.SubscriptionPlan memory plan) {
        Types.SubscriptionPlan storage storedPlan = _requireExistingPlan(planId);
        plan = storedPlan;
    }

    /// @inheritdoc ISubscriptionManager
    function getCreatorPlanIds(
        address creator
    ) external view returns (uint256[] memory) {
        return _creatorPlanIds[creator];
    }

    /// @inheritdoc ISubscriptionManager
    function getSubscription(
        uint256 planId,
        address subscriber
    ) external view returns (Types.SubscriptionRecord memory subscription) {
        subscription = _subscriptions[planId][subscriber];
    }

    /// @inheritdoc ISubscriptionManager
    function getSubscriptionExpiry(
        uint256 planId,
        address subscriber
    ) external view returns (uint256) {
        return _subscriptions[planId][subscriber].expiresAt;
    }

    /// @inheritdoc ISubscriptionManager
    function creatorAccessExpiry(
        address creator,
        address subscriber
    ) external view returns (uint256) {
        return _creatorAccessExpiries[creator][subscriber];
    }

    /// @inheritdoc ISubscriptionManager
    function hasActiveSubscription(
        uint256 planId,
        address subscriber
    ) external view returns (bool) {
        return _subscriptions[planId][subscriber].expiresAt > block.timestamp;
    }

    /// @inheritdoc ISubscriptionManager
    function hasActiveAccess(
        address creator,
        address subscriber
    ) external view returns (bool) {
        return _creatorAccessExpiries[creator][subscriber] > block.timestamp;
    }

    function _purchase(
        uint256 planId,
        bool isRenewal
    ) internal returns (uint256 expiresAt) {
        Types.SubscriptionPlan storage plan = _requireExistingPlan(planId);
        if (!plan.active) revert Errors.PlanInactive(planId);
        if (!creatorRegistry.isCreatorActive(plan.creator)) {
            revert Errors.CreatorInactive(plan.creator);
        }

        if (plan.paymentToken == address(0)) {
            if (msg.value != plan.price) revert Errors.InvalidNativeValue(plan.price, msg.value);
        } else if (msg.value != 0) {
            revert Errors.NativeValueNotAccepted();
        }

        paymentRouter.processSubscriptionPayment{ value: msg.value }(
            msg.sender, plan.creator, plan.paymentToken, plan.price
        );

        Types.SubscriptionRecord storage subscription = _subscriptions[planId][msg.sender];
        uint64 currentTimestamp = uint64(block.timestamp);
        uint64 previousExpiresAt = subscription.expiresAt;
        uint64 baseTimestamp =
            previousExpiresAt > currentTimestamp ? previousExpiresAt : currentTimestamp;

        expiresAt = baseTimestamp + uint64(plan.duration);

        subscription.startedAt = currentTimestamp;
        subscription.expiresAt = uint64(expiresAt);
        subscription.updatedAt = currentTimestamp;

        if (expiresAt > _creatorAccessExpiries[plan.creator][msg.sender]) {
            _creatorAccessExpiries[plan.creator][msg.sender] = uint64(expiresAt);
        }

        if (isRenewal) {
            emit Events.SubscriptionRenewed(
                planId, msg.sender, plan.creator, previousExpiresAt, expiresAt
            );
        } else {
            emit Events.SubscriptionPurchased(
                planId, msg.sender, plan.creator, currentTimestamp, expiresAt
            );
        }
    }

    function _planExists(
        uint256 planId
    ) internal view returns (bool) {
        return _plans[planId].creator != address(0);
    }

    function _requireExistingPlan(
        uint256 planId
    ) internal view returns (Types.SubscriptionPlan storage plan) {
        plan = _plans[planId];
        if (plan.creator == address(0)) revert Errors.PlanNotFound(planId);
    }

    function _requireCreatorPlan(
        uint256 planId,
        address caller
    ) internal view returns (Types.SubscriptionPlan storage plan) {
        plan = _requireExistingPlan(planId);
        if (plan.creator != caller) revert Errors.NotPlanCreator(planId, caller);
    }
}
