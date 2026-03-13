// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { ICreatorRegistry } from "src/interfaces/ICreatorRegistry.sol";
import { IPaymentRouter } from "src/interfaces/IPaymentRouter.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { Types } from "src/libraries/Types.sol";
import { Fees } from "src/utils/Fees.sol";

/// @title PaymentRouter
/// @notice Performs atomic settlement for subscriptions, splitting creator proceeds and protocol fees.
contract PaymentRouter is IPaymentRouter, Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    ICreatorRegistry public immutable creatorRegistry;
    address public immutable treasury;

    address public subscriptionManager;
    uint16 public platformFeeBps;

    modifier onlySubscriptionManager() {
        if (msg.sender != subscriptionManager) revert Errors.UnauthorizedCaller(msg.sender);
        _;
    }

    constructor(
        address initialOwner,
        address creatorRegistry_,
        address treasury_,
        uint16 initialPlatformFeeBps
    ) Ownable(initialOwner) {
        if (initialOwner == address(0) || creatorRegistry_ == address(0) || treasury_ == address(0))
        {
            revert Errors.ZeroAddress();
        }

        Fees.validateFeeBps(initialPlatformFeeBps);

        creatorRegistry = ICreatorRegistry(creatorRegistry_);
        treasury = treasury_;
        platformFeeBps = initialPlatformFeeBps;
    }

    /// @inheritdoc IPaymentRouter
    function setSubscriptionManager(
        address newSubscriptionManager
    ) external onlyOwner {
        if (newSubscriptionManager == address(0)) revert Errors.ZeroAddress();

        address previousManager = subscriptionManager;
        subscriptionManager = newSubscriptionManager;

        emit Events.SubscriptionManagerUpdated(previousManager, newSubscriptionManager);
    }

    /// @inheritdoc IPaymentRouter
    function setPlatformFeeBps(
        uint16 newFeeBps
    ) external onlyOwner {
        Fees.validateFeeBps(newFeeBps);

        uint16 previousFeeBps = platformFeeBps;
        platformFeeBps = newFeeBps;

        emit Events.PlatformFeeBpsUpdated(previousFeeBps, newFeeBps);
    }

    /// @inheritdoc IPaymentRouter
    function previewPayment(
        uint256 grossAmount
    ) external view returns (Types.FeeQuote memory) {
        return Fees.quote(grossAmount, platformFeeBps);
    }

    /// @inheritdoc IPaymentRouter
    function processSubscriptionPayment(
        address payer,
        address creator,
        address paymentToken,
        uint256 amount
    )
        external
        payable
        onlySubscriptionManager
        nonReentrant
        returns (Types.FeeQuote memory feeQuote)
    {
        if (payer == address(0) || creator == address(0)) {
            revert Errors.ZeroAddress();
        }
        if (amount == 0) revert Errors.InvalidAmount();
        if (!creatorRegistry.isCreatorActive(creator)) revert Errors.CreatorInactive(creator);

        address payoutAddress = creatorRegistry.payoutAddressOf(creator);
        if (payoutAddress == address(0)) revert Errors.ZeroAddress();

        feeQuote = Fees.quote(amount, platformFeeBps);

        if (paymentToken == address(0)) {
            if (msg.value != amount) revert Errors.InvalidNativeValue(amount, msg.value);
            _forwardNative(payable(treasury), feeQuote.platformFeeAmount);
            _forwardNative(payable(payoutAddress), feeQuote.creatorNetAmount);
        } else {
            if (msg.value != 0) revert Errors.NativeValueNotAccepted();
            _forwardERC20(paymentToken, payer, treasury, feeQuote.platformFeeAmount);
            _forwardERC20(paymentToken, payer, payoutAddress, feeQuote.creatorNetAmount);
        }

        emit Events.PaymentProcessed(
            payer,
            creator,
            paymentToken,
            amount,
            feeQuote.platformFeeAmount,
            feeQuote.creatorNetAmount,
            treasury
        );
    }

    function _forwardNative(
        address payable recipient,
        uint256 amount
    ) internal {
        if (amount == 0) return;

        (bool success,) = recipient.call{ value: amount }("");
        if (!success) revert Errors.NativeTransferFailed(recipient);
    }

    function _forwardERC20(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) return;
        IERC20(token).safeTransferFrom(from, to, amount);
    }
}
