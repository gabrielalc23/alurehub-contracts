// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

library Types {
    struct CreatorProfile {
        address payoutAddress;
        bool active;
        uint64 createdAt;
        uint64 updatedAt;
        string metadataURI;
    }

    struct SubscriptionPlan {
        address creator;
        address paymentToken;
        uint96 price;
        uint32 duration;
        bool active;
        uint64 createdAt;
        uint64 updatedAt;
    }

    struct SubscriptionRecord {
        uint64 startedAt;
        uint64 expiresAt;
        uint64 updatedAt;
    }

    struct FeeQuote {
        uint256 grossAmount;
        uint256 platformFeeAmount;
        uint256 creatorNetAmount;
    }

    struct AccessState {
        bool creatorHasAccess;
        bool planHasAccess;
        uint256 creatorAccessExpiry;
        uint256 planAccessExpiry;
    }
}
