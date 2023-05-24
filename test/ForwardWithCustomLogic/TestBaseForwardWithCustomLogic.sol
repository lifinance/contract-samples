// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";
import "src/interfaces/IForwardErrors.sol";
import "src/interfaces/IForwardEvents.sol";
import "src/interfaces/IForwardTypes.sol";
import "src/utils/interfaces/IBeefyVault.sol";
import "src/utils/interfaces/IERC20.sol";
import "src/utils/SafeERC20.sol";
import "src/ForwardWithCustomLogic.sol";
import "forge-std/console.sol";

abstract contract TestBaseForwardWithCustomLogic is
    Test,
    IForwardErrors,
    IForwardEvents,
    IForwardTypes
{
    using SafeERC20 for IERC20;

    event ForwardedWithCustomLogic(
        IBeefyVault usdtBeefyVault,
        uint256 shares,
        address lifi,
        IERC20 token,
        uint256 amount,
        bytes data
    );

    error TokensMismatch(address token, address actual);

    address LIFI = 0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address RECEIVER = 0xf0ad40Df0AD40DF0Ad40DF0Ad40df0Ad40df0Ad4;
    address MOO_STARGATE_USDT = 0x61cf8d861ff3c939147c2aa1F694f9592Bf51983;
    address MOO_STARGATE_ETH = 0x4dd0cF20237deb5F2bE76340838B9e2D7c70E852;
    address MOO_STARGATE_USDT_HOLDER =
        0x63220B5e9272Ec6421F9993D5cBB3cAb66038ed4;
    address MOO_STARGATE_ETH_HOLDER =
        0x788Df1CF86747F24f52e6445Ffc0E5Ae5bd12437;

    bytes DATA_WITH_NON_NATIVE_ASSET;
    bytes DATA_WITH_NATIVE_ASSET;

    address sendingAssetId;
    uint256 sendingAmount;
    uint256 sendingNativeAmount;
    address usdtBeefyVault;
    address ethBeefyVault;
    uint256 mooUSDTAmount;
    uint256 mooETHAmount;

    ForwardWithCustomLogic forwardContract;

    function setUp() public virtual {
        _fork();

        forwardContract = new ForwardWithCustomLogic();

        sendingAssetId = USDT;
        usdtBeefyVault = MOO_STARGATE_USDT;
        ethBeefyVault = MOO_STARGATE_ETH;
        sendingAmount = 10e6;
        sendingNativeAmount = 1e18;
        mooUSDTAmount = 12e6;
        mooETHAmount = 1e18;

        vm.prank(MOO_STARGATE_USDT_HOLDER);
        IERC20(usdtBeefyVault).transfer(address(this), mooUSDTAmount);

        vm.prank(MOO_STARGATE_ETH_HOLDER);
        IERC20(ethBeefyVault).transfer(address(this), mooETHAmount);
    }

    function test_forwardWithCustomLogic_fail_withNonNativeAsset_whenAllowanceIsLow()
        public
        virtual
    {
        vm.expectRevert();
        forwardContract.forwardWithCustomLogic(
            IBeefyVault(usdtBeefyVault),
            mooUSDTAmount,
            LIFI,
            IERC20(sendingAssetId),
            sendingAmount,
            DATA_WITH_NON_NATIVE_ASSET
        );
    }

    function test_forwardWithCustomLogic_fail_withNonNativeAsset_whenTokensMismatch()
        public
        virtual
    {
        IERC20(usdtBeefyVault).safeApprove(
            address(forwardContract),
            type(uint256).max
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                TokensMismatch.selector,
                address(1),
                sendingAssetId
            )
        );
        forwardContract.forwardWithCustomLogic(
            IBeefyVault(usdtBeefyVault),
            mooUSDTAmount,
            LIFI,
            IERC20(address(1)),
            sendingAmount,
            DATA_WITH_NON_NATIVE_ASSET
        );
    }

    function test_forwardWithCustomLogic_fail_withNonNativeAsset_whenWithdrawnAmountIsLow()
        public
        virtual
    {
        IERC20(usdtBeefyVault).safeApprove(
            address(forwardContract),
            type(uint256).max
        );

        vm.expectRevert();
        forwardContract.forwardWithCustomLogic(
            IBeefyVault(usdtBeefyVault),
            mooUSDTAmount,
            LIFI,
            IERC20(sendingAssetId),
            sendingAmount + 1e18,
            DATA_WITH_NON_NATIVE_ASSET
        );
    }

    function test_forwardWithCustomLogic_fail_withNonNativeAsset_whenNoEnoughFee()
        public
        virtual
    {
        IERC20(usdtBeefyVault).safeApprove(
            address(forwardContract),
            type(uint256).max
        );

        vm.expectRevert();
        forwardContract.forwardWithCustomLogic(
            IBeefyVault(usdtBeefyVault),
            mooUSDTAmount,
            LIFI,
            IERC20(sendingAssetId),
            sendingAmount,
            DATA_WITH_NON_NATIVE_ASSET
        );
    }

    function test_forwardWithCustomLogic_success_withNonNativeAsset()
        public
        virtual
    {
        _forwardWithCustomLogic(false, 0);
    }

    function test_forwardWithCustomLogic_fail_withNativeAsset_whenMsgValueIsLow()
        public
        virtual
    {
        vm.expectRevert();
        forwardContract.forwardWithCustomLogic{value: sendingNativeAmount - 1}(
            IBeefyVault(usdtBeefyVault),
            mooUSDTAmount,
            LIFI,
            IERC20(address(0)),
            sendingNativeAmount,
            DATA_WITH_NATIVE_ASSET
        );
    }

    function test_forwardWithCustomLogic_success_withNativeAsset()
        public
        virtual
    {
        _forwardWithCustomLogic(true, 0);
    }

    function _fork() internal virtual {
        vm.createSelectFork(vm.envString("ETH_NODE_URI_MAINNET"), 17276300);
    }

    function _forwardWithCustomLogic(
        bool isNative,
        uint256 fee
    ) internal virtual {
        if (isNative) {
            IERC20(ethBeefyVault).safeApprove(
                address(forwardContract),
                type(uint256).max
            );

            vm.expectEmit(true, true, true, true, address(forwardContract));
            emit ForwardedWithCustomLogic(
                IBeefyVault(ethBeefyVault),
                mooETHAmount,
                LIFI,
                IERC20(address(0)),
                sendingNativeAmount,
                DATA_WITH_NATIVE_ASSET
            );

            forwardContract.forwardWithCustomLogic{
                value: sendingNativeAmount + fee
            }(
                IBeefyVault(ethBeefyVault),
                mooETHAmount,
                LIFI,
                IERC20(address(0)),
                sendingNativeAmount,
                DATA_WITH_NATIVE_ASSET
            );
        } else {
            IERC20(usdtBeefyVault).safeApprove(
                address(forwardContract),
                type(uint256).max
            );

            vm.expectEmit(true, true, true, true, address(forwardContract));
            emit ForwardedWithCustomLogic(
                IBeefyVault(usdtBeefyVault),
                mooUSDTAmount,
                LIFI,
                IERC20(sendingAssetId),
                sendingAmount,
                DATA_WITH_NON_NATIVE_ASSET
            );

            forwardContract.forwardWithCustomLogic{value: fee}(
                IBeefyVault(usdtBeefyVault),
                mooUSDTAmount,
                LIFI,
                IERC20(sendingAssetId),
                sendingAmount,
                DATA_WITH_NON_NATIVE_ASSET
            );
        }
    }
}
