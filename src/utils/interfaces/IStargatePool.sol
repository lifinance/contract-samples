pragma solidity ^0.8.0;

interface IStargatePool {
    function poolId() external returns (uint256);

    function token() external returns (address);

    function router() external returns (address);
}
