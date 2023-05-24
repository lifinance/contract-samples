// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Errors for Forward Contract
interface IForwardErrors {
    error SpenderIsInvalid();
    error FailedToForward(bytes);
}
