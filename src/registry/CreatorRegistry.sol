// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

import { ICreatorRegistry } from "src/interfaces/ICreatorRegistry.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { Types } from "src/libraries/Types.sol";

/// @title CreatorRegistry
/// @notice Stores creator profile data used across subscription, payout, and access flows.
contract CreatorRegistry is ICreatorRegistry, Ownable2Step {
    mapping(address creator => Types.CreatorProfile profile) private _creatorProfiles;

    constructor(
        address initialOwner
    ) Ownable(initialOwner) {
        if (initialOwner == address(0)) revert Errors.ZeroAddress();
    }

    /// @inheritdoc ICreatorRegistry
    function registerCreator(
        address payoutAddress,
        string calldata metadataURI
    ) external {
        if (payoutAddress == address(0)) revert Errors.ZeroAddress();
        if (_creatorProfiles[msg.sender].createdAt != 0) {
            revert Errors.CreatorAlreadyRegistered(msg.sender);
        }

        uint64 timestamp = uint64(block.timestamp);
        _creatorProfiles[msg.sender] = Types.CreatorProfile({
            payoutAddress: payoutAddress,
            active: true,
            createdAt: timestamp,
            updatedAt: timestamp,
            metadataURI: metadataURI
        });

        emit Events.CreatorRegistered(msg.sender, payoutAddress, metadataURI);
    }

    /// @inheritdoc ICreatorRegistry
    function updatePayoutAddress(
        address newPayoutAddress
    ) external {
        if (newPayoutAddress == address(0)) revert Errors.ZeroAddress();

        Types.CreatorProfile storage profile = _requireRegisteredCreator(msg.sender);
        address previousPayoutAddress = profile.payoutAddress;

        profile.payoutAddress = newPayoutAddress;
        profile.updatedAt = uint64(block.timestamp);

        emit Events.CreatorPayoutAddressUpdated(msg.sender, previousPayoutAddress, newPayoutAddress);
    }

    /// @inheritdoc ICreatorRegistry
    function updateMetadataURI(
        string calldata newMetadataURI
    ) external {
        Types.CreatorProfile storage profile = _requireRegisteredCreator(msg.sender);

        profile.metadataURI = newMetadataURI;
        profile.updatedAt = uint64(block.timestamp);

        emit Events.CreatorMetadataURIUpdated(msg.sender, newMetadataURI);
    }

    /// @inheritdoc ICreatorRegistry
    function setMyStatus(
        bool active
    ) external {
        _setCreatorStatus(msg.sender, active, msg.sender);
    }

    /// @inheritdoc ICreatorRegistry
    function adminSetCreatorStatus(
        address creator,
        bool active
    ) external onlyOwner {
        _setCreatorStatus(creator, active, msg.sender);
    }

    /// @inheritdoc ICreatorRegistry
    function isRegisteredCreator(
        address creator
    ) external view returns (bool) {
        return _creatorProfiles[creator].createdAt != 0;
    }

    /// @inheritdoc ICreatorRegistry
    function isCreatorActive(
        address creator
    ) external view returns (bool) {
        Types.CreatorProfile storage profile = _creatorProfiles[creator];
        return profile.createdAt != 0 && profile.active;
    }

    /// @inheritdoc ICreatorRegistry
    function payoutAddressOf(
        address creator
    ) external view returns (address) {
        return _requireRegisteredCreator(creator).payoutAddress;
    }

    /// @inheritdoc ICreatorRegistry
    function getCreator(
        address creator
    ) external view returns (Types.CreatorProfile memory profile) {
        Types.CreatorProfile storage storedProfile = _requireRegisteredCreator(creator);
        profile = storedProfile;
    }

    function _setCreatorStatus(
        address creator,
        bool active,
        address actor
    ) internal {
        Types.CreatorProfile storage profile = _requireRegisteredCreator(creator);

        profile.active = active;
        profile.updatedAt = uint64(block.timestamp);

        emit Events.CreatorStatusUpdated(creator, active, actor);
    }

    function _requireRegisteredCreator(
        address creator
    ) internal view returns (Types.CreatorProfile storage profile) {
        profile = _creatorProfiles[creator];
        if (profile.createdAt == 0) revert Errors.CreatorNotRegistered(creator);
    }
}
