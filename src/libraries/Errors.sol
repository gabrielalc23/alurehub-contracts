// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

library Errors {
    error ZeroAddress();
    error InvalidAmount();
    error InvalidDuration();
    error InvalidFeeBps(uint16 feeBps);
    error InvalidPaymentToken(address token);
    error InsufficientBalance(uint256 available, uint256 required);
    error CreatorAlreadyRegistered(address creator);
    error CreatorNotRegistered(address creator);
    error CreatorInactive(address creator);
    error CallerNotCreator(address caller);
    error NotPlanCreator(uint256 planId, address caller);
    error PlanNotFound(uint256 planId);
    error PlanInactive(uint256 planId);
    error SubscriptionNotFound(uint256 planId, address subscriber);
    error SubscriptionAlreadyActive(uint256 planId, address subscriber, uint256 expiresAt);
    error UnauthorizedCaller(address caller);
    error InvalidNativeValue(uint256 expected, uint256 received);
    error NativeValueNotAccepted();
    error NativeTransferFailed(address recipient);
}
