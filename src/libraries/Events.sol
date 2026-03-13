// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

library Events {
    event CreatorRegistered(
        address indexed creator, address indexed payoutAddress, string metadataURI
    );
    event CreatorPayoutAddressUpdated(
        address indexed creator,
        address indexed previousPayoutAddress,
        address indexed newPayoutAddress
    );
    event CreatorMetadataURIUpdated(address indexed creator, string metadataURI);
    event CreatorStatusUpdated(address indexed creator, bool active, address indexed actor);
    event PlanCreated(
        uint256 indexed planId,
        address indexed creator,
        address indexed paymentToken,
        uint256 price,
        uint256 duration
    );
    event PlanPriceUpdated(uint256 indexed planId, uint256 previousPrice, uint256 newPrice);
    event PlanStatusUpdated(uint256 indexed planId, bool active);
    event SubscriptionPurchased(
        uint256 indexed planId,
        address indexed subscriber,
        address indexed creator,
        uint256 startsAt,
        uint256 expiresAt
    );
    event SubscriptionRenewed(
        uint256 indexed planId,
        address indexed subscriber,
        address indexed creator,
        uint256 previousExpiresAt,
        uint256 newExpiresAt
    );
    event PaymentProcessed(
        address indexed payer,
        address indexed creator,
        address indexed paymentToken,
        uint256 grossAmount,
        uint256 platformFeeAmount,
        uint256 creatorNetAmount,
        address treasury
    );
    event PlatformFeeBpsUpdated(uint16 previousFeeBps, uint16 newFeeBps);
    event SubscriptionManagerUpdated(address indexed previousManager, address indexed newManager);
    event TreasuryNativeReceived(address indexed from, uint256 amount);
    event TreasuryNativeWithdrawn(address indexed to, uint256 amount);
    event TreasuryERC20Withdrawn(address indexed token, address indexed to, uint256 amount);
}
