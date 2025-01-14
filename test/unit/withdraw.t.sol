// SPDX-License-Identifier: BSD Clause-3
pragma solidity ^0.8.24;

import {IVault} from "lib/yieldnest-vault/src/BaseVault.sol";

import {IERC20} from "lib/yieldnest-vault/src/Common.sol";
import {MainnetContracts as MC} from "script/Contracts.sol";

import {KernelStrategy} from "src/KernelStrategy.sol";
import {SetupKernelStrategy} from "test/unit/helpers/SetupKernelStrategy.sol";

contract KernelStrategyWithdrawUnitTest is SetupKernelStrategy {
    function setUp() public {
        deploy();

        // Give Alice some tokens
        deal(alice, INITIAL_BALANCE);
        wbnb.deposit{value: INITIAL_BALANCE}();
        wbnb.transfer(alice, INITIAL_BALANCE);

        // Approve vault to spend Alice's tokens
        vm.prank(alice);
        wbnb.approve(address(vault), type(uint256).max);

        vm.startPrank(ADMIN);
        setStakingRule(vault, address(mockGateway), address(wbnb));
        setApprovalRule(vault, address(wbnb), address(mockGateway));
        vm.stopPrank();
    }

    function stakeIntoKernel(address asset, uint256 amount) public {
        address[] memory targets = new address[](2);
        targets[0] = asset;
        targets[1] = address(mockGateway);

        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSignature("approve(address,uint256)", address(mockGateway), amount);
        data[1] = abi.encodeWithSignature("stake(address,uint256,string)", asset, amount, "");

        vm.prank(ADMIN);
        vault.processor(targets, values, data);

        vault.processAccounting();
    }

    function test_KernelStrategy_ynBNBk_withdraw_revert_whilePaused() public {
        vm.prank(ADMIN);
        vault.pause();
        assertEq(vault.paused(), true);

        vm.prank(alice);
        vm.expectRevert(IVault.Paused.selector);
        vault.withdrawAsset(MC.WBNB, 1000, alice, alice);
    }

    function test_KernelStrategy_ynBNBk_withdraw_maxWithdraw(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, 10, INITIAL_BALANCE);
        // deposit amount
        vm.prank(alice);
        vault.deposit(depositAmount, alice);

        assertEq(vault.maxWithdrawAsset(MC.WBNB, alice), depositAmount);
    }

    function test_KernelStrategy_ynBNBk_withdraw_previewWithdrawAsset(uint256 depositAmount, uint256 withdrawalAmount)
        public
    {
        depositAmount = bound(depositAmount, 11, INITIAL_BALANCE);
        withdrawalAmount = bound(withdrawalAmount, 10, depositAmount);
        // deposit amount
        vm.prank(alice);
        vault.deposit(depositAmount, alice);

        assertEq(depositAmount, vault.previewWithdrawAsset(MC.WBNB, depositAmount), "invalid withdraw preview");
    }

    function test_KernelStrategy_ynBNBk_withdraw_previewRedeemAsset(uint256 depositAmount, uint256 withdrawalAmount)
        public
    {
        depositAmount = bound(depositAmount, 11, INITIAL_BALANCE);
        withdrawalAmount = bound(withdrawalAmount, 10, depositAmount);
        // deposit amount
        vm.prank(alice);
        uint256 shares = vault.deposit(depositAmount, alice);

        assertEq(depositAmount, vault.previewRedeemAsset(MC.WBNB, shares), "invalid withdraw preview");
    }

    function test_KernelStrategy_ynBNBk_withdraw_maxWithdraw_isZero_whenPaused() public {
        // deposit amount
        vm.prank(alice);
        vault.deposit(1 ether, alice);

        assertEq(vault.maxWithdrawAsset(MC.WBNB, alice), 1 ether);

        vm.prank(ADMIN);
        vault.pause();
        assertEq(vault.paused(), true);

        vm.prank(alice);
        uint256 shouldBeZero = vault.maxWithdrawAsset(MC.WBNB, alice);
        assertEq(shouldBeZero, 0, "maxwithdraw is not zero");
    }

    function test_KernelStrategy_ynBNBk_withdraw_maxRedeem_isZero_whenPaused() public {
        // deposit amount
        vm.prank(alice);
        uint256 shares = vault.deposit(1 ether, alice);

        assertEq(vault.maxRedeem(alice), shares);

        vm.prank(ADMIN);
        vault.pause();
        assertEq(vault.paused(), true);

        vm.prank(alice);
        uint256 shouldBeZero = vault.maxRedeem(alice);
        assertEq(shouldBeZero, 0, "maxRedeem is not zero");
    }

    // todo should this revert?
    function test_KernelStrategy_ynBNBk_withdraw_zeroAmount() public {
        // deposit amount
        vm.startPrank(alice);
        vault.deposit(1 ether, alice);

        vault.withdrawAsset(address(MC.WBNB), 0, alice, alice);
    }

    function test_KernelStrategy_ynBNBk_withdraw_revert_zeroAddress(uint256 withdrawalAmount) public {
        // uint256 withdrawalAmount = 100 * 10 ** 18;
        if (withdrawalAmount < 10) return;
        if (withdrawalAmount > INITIAL_BALANCE) return;

        // deposit amount
        vm.startPrank(alice);
        vault.deposit(withdrawalAmount, alice);

        vm.expectRevert(IVault.ZeroAddress.selector);
        vault.withdrawAsset(address(0), withdrawalAmount, alice, alice);
    }

    function test_KernelStrategy_ynBNBk_withdraw_revert_wrongAsset(uint256 withdrawalAmount) public {
        // uint256 withdrawalAmount = 100 * 10 ** 18;
        if (withdrawalAmount < 10) return;
        if (withdrawalAmount > INITIAL_BALANCE) return;

        // deposit amount
        vm.startPrank(alice);
        vault.deposit(withdrawalAmount, alice);

        vm.expectRevert();
        vault.withdrawAsset(MC.SLISBNB, withdrawalAmount, alice, alice);
    }

    function test_KernelStrategy_ynBNBk_withdraw_revert_insufficientShares(
        uint256 withdrawalAmount,
        uint256 depositAmount
    ) public {
        withdrawalAmount = bound(withdrawalAmount, 11, INITIAL_BALANCE);
        depositAmount = bound(depositAmount, 10, withdrawalAmount - 1);

        // deposit amount
        vm.startPrank(alice);
        vault.deposit(depositAmount, alice);

        vm.expectRevert(
            abi.encodeWithSelector(
                IVault.ExceededMaxWithdraw.selector, alice, withdrawalAmount, vault.maxWithdraw(alice)
            )
        );
        vault.withdrawAsset(address(MC.WBNB), withdrawalAmount, alice, alice);
    }

    function test_KernelStrategy_ynBNBk_withdraw_revert_wnbnb_sync_disabled_exceededMaxWithdraw(
        uint256 withdrawalAmount
    ) public {
        // uint256 withdrawalAmount = 100 * 10 ** 18;
        if (withdrawalAmount < 10) return;
        if (withdrawalAmount > INITIAL_BALANCE) return;

        IERC20 asset = IERC20(address(MC.WBNB));
        // deposit amount
        vm.prank(alice);
        vault.deposit(withdrawalAmount, alice);

        // disable withdraw sync
        vm.prank(ADMIN);
        vault.setSyncWithdraw(false);

        uint256 maxWithdraw = vault.maxWithdrawAsset(address(asset), alice);
        assertGt(maxWithdraw, 0, "maxWithdraw is 0");

        //stake funds in vault
        stakeIntoKernel(address(asset), withdrawalAmount);

        uint256 beforeAliceBalance = asset.balanceOf(alice);
        uint256 beforeAliceShares = vault.balanceOf(alice);

        assertEq(asset.balanceOf(address(vault)), 0, "vault still has wbnb");

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IVault.ExceededMaxWithdraw.selector, alice, maxWithdraw, 0));
        uint256 shares = vault.withdrawAsset(address(asset), withdrawalAmount, alice, alice);

        assertEq(shares, 0, "Shares should be 0");

        assertEq(asset.balanceOf(address(vault)), 0, "Vault balance should be 0");
        assertEq(asset.balanceOf(alice), beforeAliceBalance, "Alice balance should not increase");
        assertEq(vault.balanceOf(alice), beforeAliceShares, "Alice shares should not decrease");
    }

    function test_KernelStrategy_ynBNBk_withdraw_success_wbnb_sync_disabled(uint256 withdrawalAmount) public {
        // uint256 withdrawalAmount = 100 * 10 ** 18;
        if (withdrawalAmount < 10) return;
        if (withdrawalAmount > INITIAL_BALANCE) return;

        IERC20 asset = IERC20(address(MC.WBNB));
        // deposit amount
        vm.prank(alice);
        vault.deposit(withdrawalAmount, alice);

        // disable withdraw sync
        vm.prank(ADMIN);
        vault.setSyncWithdraw(false);

        uint256 maxWithdraw = vault.maxWithdrawAsset(address(asset), alice);
        assertGt(maxWithdraw, 0, "maxWithdraw is 0");

        //stake funds in vault
        stakeIntoKernel(address(asset), withdrawalAmount);

        uint256 beforeAliceBalance = asset.balanceOf(alice);
        uint256 beforeAliceShares = vault.balanceOf(alice);

        vault.processAccounting();

        assertEq(asset.balanceOf(address(vault)), 0, "Vault balance should be 0");
        assertEq(asset.balanceOf(alice), beforeAliceBalance, "Alice balance should not increase");
        assertEq(vault.balanceOf(alice), beforeAliceShares, "Alice shares should not decrease");

        // set unstaking rule
        vm.prank(ADMIN);
        setUnstakingRule(vault, address(mockGateway), address(asset));

        address[] memory targets = new address[](1);
        targets[0] = address(mockGateway);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("unstake(address,uint256,string)", address(asset), withdrawalAmount, "");

        vm.prank(ADMIN);
        vault.processor(targets, values, data);

        vault.processAccounting();

        assertEq(asset.balanceOf(address(vault)), withdrawalAmount, "Vault balance should be withdrawalAmount");
        assertEq(asset.balanceOf(alice), beforeAliceBalance, "Alice balance should not increase");
        assertEq(vault.balanceOf(alice), beforeAliceShares, "Alice shares should not decrease");

        maxWithdraw = vault.maxWithdrawAsset(address(asset), alice);

        assertEqThreshold(maxWithdraw, withdrawalAmount, 2, "maxWithdraw should be equal to withdrawalAmount");

        vm.expectEmit();
        emit KernelStrategy.WithdrawAsset(
            alice, alice, alice, address(asset), withdrawalAmount, vault.previewWithdraw(withdrawalAmount)
        );

        // withdraw for real
        vm.prank(alice);
        uint256 shares = vault.withdrawAsset(address(asset), maxWithdraw, alice, alice);

        assertEq(asset.balanceOf(address(vault)), withdrawalAmount - maxWithdraw, "Vault balance should be 0");
        assertEq(asset.balanceOf(alice), beforeAliceBalance + maxWithdraw, "Alice balance should increase");
        assertEq(vault.balanceOf(alice), beforeAliceShares - shares, "Alice shares should decrease");
    }

    function test_KernelStrategy_ynBNBk_redeem_success_wbnb_sync_disabled(uint256 withdrawalAmount) public {
        // uint256 withdrawalAmount = 100 * 10 ** 18;
        if (withdrawalAmount < 10) return;
        if (withdrawalAmount > INITIAL_BALANCE) return;

        IERC20 asset = IERC20(address(MC.WBNB));
        // deposit amount
        vm.prank(alice);
        uint256 shares = vault.deposit(withdrawalAmount, alice);

        // disable withdraw sync
        vm.prank(ADMIN);
        vault.setSyncWithdraw(false);

        uint256 maxRedeem = vault.maxRedeem(alice);
        assertGt(maxRedeem, 0, "maxRedeem is 0");

        //stake funds in vault
        stakeIntoKernel(address(asset), withdrawalAmount);

        uint256 beforeAliceBalance = asset.balanceOf(alice);
        uint256 beforeAliceShares = vault.balanceOf(alice);

        vault.processAccounting();

        assertEq(asset.balanceOf(address(vault)), 0, "Vault balance should be 0");
        assertEq(asset.balanceOf(alice), beforeAliceBalance, "Alice balance should not increase");
        assertEq(vault.balanceOf(alice), beforeAliceShares, "Alice shares should not decrease");

        // set unstaking rule
        vm.prank(ADMIN);
        setUnstakingRule(vault, address(mockGateway), address(asset));
        {
            address[] memory targets = new address[](1);
            targets[0] = address(mockGateway);

            uint256[] memory values = new uint256[](1);
            values[0] = 0;

            bytes[] memory data = new bytes[](1);
            data[0] = abi.encodeWithSignature("unstake(address,uint256,string)", address(asset), withdrawalAmount, "");

            vm.prank(ADMIN);
            vault.processor(targets, values, data);
        }
        vault.processAccounting();

        assertEq(asset.balanceOf(address(vault)), withdrawalAmount, "Vault balance should be withdrawalAmount");
        assertEq(asset.balanceOf(alice), beforeAliceBalance, "Alice balance should not increase");
        assertEq(vault.balanceOf(alice), beforeAliceShares, "Alice shares should not decrease");

        maxRedeem = vault.maxRedeem(alice);

        assertEqThreshold(maxRedeem, withdrawalAmount, 2, "maxRedeem should be equal to withdrawalAmount");

        vm.expectEmit();
        emit KernelStrategy.WithdrawAsset(
            alice, alice, alice, address(asset), withdrawalAmount, vault.previewWithdraw(withdrawalAmount)
        );

        // withdraw for real
        vm.prank(alice);
        shares = vault.redeemAsset(address(asset), maxRedeem, alice, alice);

        assertEq(asset.balanceOf(address(vault)), withdrawalAmount - maxRedeem, "Vault balance should be 0");
        assertEq(asset.balanceOf(alice), beforeAliceBalance + maxRedeem, "Alice balance should increase");
        assertEq(vault.balanceOf(alice), beforeAliceShares - shares, "Alice shares should decrease");
    }

    function test_KernelStrategy_ynBNBk_withdraw_success_wbnb_sync_enabled(uint256 withdrawalAmount) public {
        // uint256 withdrawalAmount = 100 * 10 ** 18;
        if (withdrawalAmount < 10) return;
        if (withdrawalAmount > INITIAL_BALANCE) return;

        // enable withdraw sync
        vm.startPrank(ADMIN);
        vault.setSyncDeposit(true);
        vault.setSyncWithdraw(true);
        vm.stopPrank();

        IERC20 asset = IERC20(address(MC.WBNB));

        // deposit amount
        vm.prank(alice);
        vault.deposit(withdrawalAmount, alice);

        uint256 maxWithdraw = vault.maxWithdrawAsset(address(asset), alice);

        assertEq(vault.balanceOf(alice), withdrawalAmount, "alice has incorrect shares");
        assertEqThreshold(maxWithdraw, withdrawalAmount, 2, "Max withdraw should be equal to withdrawalAmount");

        uint256 beforeAliceBalance = asset.balanceOf(alice);
        uint256 beforeAliceShares = vault.balanceOf(alice);

        assertEq(asset.balanceOf(address(vault)), 0, "vault still has wbnb");

        vm.expectEmit();
        emit KernelStrategy.WithdrawAsset(
            alice, alice, alice, address(asset), withdrawalAmount, vault.previewWithdraw(withdrawalAmount)
        );
        vm.prank(alice);
        uint256 shares = vault.withdrawAsset(address(asset), withdrawalAmount, alice, alice);

        assertEq(asset.balanceOf(address(vault)), withdrawalAmount - maxWithdraw, "Vault balance should be 0");
        assertEq(asset.balanceOf(alice), beforeAliceBalance + maxWithdraw, "Alice balance should increase");
        assertEq(vault.balanceOf(alice), beforeAliceShares - shares, "Alice shares should decrease");
    }

    function test_KernelStrategy_ynBNBk_redeem_wbnb_sync_enabled(uint256 redeemAmount, uint256 depositAmount) public {
        redeemAmount = bound(redeemAmount, 10, INITIAL_BALANCE);
        depositAmount = bound(depositAmount, redeemAmount, INITIAL_BALANCE);

        // enable withdraw sync
        vm.startPrank(ADMIN);
        vault.setSyncDeposit(true);
        vault.setSyncWithdraw(true);
        vm.stopPrank();

        IERC20 asset = IERC20(address(MC.WBNB));

        // deposit amount
        vm.prank(alice);
        uint256 shares = vault.deposit(redeemAmount, alice);

        uint256 maxRedeem = vault.maxRedeem(alice);

        assertEq(vault.balanceOf(alice), redeemAmount, "alice has incorrect shares");
        assertEqThreshold(maxRedeem, redeemAmount, 2, "Max withdraw should be equal to redeemAmount");

        uint256 beforeAliceBalance = asset.balanceOf(alice);
        uint256 beforeAliceShares = vault.balanceOf(alice);

        assertEq(asset.balanceOf(address(vault)), 0, "vault still has wbnb");

        vm.expectEmit();
        emit KernelStrategy.WithdrawAsset(
            alice, alice, alice, address(asset), redeemAmount, vault.previewRedeem(redeemAmount)
        );
        vm.prank(alice);
        shares = vault.redeemAsset(address(asset), redeemAmount, alice, alice);

        assertEq(asset.balanceOf(address(vault)), redeemAmount - maxRedeem, "Vault balance should be 0");
        assertEq(asset.balanceOf(alice), beforeAliceBalance + maxRedeem, "Alice balance should increase");
        assertEq(vault.balanceOf(alice), beforeAliceShares - shares, "Alice shares should decrease");
    }
}
