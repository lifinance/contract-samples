pragma solidity ^0.8.0;

interface IBeefyVault {
    function withdraw(uint256 shares) external;

    function want() external returns (address);
}
