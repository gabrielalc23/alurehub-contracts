// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Types } from "src/libraries/Types.sol";

interface ICreatorRegistry {
    function registerCreator(
        address payoutAddress,
        string calldata metadataURI
    ) external;

    function updatePayoutAddress(
        address newPayoutAddress
    ) external;

    function updateMetadataURI(
        string calldata newMetadataURI
    ) external;

    function setMyStatus(
        bool active
    ) external;

    function adminSetCreatorStatus(
        address creator,
        bool active
    ) external;

    function isRegisteredCreator(
        address creator
    ) external view returns (bool);

    function isCreatorActive(
        address creator
    ) external view returns (bool);

    function payoutAddressOf(
        address creator
    ) external view returns (address);

    function getCreator(
        address creator
    ) external view returns (Types.CreatorProfile memory);
}
