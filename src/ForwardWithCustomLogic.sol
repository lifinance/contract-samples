// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./utils/interfaces/IBeefyVault.sol";
import "./utils/interfaces/IStargateETHVault.sol";
import "./utils/interfaces/IStargatePool.sol";
import "./utils/interfaces/IStargateRouter.sol";
import "./utils/interfaces/IERC20.sol";
import "./utils/SafeERC20.sol";
import "./Forward.sol";
import "forge-std/console.sol";

/// @title Forward Contract with custom logic.
/// @author LI.FI (https://li.fi)
/// @notice Provides functionality for forwarding calldata to li.fi.
contract ForwardWithCustomLogic is Forward {
    using SafeERC20 for IERC20;

    /// EVENTS ///

    event ForwardedWithCustomLogic(
        IBeefyVault beefyVault,
        uint256 shares,
        address lifi,
        IERC20 token,
        uint256 amount,
        bytes data
    );

    /// ERRORS ///

    error TokensMismatch(address token, address actual);
    error InsufficientAmount(uint256 amount, uint256 actual);
    error FailedToRefundExcessNative();

    /// External Methods ///

    /// @notice Forward call data to li.fi contract.
    /// @param beefyVault The address of Beefy vault.
    /// @param shares The amount of share.
    /// @param lifi The address of li.fi contract.
    /// @param token The address of token to send.
    /// @param amount The Amount of token to send.
    /// @param data The calldata to forward.
    function forwardWithCustomLogic(
        IBeefyVault beefyVault,
        uint256 shares,
        address lifi,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) external payable {
        _doCustomLogic(beefyVault, shares, token, amount);
        _forward(lifi, token, amount, data);

        emit ForwardedWithCustomLogic(
            beefyVault,
            shares,
            lifi,
            token,
            amount,
            data
        );
    }

    /// Internal Methods ///

    /// @notice Do custom logic before forward to li.fi.
    /// @dev Here, it redeem shares from beefy vault.
    ///      And then it withdraws underlying token(sending asset) from stargate pool.
    /// @param beefyVault The address of Beefy vault.
    /// @param shares The amount of share.
    /// @param token The address of token to send.
    /// @param amount The Amount of token to send.
    function _doCustomLogic(
        IBeefyVault beefyVault,
        uint256 shares,
        IERC20 token,
        uint256 amount
    ) internal {
        address want = beefyVault.want();
        IStargatePool stargatePool = IStargatePool(want);
        IStargateRouter stargateRouter = IStargateRouter(stargatePool.router());
        uint256 poolId = stargatePool.poolId();

        bool isNative = _isNative(token);
        address underlyingToken = stargatePool.token();

        if (address(token) != underlyingToken) {
            revert TokensMismatch(address(token), underlyingToken);
        }

        IERC20(address(beefyVault)).safeTransferFrom(
            msg.sender,
            address(this),
            shares
        );

        // Withdraw stargate pool token from beefy vault.

        uint256 lpBalance = IERC20(want).balanceOf(address(this));

        beefyVault.withdraw(shares);

        uint256 lpAmount = IERC20(want).balanceOf(address(this)) - lpBalance;

        // Withdraw underlying token(sending asset) from stargate pool.

        uint256 tokenBalance = isNative
            ? address(this).balance
            : token.balanceOf(address(this));

        stargateRouter.instantRedeemLocal(
            uint16(poolId),
            lpAmount,
            address(this)
        );

        uint256 tokenAmount = isNative
            ? address(this).balance - tokenBalance
            : token.balanceOf(address(this)) - tokenBalance;

        // Check withdrawn amount.

        if (tokenAmount < amount) {
            revert InsufficientAmount(amount, tokenAmount);
        }

        // Refund excess amount of sending token.

        if (isNative) {
            (bool success, ) = msg.sender.call{value: tokenAmount - amount}("");
            if (!success) {
                revert FailedToRefundExcessNative();
            }
        } else {
            token.safeTransfer(msg.sender, tokenAmount - amount);
        }
    }

    /// @notice Forward call data to li.fi contract.
    /// @param lifi The address of li.fi contract.
    /// @param token The address of token to send.
    /// @param amount The Amount of token to send.
    /// @param data The calldata to forward.
    function _forward(
        address lifi,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) internal override {
        if (!_isNative(token)) {
            _setAllowance(token, lifi, amount);
        }

        (bool success, bytes memory err) = lifi.call{value: msg.value}(data);

        if (!success) {
            revert FailedToForward(err);
        }

        emit Forwarded(lifi, token, amount, data);
    }
}
