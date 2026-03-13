// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Types } from "src/libraries/Types.sol";
import { AllureHubTestBase } from "test/utils/AllureHubTestBase.sol";

contract ContentAccessTest is AllureHubTestBase {
    function test_HasActiveAccessAfterSubscription() public {
        uint256 planId = _createEthPlan();
        uint256 expiry = _subscribeEth(planId, user);

        Types.AccessState memory accessState = contentAccess.getAccessState(planId, user);

        assertTrue(contentAccess.hasPlanAccess(planId, user));
        assertTrue(contentAccess.hasCreatorAccess(creator, user));
        assertTrue(accessState.planHasAccess);
        assertTrue(accessState.creatorHasAccess);
        assertEq(accessState.planAccessExpiry, expiry);
        assertEq(accessState.creatorAccessExpiry, expiry);
    }

    function test_AccessExpiresAfterDuration() public {
        uint256 planId = _createEthPlan();
        _subscribeEth(planId, user);

        vm.warp(block.timestamp + PLAN_DURATION + 1);

        assertFalse(contentAccess.hasPlanAccess(planId, user));
        assertFalse(contentAccess.hasCreatorAccess(creator, user));
    }

    function test_CreatorDeactivationRemovesReadableAccess() public {
        uint256 planId = _createEthPlan();
        _subscribeEth(planId, user);

        vm.prank(owner);
        creatorRegistry.adminSetCreatorStatus(creator, false);

        assertFalse(contentAccess.hasPlanAccess(planId, user));
        assertFalse(contentAccess.hasCreatorAccess(creator, user));
    }
}
