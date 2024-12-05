// SPDX-License-Identifier: BSD Clause-3
pragma solidity ^0.8.24;

import {IVault} from "lib/yieldnest-vault/src/BaseVault.sol";
import {MockERC20} from "lib/yieldnest-vault/test/unit/mocks/MockERC20.sol";
import {MainnetContracts as MC} from "script/Contracts.sol";

import {IStakerGateway} from "src/interface/external/kernel/IStakerGateway.sol";
import {KernelRateProvider} from "src/module/KernelRateProvider.sol";
import {SetupKernelStrategy} from "test/unit/helpers/SetupKernelStrategy.sol";

contract KernelStrategyDepositUnitTest is SetupKernelStrategy {
    function setUp() public {
        deploy();

        // Give Alice some tokens
        deal(alice, INITIAL_BALANCE);
        wbnb.deposit{value: INITIAL_BALANCE}();
        wbnb.transfer(alice, INITIAL_BALANCE);

        // Approve vault to spend Alice's tokens
        vm.prank(alice);
        wbnb.approve(address(vault), type(uint256).max);
    }

    function test_KernelStrategy_deposit_unauthorized() public {
        vm.prank(address(0x123456));
        vm.expectRevert();
        vault.deposit(1 ether, alice);
    }

    function test_KernelStrategy_deposit_success(uint256 depositAmount) public {
        // uint256 depositAmount = 100 * 10 ** 18;
        if (depositAmount < 10) return;
        if (depositAmount > 100_000 ether) return;

        vm.prank(alice);
        uint256 sharesMinted = vault.deposit(depositAmount, alice);

        // Check that shares were minted
        assertGt(sharesMinted, 0, "No shares were minted");

        // Check that the vault received the tokens
        assertEq(wbnb.balanceOf(address(vault)), depositAmount, "KernelStrategy did not receive tokens");

        // Check that Alice's token balance decreased
        assertEq(wbnb.balanceOf(alice), INITIAL_BALANCE - depositAmount, "Alice's balance did not decrease correctly");

        // Check that Alice received the correct amount of shares
        assertEq(vault.balanceOf(alice), sharesMinted, "Alice did not receive the correct amount of shares");

        // Check that total assets increased
        assertEq(vault.totalAssets(), depositAmount, "Total assets did not increase correctly");
    }

    function test_KernelStrategy_deposit_success_sync(uint256 depositAmount) public {
        // uint256 depositAmount = 100 * 10 ** 18;
        if (depositAmount < 10) return;
        if (depositAmount > 100_000 ether) return;

        vm.prank(ADMIN);
        vault.setSyncDeposit(true);

        uint256 beforeGatewayBalance = wbnb.balanceOf(address(mockGateway));

        vm.prank(alice);
        uint256 sharesMinted = vault.deposit(depositAmount, alice);

        // Check that shares were minted
        assertGt(sharesMinted, 0, "No shares were minted");

        // Check that the vault received the tokens
        assertEq(
            wbnb.balanceOf(address(mockGateway)),
            beforeGatewayBalance + depositAmount,
            "KernelStrategy did not receive tokens"
        );

        // Check that Alice's token balance decreased
        assertEq(wbnb.balanceOf(alice), INITIAL_BALANCE - depositAmount, "Alice's balance did not decrease correctly");

        // Check that Alice received the correct amount of shares
        assertEq(vault.balanceOf(alice), sharesMinted, "Alice did not receive the correct amount of shares");

        // Check that total assets increased
        assertEq(vault.totalAssets(), depositAmount, "Total assets did not increase correctly");

        // Check that the kernel staker gateway received the correct amount of tokens
        assertEq(
            IStakerGateway(address(mockGateway)).balanceOf(address(wbnb), address(vault)),
            depositAmount,
            "KernelStrategy did not receive tokens"
        );
    }

    event Log(string, uint256);

    function test_KernelStrategy_depositAsset_STETH(uint256 depositAmount) public {
        if (depositAmount < 10) return;
        if (depositAmount > 100_000 ether) return;

        deal(address(slisbnb), alice, depositAmount);

        vm.startPrank(alice);

        uint256 previewDepositAsset = vault.previewDepositAsset(address(slisbnb), depositAmount);

        slisbnb.approve(address(vault), depositAmount);

        uint256 sharesMinted = vault.depositAsset(address(slisbnb), depositAmount, alice);

        // Check that shares were minted
        assertGt(sharesMinted, 0, "No shares were minted");
        assertEq(sharesMinted, previewDepositAsset, "Incorrect shares minted");

        // Check that the vault received the tokens
        assertEq(slisbnb.balanceOf(address(vault)), depositAmount, "KernelStrategy did not receive tokens");

        // Check that Alice's token balance decreased
        assertEq(slisbnb.balanceOf(alice), 0, "Alice's balance did not decrease correctly");

        // Check that Alice received the correct amount of shares
        assertEq(vault.balanceOf(alice), sharesMinted, "Alice did not receive the correct amount of shares");

        // Check that total assets increased
        assertEq(vault.totalAssets(), previewDepositAsset, "Total assets did not increase correctly");

        vm.stopPrank();
    }

    function test_KernelStrategy_depositAsset_STETH_sync(uint256 depositAmount) public {
        if (depositAmount < 10) return;
        if (depositAmount > 100_000 ether) return;

        vm.prank(ADMIN);
        vault.setSyncDeposit(true);

        deal(address(slisbnb), alice, depositAmount);

        vm.startPrank(alice);

        uint256 previewDepositAsset = vault.previewDepositAsset(address(slisbnb), depositAmount);

        slisbnb.approve(address(vault), depositAmount);

        uint256 sharesMinted = vault.depositAsset(address(slisbnb), depositAmount, alice);

        // Check that shares were minted
        assertGt(sharesMinted, 0, "No shares were minted");
        assertEq(sharesMinted, previewDepositAsset, "Incorrect shares minted");

        // Check that the vault received the tokens
        assertEq(slisbnb.balanceOf(address(mockGateway)), depositAmount, "KernelStrategy did not receive tokens");

        // Check that Alice's token balance decreased
        assertEq(slisbnb.balanceOf(alice), 0, "Alice's balance did not decrease correctly");

        // Check that Alice received the correct amount of shares
        assertEq(vault.balanceOf(alice), sharesMinted, "Alice did not receive the correct amount of shares");

        // Check that total assets increased
        assertEq(vault.totalAssets(), previewDepositAsset, "Total assets did not increase correctly");

        // Check that the kernel staker gateway received the correct amount of tokens
        assertEq(
            IStakerGateway(address(mockGateway)).balanceOf(address(slisbnb), address(vault)),
            depositAmount,
            "KernelStrategy did not receive tokens"
        );

        vm.stopPrank();
    }

    function test_KernelStrategy_mint(uint256 mintAmount) public {
        if (mintAmount < 10) return;
        if (mintAmount > 100_000 ether) return;

        vm.startPrank(alice);
        uint256 sharesMinted = vault.mint(mintAmount, alice);

        // Check that shares were minted
        assertGt(sharesMinted, 0, "No shares were minted");

        // Check that Alice received the correct amount of shares
        assertEq(vault.balanceOf(alice), sharesMinted, "Alice did not receive the correct amount of shares");

        // Check that total assets did not change
        assertEq(vault.totalAssets(), mintAmount, "Total assets changed incorrectly");

        vm.stopPrank();
    }

    function test_KernelStrategy_depositAsset_WrongAsset() public {
        vm.prank(alice);
        vm.expectRevert();
        vault.depositAsset(address(0), 100, alice);
    }

    function test_KernelStrategy_depositAssetWhilePaused() public {
        vm.prank(ADMIN);
        vault.pause();
        assertEq(vault.paused(), true);

        vm.prank(alice);
        vm.expectRevert();
        vault.depositAsset(address(0), 1000, alice);
    }

    function test_KernelStrategy_mintWhilePaused() public {
        vm.prank(ADMIN);
        vault.pause();
        assertEq(vault.paused(), true);

        vm.prank(alice);
        vm.expectRevert();
        vault.mint(1000, alice);
    }

    function test_KernelStrategy_pauseAndDeposit() public {
        vm.prank(ADMIN);
        vault.pause();
        assertEq(vault.paused(), true);

        vm.prank(alice);
        vm.expectRevert();
        vault.deposit(1000, alice);
    }

    function test_KernelStrategy_maxMint() public view {
        uint256 maxMint = vault.maxMint(alice);
        assertEq(maxMint, type(uint256).max, "Max mint does not match");
    }

    function test_KernelStrategy_previewDeposit() public view {
        uint256 assets = 1000;
        uint256 expectedShares = 1000; // Assuming a 1:1 conversion for simplicity
        uint256 shares = vault.previewDeposit(assets);
        assertEq(shares, expectedShares, "Preview deposit does not match expected shares");
    }

    function test_KernelStrategy_previewMint() public view {
        uint256 shares = 1000;
        uint256 expectedAssets = 1000; // Assuming a 1:1 conversion for simplicity
        uint256 assets = vault.previewMint(shares);
        assertEq(assets, expectedAssets, "Preview mint does not match expected assets");
    }

    function test_KernelStrategy_getAsset() public view {
        address assetAddress = MC.WBNB;
        IVault.AssetParams memory expectedAssetParams = IVault.AssetParams({active: true, index: 0, decimals: 18});
        assertEq(vault.getAsset(assetAddress).active, expectedAssetParams.active);
        assertEq(vault.getAsset(assetAddress).index, expectedAssetParams.index);
        assertEq(vault.getAsset(assetAddress).decimals, expectedAssetParams.decimals);
    }

    function test_KernelStrategy_maxDeposit() public view {
        uint256 maxDeposit = vault.maxDeposit(alice);
        assertEq(maxDeposit, type(uint256).max, "Max deposit does not match");
    }

    function test_KernelStrategy_previewDepositAsset() public view {
        uint256 assets = 1000;
        uint256 expectedShares = 1000; // Assuming a 1:1 conversion for simplicity
        uint256 shares = vault.previewDepositAsset(MC.WBNB, assets);
        assertEq(shares, expectedShares, "Preview deposit asset does not match expected shares");
    }

    function test_KernelStrategy_previewDepositAsset_WrongAsset() public {
        address invalidAssetAddress = address(0);
        uint256 assets = 1000;
        vm.expectRevert();
        vault.previewDepositAsset(invalidAssetAddress, assets);
    }

    function test_KernelStrategy_maxMint_whenPaused_shouldRevert() public {
        // Pause the vault
        vm.prank(ADMIN);
        vault.pause();

        // Expect revert when calling maxMint while paused
        assertEq(vault.maxMint(alice), 0, "Should be zero when paused");
    }

    function test_KernelStrategy_maxRedeem_whenPaused_shouldRevert() public {
        // Pause the vault
        vm.prank(ADMIN);
        vault.pause();

        // Expect revert when calling maxRedeem while paused
        assertEq(vault.maxRedeem(alice), 0, "Should be zero when paused");
    }

    function test_KernelStrategy_receiveETH(uint256 depositAmount) public {
        if (depositAmount < 1 || depositAmount > 100_000_00 ether) return;

        (bool success,) = address(vault).call{value: depositAmount}("");
        assertTrue(success, "Deposit eth failed");
        vault.processAccounting();

        // Check the shares minted
        uint256 assets = vault.totalAssets();
        assertEq(depositAmount, assets, "No shares minted");
    }

    function test_KernelStrategy_depositAsset_InvalidAsset() public {
        // Deploy a random ERC20 token that hasn't been added to vault
        MockERC20 randomToken = new MockERC20("Random", "RND");

        vm.startPrank(alice);
        // Mint some tokens to alice
        randomToken.mint(1000);

        // Try to deposit the random token
        randomToken.approve(address(vault), 1000);
        bytes memory encodedError =
            abi.encodeWithSelector(KernelRateProvider.UnsupportedAsset.selector, address(randomToken));
        vm.expectRevert(encodedError);
        vault.depositAsset(address(randomToken), 1000, alice);
        vm.stopPrank();
    }

    function test_maxDeposit_is_zero_when_paused() public {
        // Pause the vault
        vm.startPrank(PAUSER);
        vault.pause();

        // Check that maxDeposit is zero for Alice
        uint256 maxDepositAmount = vault.maxDeposit(alice);
        assertEq(maxDepositAmount, 0, "maxDeposit should be zero when paused");

        // Unpause the vault
        vm.startPrank(UNPAUSER);
        vault.unpause();

        // Check that maxDeposit is no longer zero for Alice
        maxDepositAmount = vault.maxDeposit(alice);
        assertGt(maxDepositAmount, 0, "maxDeposit should not be zero when unpaused");
    }
}
