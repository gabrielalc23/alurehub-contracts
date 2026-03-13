// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Test } from "forge-std/Test.sol";

import { ContentAccess } from "src/core/ContentAccess.sol";
import { PaymentRouter } from "src/core/PaymentRouter.sol";
import { SubscriptionManager } from "src/core/SubscriptionManager.sol";
import { CreatorRegistry } from "src/registry/CreatorRegistry.sol";
import { PlatformTreasury } from "src/treasury/PlatformTreasury.sol";
import { MockERC20 } from "test/mocks/MockERC20.sol";

abstract contract AllureHubTestBase is Test {
    uint16 internal constant DEFAULT_PLATFORM_FEE_BPS = 1000;
    uint96 internal constant ETH_PLAN_PRICE = 1 ether;
    uint96 internal constant ERC20_PLAN_PRICE = 100e6;
    uint32 internal constant PLAN_DURATION = 30 days;

    address internal owner = makeAddr("owner");
    address internal creator = makeAddr("creator");
    address internal creatorPayout = makeAddr("creatorPayout");
    address internal creatorPayoutTwo = makeAddr("creatorPayoutTwo");
    address internal user = makeAddr("user");
    address internal userTwo = makeAddr("userTwo");

    CreatorRegistry internal creatorRegistry;
    PlatformTreasury internal platformTreasury;
    PaymentRouter internal paymentRouter;
    SubscriptionManager internal subscriptionManager;
    ContentAccess internal contentAccess;
    MockERC20 internal mockUSDC;

    function setUp() public virtual {
        vm.deal(owner, 100 ether);
        vm.deal(creator, 100 ether);
        vm.deal(creatorPayout, 1 ether);
        vm.deal(creatorPayoutTwo, 1 ether);
        vm.deal(user, 100 ether);
        vm.deal(userTwo, 100 ether);

        vm.startPrank(owner);
        creatorRegistry = new CreatorRegistry(owner);
        platformTreasury = new PlatformTreasury(owner);
        paymentRouter = new PaymentRouter(
            owner, address(creatorRegistry), address(platformTreasury), DEFAULT_PLATFORM_FEE_BPS
        );
        subscriptionManager =
            new SubscriptionManager(owner, address(creatorRegistry), address(paymentRouter));
        contentAccess = new ContentAccess(address(creatorRegistry), address(subscriptionManager));
        paymentRouter.setSubscriptionManager(address(subscriptionManager));
        vm.stopPrank();

        mockUSDC = new MockERC20("Mock USD Coin", "mUSDC", 6);
        mockUSDC.mint(user, 1_000_000e6);
        mockUSDC.mint(userTwo, 1_000_000e6);
    }

    function _registerCreator() internal {
        if (creatorRegistry.isRegisteredCreator(creator)) return;

        vm.prank(creator);
        creatorRegistry.registerCreator(creatorPayout, "ipfs://allurehub/creator/profile.json");
    }

    function _createEthPlan() internal returns (uint256 planId) {
        _registerCreator();

        vm.prank(creator);
        planId = subscriptionManager.createPlan(ETH_PLAN_PRICE, address(0), PLAN_DURATION);
    }

    function _createErc20Plan() internal returns (uint256 planId) {
        _registerCreator();

        vm.prank(creator);
        planId = subscriptionManager.createPlan(ERC20_PLAN_PRICE, address(mockUSDC), PLAN_DURATION);
    }

    function _subscribeEth(
        uint256 planId,
        address subscriber
    ) internal returns (uint256 expiresAt) {
        vm.prank(subscriber);
        expiresAt = subscriptionManager.subscribe{ value: ETH_PLAN_PRICE }(planId);
    }

    function _renewEth(
        uint256 planId,
        address subscriber
    ) internal returns (uint256 expiresAt) {
        vm.prank(subscriber);
        expiresAt = subscriptionManager.renewSubscription{ value: ETH_PLAN_PRICE }(planId);
    }

    function _subscribeErc20(
        uint256 planId,
        address subscriber
    ) internal returns (uint256 expiresAt) {
        vm.startPrank(subscriber);
        mockUSDC.approve(address(paymentRouter), ERC20_PLAN_PRICE);
        expiresAt = subscriptionManager.subscribe(planId);
        vm.stopPrank();
    }

    function _renewErc20(
        uint256 planId,
        address subscriber
    ) internal returns (uint256 expiresAt) {
        vm.startPrank(subscriber);
        mockUSDC.approve(address(paymentRouter), ERC20_PLAN_PRICE);
        expiresAt = subscriptionManager.renewSubscription(planId);
        vm.stopPrank();
    }
}
