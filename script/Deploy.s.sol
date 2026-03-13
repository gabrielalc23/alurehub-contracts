// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { console2 } from "forge-std/console2.sol";
import { Script } from "forge-std/Script.sol";

import { ContentAccess } from "src/core/ContentAccess.sol";
import { PaymentRouter } from "src/core/PaymentRouter.sol";
import { SubscriptionManager } from "src/core/SubscriptionManager.sol";
import { CreatorRegistry } from "src/registry/CreatorRegistry.sol";
import { PlatformTreasury } from "src/treasury/PlatformTreasury.sol";

/// @title DeployAllureHub
/// @notice Deploys the AllureHub contracts and wires their runtime dependencies.
contract DeployAllureHub is Script {
    function run()
        external
        returns (
            CreatorRegistry creatorRegistry,
            PlatformTreasury platformTreasury,
            PaymentRouter paymentRouter,
            SubscriptionManager subscriptionManager,
            ContentAccess contentAccess
        )
    {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address initialOwner = vm.envOr("ALLUREHUB_OWNER", vm.addr(deployerPrivateKey));
        uint256 configuredFeeBps = vm.envOr("PLATFORM_FEE_BPS", uint256(1000));

        vm.startBroadcast(deployerPrivateKey);

        creatorRegistry = new CreatorRegistry(initialOwner);
        platformTreasury = new PlatformTreasury(initialOwner);
        paymentRouter = new PaymentRouter(
            initialOwner,
            address(creatorRegistry),
            address(platformTreasury),
            uint16(configuredFeeBps)
        );
        subscriptionManager =
            new SubscriptionManager(initialOwner, address(creatorRegistry), address(paymentRouter));
        contentAccess = new ContentAccess(address(creatorRegistry), address(subscriptionManager));

        paymentRouter.setSubscriptionManager(address(subscriptionManager));

        vm.stopBroadcast();

        console2.log("CreatorRegistry:", address(creatorRegistry));
        console2.log("PlatformTreasury:", address(platformTreasury));
        console2.log("PaymentRouter:", address(paymentRouter));
        console2.log("SubscriptionManager:", address(subscriptionManager));
        console2.log("ContentAccess:", address(contentAccess));
    }
}
