// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Types } from "src/libraries/Types.sol";

interface IPaymentRouter {
    function platformFeeBps() external view returns (uint16);

    function treasury() external view returns (address);

    function subscriptionManager() external view returns (address);

    function setSubscriptionManager(
        address newSubscriptionManager
    ) external;

    function setPlatformFeeBps(
        uint16 newFeeBps
    ) external;

    function previewPayment(
        uint256 grossAmount
    ) external view returns (Types.FeeQuote memory);

    function processSubscriptionPayment(
        address payer,
        address creator,
        address paymentToken,
        uint256 amount
    ) external payable returns (Types.FeeQuote memory);
}
