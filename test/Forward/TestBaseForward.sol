// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";
import {ILiFi} from "@lifi/Interfaces/ILiFi.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "src/interfaces/IForwardErrors.sol";
import "src/interfaces/IForwardEvents.sol";
import "src/interfaces/IForwardTypes.sol";
import "src/Forward.sol";
import "forge-std/console.sol";

abstract contract TestBaseForward is
    Test,
    IForwardErrors,
    IForwardEvents,
    IForwardTypes
{
    using SafeERC20 for IERC20;

    address LIFI = 0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address RECEIVER = 0xf0ad40Df0AD40DF0Ad40DF0Ad40df0Ad40df0Ad4;

    bytes DATA_WITH_NON_NATIVE_ASSET;
    bytes DATA_WITH_NATIVE_ASSET;

    address sendingAssetId;
    uint256 sendingAmount;
    uint256 sendingNativeAmount;

    Forward forwardContract;

    function setUp() public virtual {
        _fork();

        forwardContract = new Forward();

        sendingAssetId = USDT;
        sendingAmount = 10e6;
        sendingNativeAmount = 1e18;

        deal(sendingAssetId, address(this), 1_000e6);
    }

    function test_forward_fail_withNonNativeAsset_whenAllowanceIsLow()
        public
        virtual
    {
        vm.expectRevert();
        forwardContract.forward(
            LIFI,
            IERC20(sendingAssetId),
            sendingAmount,
            DATA_WITH_NON_NATIVE_ASSET
        );
    }

    function test_forward_fail_withNonNativeAsset_whenNoEnoughFee()
        public
        virtual
    {
        IERC20(sendingAssetId).safeApprove(
            address(forwardContract),
            type(uint256).max
        );

        vm.expectRevert();
        forwardContract.forward(
            LIFI,
            IERC20(sendingAssetId),
            sendingAmount,
            DATA_WITH_NON_NATIVE_ASSET
        );
    }

    function test_forward_success_withNonNativeAsset() public virtual {
        _forward(false, 0);
    }

    function test_forward_fail_withNativeAsset_whenMsgValueIsLow()
        public
        virtual
    {
        vm.expectRevert();
        forwardContract.forward{value: sendingNativeAmount - 1}(
            LIFI,
            IERC20(address(0)),
            sendingNativeAmount,
            DATA_WITH_NATIVE_ASSET
        );
    }

    function test_forward_success_withNativeAsset() public virtual {
        _forward(true, 0);
    }

    function _fork() internal virtual {
        vm.createSelectFork(vm.envString("ETH_NODE_URI_MAINNET"), 17276300);
    }

    function _forward(bool isNative, uint256 fee) internal virtual {
        if (isNative) {
            vm.expectEmit(true, true, true, true, address(forwardContract));
            emit Forwarded(
                LIFI,
                IERC20(address(0)),
                sendingNativeAmount,
                DATA_WITH_NATIVE_ASSET
            );

            forwardContract.forward{value: sendingNativeAmount + fee}(
                LIFI,
                IERC20(address(0)),
                sendingNativeAmount,
                DATA_WITH_NATIVE_ASSET
            );
        } else {
            IERC20(sendingAssetId).safeApprove(
                address(forwardContract),
                type(uint256).max
            );

            vm.expectEmit(true, true, true, true, address(forwardContract));
            emit Forwarded(
                LIFI,
                IERC20(sendingAssetId),
                sendingAmount,
                DATA_WITH_NON_NATIVE_ASSET
            );

            forwardContract.forward{value: fee}(
                LIFI,
                IERC20(sendingAssetId),
                sendingAmount,
                DATA_WITH_NON_NATIVE_ASSET
            );
        }
    }
}
