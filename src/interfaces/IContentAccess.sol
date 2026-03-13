// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Types } from "src/libraries/Types.sol";

interface IContentAccess {
    function hasCreatorAccess(
        address creator,
        address subscriber
    ) external view returns (bool);

    function hasPlanAccess(
        uint256 planId,
        address subscriber
    ) external view returns (bool);

    function getCreatorAccessExpiry(
        address creator,
        address subscriber
    ) external view returns (uint256);

    function getPlanAccessExpiry(
        uint256 planId,
        address subscriber
    ) external view returns (uint256);

    function getAccessState(
        uint256 planId,
        address subscriber
    ) external view returns (Types.AccessState memory);
}
