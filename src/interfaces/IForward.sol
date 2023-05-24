// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../utils/interfaces/IERC20.sol";
import "./IForwardErrors.sol";
import "./IForwardEvents.sol";
import "./IForwardTypes.sol";

/// @title Interface for Forward Contract
interface IForward is IForwardErrors, IForwardEvents, IForwardTypes {
    /// @notice Forward call data to li.fi contract.
    /// @param lifi The address of li.fi contract.
    /// @param token The address of token to send.
    /// @param amount The Amount of token to send.
    /// @param data The calldata to forward.
    function forward(
        address lifi,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) external payable;

    /// @notice Extracts the bridge data from the calldata.
    /// @param data The calldata to extract the bridge data from.
    /// @return bridgeData The bridge data extracted from the calldata.
    function extractBridgeData(
        bytes calldata data
    ) external pure returns (BridgeData memory bridgeData);

    /// @notice Extracts the swap data from the calldata.
    /// @param data The calldata to extract the swap data from.
    /// @return swapData The swap data extracted from the calldata.
    function extractSwapData(
        bytes calldata data
    ) external pure returns (SwapData[] memory swapData);

    /// @notice Extracts Amarok specific data from the calldata.
    /// @param data The calldata to extract the amarok data from.
    /// @return amarokData Data specific to Amarok.
    function extractAmarokData(
        bytes calldata data
    ) external pure returns (AmarokData memory amarokData);

    /// @notice Extracts Arbitrum specific data from the calldata.
    /// @param data The calldata to extract the arbitrum data from.
    /// @return arbitrumData Data specific to Arbitrum.
    function extractArbitrumData(
        bytes calldata data
    ) external pure returns (ArbitrumData memory arbitrumData);

    /// @notice Extracts Stargate Bridge specific data from the calldata.
    /// @param data The calldata to extract the stargate data from.
    /// @return stargateData Data specific to Stargate Bridge.
    function extractStargateData(
        bytes calldata data
    ) external pure returns (StargateData memory stargateData);
}
