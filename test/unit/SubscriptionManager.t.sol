// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Errors } from "src/libraries/Errors.sol";
import { Types } from "src/libraries/Types.sol";
import { AllureHubTestBase } from "test/utils/AllureHubTestBase.sol";

contract SubscriptionManagerTest is AllureHubTestBase {
    function test_CreatePlan() public {
        uint256 planId = _createEthPlan();

        Types.SubscriptionPlan memory plan = subscriptionManager.getPlan(planId);
        uint256[] memory creatorPlanIds = subscriptionManager.getCreatorPlanIds(creator);

        assertEq(plan.creator, creator);
        assertEq(plan.paymentToken, address(0));
        assertEq(plan.price, ETH_PLAN_PRICE);
        assertEq(plan.duration, PLAN_DURATION);
        assertTrue(plan.active);
        assertEq(creatorPlanIds.length, 1);
        assertEq(creatorPlanIds[0], planId);
    }

    function test_RenewSubscriptionExtendsFromCurrentExpiry() public {
        uint256 planId = _createEthPlan();
        uint256 firstExpiry = _subscribeEth(planId, user);

        vm.warp(block.timestamp + 10 days);
        uint256 renewedExpiry = _renewEth(planId, user);

        assertEq(renewedExpiry, firstExpiry + PLAN_DURATION);
    }

    function test_RevertWhen_SubscribeToInactivePlan() public {
        uint256 planId = _createEthPlan();

        vm.prank(creator);
        subscriptionManager.setPlanStatus(planId, false);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Errors.PlanInactive.selector, planId));
        subscriptionManager.subscribe{ value: ETH_PLAN_PRICE }(planId);
    }

    function test_RevertWhen_SubscribeToInactiveCreator() public {
        uint256 planId = _createEthPlan();

        vm.prank(owner);
        creatorRegistry.adminSetCreatorStatus(creator, false);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Errors.CreatorInactive.selector, creator));
        subscriptionManager.subscribe{ value: ETH_PLAN_PRICE }(planId);
    }

    function test_RevertWhen_SubscribeTwiceWithoutRenew() public {
        uint256 planId = _createEthPlan();
        uint256 firstExpiry = _subscribeEth(planId, user);

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SubscriptionAlreadyActive.selector, planId, user, firstExpiry
            )
        );
        subscriptionManager.subscribe{ value: ETH_PLAN_PRICE }(planId);
    }

    function test_RevertWhen_NonCreatorUpdatesPlan() public {
        uint256 planId = _createEthPlan();

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotPlanCreator.selector, planId, user));
        subscriptionManager.updatePlanPrice(planId, ETH_PLAN_PRICE * 2);
    }
}
