// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./utils/interfaces/IERC20.sol";
import "./utils/SafeERC20.sol";
import "./interfaces/IForward.sol";

/// @title Forward Contract
/// @author LI.FI (https://li.fi)
/// @notice Provides functionality for forwarding calldata to li.fi.
contract Forward is IForward {
    using SafeERC20 for IERC20;

    /// External Methods ///

    /// @inheritdoc IForward
    function forward(
        address lifi,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) external payable override {
        _forward(lifi, token, amount, data);
    }

    /// @inheritdoc IForward
    function extractBridgeData(
        bytes calldata data
    ) external pure override returns (BridgeData memory bridgeData) {
        bridgeData = abi.decode(data[4:], (BridgeData));
    }

    /// @inheritdoc IForward
    function extractSwapData(
        bytes calldata data
    ) external pure override returns (SwapData[] memory swapData) {
        (, swapData) = abi.decode(data[4:], (BridgeData, SwapData[]));
    }

    /// @inheritdoc IForward
    function extractAmarokData(
        bytes calldata data
    ) external pure override returns (AmarokData memory amarokData) {
        BridgeData memory bridgeData = abi.decode(data[4:], (BridgeData));
        if (bridgeData.hasSourceSwaps) {
            (, , amarokData) = abi.decode(
                data[4:],
                (BridgeData, SwapData[], AmarokData)
            );
        } else {
            (, amarokData) = abi.decode(data[4:], (BridgeData, AmarokData));
        }
    }

    /// @inheritdoc IForward
    function extractArbitrumData(
        bytes calldata data
    ) external pure override returns (ArbitrumData memory arbitrumData) {
        BridgeData memory bridgeData = abi.decode(data[4:], (BridgeData));
        if (bridgeData.hasSourceSwaps) {
            (, , arbitrumData) = abi.decode(
                data[4:],
                (BridgeData, SwapData[], ArbitrumData)
            );
        } else {
            (, arbitrumData) = abi.decode(data[4:], (BridgeData, ArbitrumData));
        }
    }

    /// @inheritdoc IForward
    function extractStargateData(
        bytes calldata data
    ) external pure override returns (StargateData memory stargateData) {
        BridgeData memory bridgeData = abi.decode(data[4:], (BridgeData));
        if (bridgeData.hasSourceSwaps) {
            (, , stargateData) = abi.decode(
                data[4:],
                (BridgeData, SwapData[], StargateData)
            );
        } else {
            (, stargateData) = abi.decode(data[4:], (BridgeData, StargateData));
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
    ) internal virtual {
        if (!_isNative(token)) {
            token.safeTransferFrom(msg.sender, address(this), amount);

            _setAllowance(token, lifi, amount);
        }

        (bool success, bytes memory err) = lifi.call{value: msg.value}(data);

        if (!success) {
            revert FailedToForward(err);
        }

        emit Forwarded(lifi, token, amount, data);
    }

    /// @notice Set allowance of token for a spender.
    /// @param token Token of address to set allowance.
    /// @param spender Address to give spend approval to.
    /// @param amount Amount to approve for spending.
    function _setAllowance(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        if (_isNative(token)) {
            return;
        }
        if (spender == address(0)) {
            revert SpenderIsInvalid();
        }

        uint256 allowance = token.allowance(address(this), spender);

        if (allowance < amount) {
            if (allowance != 0) {
                token.safeApprove(spender, 0);
            }
            token.safeApprove(spender, amount);
        }
    }

    /// @notice Check if the token is native asset.
    /// @param token Token to check.
    /// @return isNative True if the token is native asset.
    function _isNative(IERC20 token) internal pure returns (bool isNative) {
        return address(token) == address(0);
    }
}
