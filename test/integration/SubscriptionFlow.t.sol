// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { AllureHubTestBase } from "test/utils/AllureHubTestBase.sol";

contract SubscriptionFlowIntegrationTest is AllureHubTestBase {
    function test_EndToEndFlowForNativeAndERC20Plans() public {
        uint256 ethPlanId = _createEthPlan();
        uint256 erc20PlanId = _createErc20Plan();

        uint256 ethFee = ETH_PLAN_PRICE * DEFAULT_PLATFORM_FEE_BPS / 10_000;
        uint256 erc20Fee = ERC20_PLAN_PRICE * DEFAULT_PLATFORM_FEE_BPS / 10_000;
        uint256 accumulatedEthFees = ethFee * 2;

        uint256 initialEthExpiry = _subscribeEth(ethPlanId, user);
        uint256 erc20Expiry = _subscribeErc20(erc20PlanId, userTwo);

        assertTrue(contentAccess.hasPlanAccess(ethPlanId, user));
        assertTrue(contentAccess.hasPlanAccess(erc20PlanId, userTwo));
        assertEq(contentAccess.getPlanAccessExpiry(erc20PlanId, userTwo), erc20Expiry);
        assertEq(address(platformTreasury).balance, ethFee);
        assertEq(mockUSDC.balanceOf(address(platformTreasury)), erc20Fee);

        vm.warp(block.timestamp + 7 days);
        uint256 renewedEthExpiry = _renewEth(ethPlanId, user);

        assertEq(renewedEthExpiry, initialEthExpiry + PLAN_DURATION);
        assertTrue(contentAccess.hasCreatorAccess(creator, user));
        assertEq(address(platformTreasury).balance, accumulatedEthFees);

        vm.startPrank(owner);
        platformTreasury.withdrawNative(payable(owner), accumulatedEthFees);
        platformTreasury.withdrawERC20(address(mockUSDC), owner, erc20Fee);
        vm.stopPrank();

        assertEq(address(platformTreasury).balance, 0);
        assertEq(mockUSDC.balanceOf(address(platformTreasury)), 0);
        assertEq(mockUSDC.balanceOf(owner), erc20Fee);
    }
}
