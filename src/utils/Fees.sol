// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Errors } from "src/libraries/Errors.sol";
import { Types } from "src/libraries/Types.sol";

library Fees {
    uint16 internal constant BPS_DENOMINATOR = 10_000;
    uint16 internal constant MAX_PLATFORM_FEE_BPS = 2500;

    function validateFeeBps(
        uint16 feeBps
    ) internal pure {
        if (feeBps > MAX_PLATFORM_FEE_BPS) {
            revert Errors.InvalidFeeBps(feeBps);
        }
    }

    function quote(
        uint256 grossAmount,
        uint16 feeBps
    ) internal pure returns (Types.FeeQuote memory feeQuote) {
        uint256 platformFeeAmount = grossAmount * feeBps / BPS_DENOMINATOR;

        feeQuote = Types.FeeQuote({
            grossAmount: grossAmount,
            platformFeeAmount: platformFeeAmount,
            creatorNetAmount: grossAmount - platformFeeAmount
        });
    }
}
