// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IPlatformTreasury } from "src/interfaces/IPlatformTreasury.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

/// @title PlatformTreasury
/// @notice Custodies protocol fees until the platform owner explicitly withdraws them.
contract PlatformTreasury is IPlatformTreasury, Ownable2Step {
    using SafeERC20 for IERC20;

    constructor(
        address initialOwner
    ) Ownable(initialOwner) {
        if (initialOwner == address(0)) revert Errors.ZeroAddress();
    }

    receive() external payable {
        emit Events.TreasuryNativeReceived(msg.sender, msg.value);
    }

    /// @inheritdoc IPlatformTreasury
    function nativeBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @inheritdoc IPlatformTreasury
    function tokenBalance(
        address token
    ) external view returns (uint256) {
        if (token == address(0)) revert Errors.ZeroAddress();
        return IERC20(token).balanceOf(address(this));
    }

    /// @inheritdoc IPlatformTreasury
    function withdrawNative(
        address payable to,
        uint256 amount
    ) external onlyOwner {
        if (to == address(0)) revert Errors.ZeroAddress();
        if (amount == 0) revert Errors.InvalidAmount();

        uint256 balance = address(this).balance;
        if (amount > balance) revert Errors.InsufficientBalance(balance, amount);

        (bool success,) = to.call{ value: amount }("");
        if (!success) revert Errors.NativeTransferFailed(to);

        emit Events.TreasuryNativeWithdrawn(to, amount);
    }

    /// @inheritdoc IPlatformTreasury
    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (token == address(0) || to == address(0)) revert Errors.ZeroAddress();
        if (amount == 0) revert Errors.InvalidAmount();

        IERC20 asset = IERC20(token);
        uint256 balance = asset.balanceOf(address(this));
        if (amount > balance) revert Errors.InsufficientBalance(balance, amount);

        asset.safeTransfer(to, amount);

        emit Events.TreasuryERC20Withdrawn(token, to, amount);
    }
}
