// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../utils/interfaces/IERC20.sol";

/// @title Events for Forward Contract
interface IForwardEvents {
    event Forwarded(address lifi, IERC20 token, uint256 amount, bytes data);
}
