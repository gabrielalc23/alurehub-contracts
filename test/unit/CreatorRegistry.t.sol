// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Errors } from "src/libraries/Errors.sol";
import { Types } from "src/libraries/Types.sol";
import { AllureHubTestBase } from "test/utils/AllureHubTestBase.sol";

contract CreatorRegistryTest is AllureHubTestBase {
    function test_RegisterCreatorStoresProfile() public {
        vm.prank(creator);
        creatorRegistry.registerCreator(creatorPayout, "ipfs://alurehub/creator/profile.json");

        Types.CreatorProfile memory profile = creatorRegistry.getCreator(creator);

        assertEq(profile.payoutAddress, creatorPayout);
        assertTrue(profile.active);
        assertEq(profile.metadataURI, "ipfs://alurehub/creator/profile.json");
        assertGt(profile.createdAt, 0);
        assertEq(profile.updatedAt, profile.createdAt);
    }

    function test_UpdatePayoutAddress() public {
        _registerCreator();

        vm.prank(creator);
        creatorRegistry.updatePayoutAddress(creatorPayoutTwo);

        assertEq(creatorRegistry.payoutAddressOf(creator), creatorPayoutTwo);
    }

    function test_RevertWhen_RegisteringTwice() public {
        _registerCreator();

        vm.prank(creator);
        vm.expectRevert(abi.encodeWithSelector(Errors.CreatorAlreadyRegistered.selector, creator));
        creatorRegistry.registerCreator(creatorPayout, "ipfs://alurehub/creator/profile.json");
    }

    function test_AdminCanDeactivateCreator() public {
        _registerCreator();

        vm.prank(owner);
        creatorRegistry.adminSetCreatorStatus(creator, false);

        assertFalse(creatorRegistry.isCreatorActive(creator));
    }
}
