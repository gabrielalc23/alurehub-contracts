// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

interface IPlatformTreasury {
    function nativeBalance() external view returns (uint256);

    function tokenBalance(
        address token
    ) external view returns (uint256);

    function withdrawNative(
        address payable to,
        uint256 amount
    ) external;

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external;
}
