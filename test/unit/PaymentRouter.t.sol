// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Errors } from "src/libraries/Errors.sol";
import { MockFailingReceiver } from "test/mocks/MockFailingReceiver.sol";
import { AllureHubTestBase } from "test/utils/AllureHubTestBase.sol";

contract PaymentRouterTest is AllureHubTestBase {
    function test_SubscribeWithETHDistributesPlatformFee() public {
        uint256 planId = _createEthPlan();
        uint256 platformFee = ETH_PLAN_PRICE * DEFAULT_PLATFORM_FEE_BPS / 10_000;
        uint256 creatorNet = ETH_PLAN_PRICE - platformFee;

        uint256 creatorBalanceBefore = creatorPayout.balance;
        uint256 treasuryBalanceBefore = address(platformTreasury).balance;

        _subscribeEth(planId, user);

        assertEq(creatorPayout.balance, creatorBalanceBefore + creatorNet);
        assertEq(address(platformTreasury).balance, treasuryBalanceBefore + platformFee);
    }

    function test_SubscribeWithERC20DistributesPlatformFee() public {
        uint256 planId = _createErc20Plan();
        uint256 platformFee = ERC20_PLAN_PRICE * DEFAULT_PLATFORM_FEE_BPS / 10_000;
        uint256 creatorNet = ERC20_PLAN_PRICE - platformFee;

        uint256 creatorBalanceBefore = mockUSDC.balanceOf(creatorPayout);
        uint256 treasuryBalanceBefore = mockUSDC.balanceOf(address(platformTreasury));

        _subscribeErc20(planId, user);

        assertEq(mockUSDC.balanceOf(creatorPayout), creatorBalanceBefore + creatorNet);
        assertEq(mockUSDC.balanceOf(address(platformTreasury)), treasuryBalanceBefore + platformFee);
    }

    function test_RevertWhen_NativeValueDoesNotMatchPlanPrice() public {
        uint256 planId = _createEthPlan();

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.InvalidNativeValue.selector, ETH_PLAN_PRICE, 0.5 ether)
        );
        subscriptionManager.subscribe{ value: 0.5 ether }(planId);
    }

    function test_RevertWhen_OnlySubscriptionManagerCanRoutePayments() public {
        _registerCreator();

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedCaller.selector, owner));
        paymentRouter.processSubscriptionPayment{ value: ETH_PLAN_PRICE }(
            user, creator, address(0), ETH_PLAN_PRICE
        );
    }

    function test_RevertWhen_CreatorPayoutRejectsNativeTransfers() public {
        address badCreator = makeAddr("badCreator");
        MockFailingReceiver failingReceiver = new MockFailingReceiver();

        vm.deal(badCreator, 1 ether);

        vm.prank(badCreator);
        creatorRegistry.registerCreator(
            address(failingReceiver), "ipfs://alurehub/creator/bad.json"
        );

        vm.prank(badCreator);
        uint256 planId = subscriptionManager.createPlan(ETH_PLAN_PRICE, address(0), PLAN_DURATION);

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.NativeTransferFailed.selector, address(failingReceiver))
        );
        subscriptionManager.subscribe{ value: ETH_PLAN_PRICE }(planId);
    }

    function test_RevertWhen_OwnerSetsFeeAboveCap() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidFeeBps.selector, 2501));
        paymentRouter.setPlatformFeeBps(2501);
    }
}
