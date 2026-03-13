# AllureHub Smart Contracts

Professional Solidity contracts for AllureHub's on-chain subscription, payment routing, and access control flow.

All private content, media, posts, and delivery remain off-chain. The contracts only store the minimum on-chain state required for creator registration, plan pricing, subscription validity, fee routing, and access checks.

## Version Policy

This repository is pinned to the most recent **official stable** versions I could verify from upstream sources as of **March 13, 2026**:

- Solidity `0.8.34`
- Foundry `v1.5.0`
- OpenZeppelin Contracts `v5.5.0`
- forge-std `v1.12.0`

Solidity `0.8.34` was released on **February 18, 2026** as the latest official stable compiler release. This repository is now pinned to that version.

## Stack

- Solidity `0.8.34`
- Foundry
- OpenZeppelin Contracts
- Docker-first developer workflow

## Project Structure

```text
.
├── Dockerfile
├── README.md
├── foundry.toml
├── script
│   └── Deploy.s.sol
├── src
│   ├── core
│   │   ├── ContentAccess.sol
│   │   ├── PaymentRouter.sol
│   │   └── SubscriptionManager.sol
│   ├── interfaces
│   │   ├── IContentAccess.sol
│   │   ├── ICreatorRegistry.sol
│   │   ├── IPaymentRouter.sol
│   │   ├── IPlatformTreasury.sol
│   │   └── ISubscriptionManager.sol
│   ├── libraries
│   │   ├── Errors.sol
│   │   ├── Events.sol
│   │   └── Types.sol
│   ├── registry
│   │   └── CreatorRegistry.sol
│   ├── treasury
│   │   └── PlatformTreasury.sol
│   └── utils
│       └── Fees.sol
└── test
    ├── integration
    │   └── SubscriptionFlow.t.sol
    ├── mocks
    │   ├── MockERC20.sol
    │   └── MockFailingReceiver.sol
    ├── unit
    │   ├── ContentAccess.t.sol
    │   ├── CreatorRegistry.t.sol
    │   ├── PaymentRouter.t.sol
    │   └── SubscriptionManager.t.sol
    └── utils
        └── AllureHubTestBase.sol
```

## Architecture

### CreatorRegistry

- Registers creators
- Stores `payoutAddress`, `metadataURI`, active status, and timestamps
- Lets creators update payout and metadata independently from their operational wallet
- Exposes lightweight read methods to other contracts

### SubscriptionManager

- Creates and manages subscription plans
- Stores subscriptions by `planId + subscriber`
- Supports native ETH with `address(0)` and ERC-20 plans
- Tracks `creatorAccessExpiry` for O(1) creator-level access checks

### PaymentRouter

- Splits subscription payments atomically
- Calculates platform fees in basis points
- Routes fees to `PlatformTreasury`
- Pushes creator proceeds directly to the creator payout address

Push settlement is intentional here: a subscription is only created if the full payment split succeeds in the same transaction. That avoids pending balances and simplifies accounting.

### PlatformTreasury

- Custodies accumulated protocol fees
- Supports controlled admin withdrawals for ETH and ERC-20

### ContentAccess

- Exposes cheap read helpers for backend/frontend authorization
- Validates access by creator and by plan
- Does not store content, media, or posts

## Main Flow

1. A creator registers in `CreatorRegistry`.
2. The creator creates a plan in `SubscriptionManager`.
3. A subscriber calls `subscribe` or `renewSubscription`.
4. `SubscriptionManager` validates plan and creator state.
5. `PaymentRouter` settles the payment and fee split atomically.
6. `SubscriptionManager` updates `expiresAt`.
7. Backend or frontend checks `ContentAccess` before serving off-chain content.

## Security Notes

- `ReentrancyGuard` on payment and subscription flows
- `Pausable` on `SubscriptionManager`
- `Ownable2Step` on admin-managed contracts
- Custom errors instead of revert strings where appropriate
- Explicit validation for zero addresses, inactive creators, inactive plans, invalid durations, and invalid amounts
- Fee cap set to `2,500` bps by default as a sane operational guardrail

Operational caveats:

- There is no on-chain chargeback flow
- `metadataURI` is only a reference pointer
- Fee-on-transfer or non-standard ERC-20 tokens should be reviewed before production

## Docker Workflow

No local Foundry or Solidity installation is required.

### Build the image

```bash
docker build -t alurehub-contracts .
```

### Run formatting checks

```bash
docker run --rm alurehub-contracts fmt --check
```

### Build contracts

```bash
docker run --rm alurehub-contracts build --sizes
```

### Run tests

```bash
docker run --rm alurehub-contracts test -vvv
```

### Open a shell inside the image

```bash
docker run --rm -it --entrypoint /bin/sh alurehub-contracts
```

## Native Workflow

If you already have compatible binaries installed locally, these commands still work:

```bash
forge fmt --check
forge build --sizes
forge test -vvv
```

## Deployment

Set the environment variables:

```bash
export PRIVATE_KEY=0x...
export ALLUREHUB_OWNER=0x...
export PLATFORM_FEE_BPS=1000
export RPC_URL=https://...
```

Run:

```bash
forge script script/Deploy.s.sol:DeployAllureHub \
  --rpc-url "$RPC_URL" \
  --broadcast \
  -vvvv
```

## Test Coverage

The suite covers:

- creator registration
- payout address update
- plan creation
- ETH subscriptions
- ERC-20 subscriptions
- inactive plan reverts
- inactive creator reverts
- fee distribution correctness
- subscription renewal
- active access checks
- security-oriented revert cases

## Production Next Steps

- add granular RBAC with `AccessControl`
- decide on upgradeability versus migration/versioning strategy
- commission an external audit
- add discounts, coupons, bundles, and referrals
- add recurring payment automation off-chain
- add event indexing via subgraph or custom indexer
- add finance reconciliation and monitoring
- formalize moderation and creator suspension workflows
# alurehub-contracts
