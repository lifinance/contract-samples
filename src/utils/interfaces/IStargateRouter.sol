pragma solidity ^0.8.0;

interface IStargateRouter {
    function instantRedeemLocal(
        uint16 srcPoolId,
        uint256 amountLP,
        address to
    ) external;
}
