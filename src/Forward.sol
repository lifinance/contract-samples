// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CalldataVerificationFacet} from "@lifi/Facets/CalldataVerificationFacet.sol";
import {ILiFi} from "@lifi/Interfaces/ILiFi.sol";
import {LibSwap} from "@lifi/Libraries/LibSwap.sol";
import "./utils/interfaces/IERC20.sol";
import "./utils/SafeERC20.sol";
import "./interfaces/IForward.sol";

/// @title Forward Contract
/// @author LI.FI (https://li.fi)
/// @notice Provides functionality for forwarding calldata to li.fi.
contract Forward is IForward, CalldataVerificationFacet {
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
    function extractAmarokData(
        bytes calldata data
    ) external pure override returns (AmarokData memory amarokData) {
        ILiFi.BridgeData memory bridgeData = abi.decode(
            data[4:],
            (ILiFi.BridgeData)
        );
        amarokData = _extractAmarokData(data, bridgeData.hasSourceSwaps);
    }

    /// @inheritdoc IForward
    function extractArbitrumData(
        bytes calldata data
    ) external pure override returns (ArbitrumData memory arbitrumData) {
        ILiFi.BridgeData memory bridgeData = abi.decode(
            data[4:],
            (ILiFi.BridgeData)
        );
        arbitrumData = _extractArbitrumData(data, bridgeData.hasSourceSwaps);
    }

    /// @inheritdoc IForward
    function extractStargateData(
        bytes calldata data
    ) external pure override returns (StargateData memory stargateData) {
        ILiFi.BridgeData memory bridgeData = abi.decode(
            data[4:],
            (ILiFi.BridgeData)
        );
        stargateData = _extractStargateData(data, bridgeData.hasSourceSwaps);
    }

    /// @inheritdoc IForward
    function extractNativeFeeAmount(
        bytes calldata data
    ) external pure override returns (uint256 amount) {
        ILiFi.BridgeData memory bridgeData = abi.decode(
            data[4:],
            (ILiFi.BridgeData)
        );
        bytes32 bridgeName = keccak256(abi.encodePacked(bridgeData.bridge));

        if (bridgeName == keccak256(abi.encodePacked("amarok"))) {
            AmarokData memory amarokData = _extractAmarokData(
                data,
                bridgeData.hasSourceSwaps
            );
            amount = amarokData.relayerFee;
        } else if (bridgeName == keccak256(abi.encodePacked("arbitrum"))) {
            ArbitrumData memory arbitrumData = _extractArbitrumData(
                data,
                bridgeData.hasSourceSwaps
            );
            amount =
                arbitrumData.maxSubmissionCost +
                arbitrumData.maxGas *
                arbitrumData.maxGasPrice;
        } else if (bridgeName == keccak256(abi.encodePacked("stargate"))) {
            StargateData memory stargateData = _extractStargateData(
                data,
                bridgeData.hasSourceSwaps
            );
            amount = stargateData.lzFee;
        }
    }

    /// Internal Methods ///

    /// @notice Extracts Amarok specific data from the calldata.
    /// @param data The calldata to extract the amarok data from.
    /// @param hasSourceSwaps Whether the data has source swaps or not.
    /// @return amarokData Data specific to Amarok.
    function _extractAmarokData(
        bytes calldata data,
        bool hasSourceSwaps
    ) internal pure returns (AmarokData memory amarokData) {
        if (hasSourceSwaps) {
            (, , amarokData) = abi.decode(
                data[4:],
                (ILiFi.BridgeData, LibSwap.SwapData[], AmarokData)
            );
        } else {
            (, amarokData) = abi.decode(
                data[4:],
                (ILiFi.BridgeData, AmarokData)
            );
        }
    }

    /// @notice Extracts Arbitrum specific data from the calldata.
    /// @param data The calldata to extract the arbitrum data from.
    /// @param hasSourceSwaps Whether the data has source swaps or not.
    /// @return arbitrumData Data specific to Arbitrum.
    function _extractArbitrumData(
        bytes calldata data,
        bool hasSourceSwaps
    ) internal pure returns (ArbitrumData memory arbitrumData) {
        if (hasSourceSwaps) {
            (, , arbitrumData) = abi.decode(
                data[4:],
                (ILiFi.BridgeData, LibSwap.SwapData[], ArbitrumData)
            );
        } else {
            (, arbitrumData) = abi.decode(
                data[4:],
                (ILiFi.BridgeData, ArbitrumData)
            );
        }
    }

    /// @notice Extracts Stargate Bridge specific data from the calldata.
    /// @param data The calldata to extract the stargate data from.
    /// @param hasSourceSwaps Whether the data has source swaps or not.
    /// @return stargateData Data specific to Stargate Bridge.
    function _extractStargateData(
        bytes calldata data,
        bool hasSourceSwaps
    ) internal pure returns (StargateData memory stargateData) {
        if (hasSourceSwaps) {
            (, , stargateData) = abi.decode(
                data[4:],
                (ILiFi.BridgeData, LibSwap.SwapData[], StargateData)
            );
        } else {
            (, stargateData) = abi.decode(
                data[4:],
                (ILiFi.BridgeData, StargateData)
            );
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
