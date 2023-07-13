// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ILiFi} from "@lifi/Interfaces/ILiFi.sol";
import {LibSwap} from "@lifi/Libraries/LibSwap.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
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

    /// @notice Extracts required native fee amount from the calldata.
    /// @param data The calldata to extract the native fee amount.
    /// @return amount The amount of required native fee.
    function extractNativeFeeAmount(
        bytes calldata data
    ) external returns (uint256 amount);
}
