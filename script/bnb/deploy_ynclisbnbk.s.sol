// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.24;

import {IProvider} from "lib/yieldnest-vault/src/interface/IProvider.sol";

import {KernelStrategy} from "src/KernelStrategy.sol";
import {BNBRateProvider, TestnetBNBRateProvider} from "src/module/BNBRateProvider.sol";

import {IStakerGateway} from "src/interface/external/kernel/IStakerGateway.sol";

import {TransparentUpgradeableProxy} from
    "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {BaseScript} from "script/BaseScript.sol";

// FOUNDRY_PROFILE=mainnet forge script DeployYnclisBNBkStrategy --sender 0xd53044093F757E8a56fED3CCFD0AF5Ad67AeaD4a
contract DeployYnclisBNBkStrategy is BaseScript {
    function symbol() public pure override returns (string memory) {
        return "ynclisBNBk";
    }

    function deployRateProvider() internal {
        if (block.chainid == 97) {
            rateProvider = IProvider(new TestnetBNBRateProvider());
        }

        if (block.chainid == 56) {
            rateProvider = IProvider(new BNBRateProvider());
        }
    }

    function run() public {
        vm.startBroadcast();

        _setup();
        _deployTimelockController();
        deployRateProvider();

        _verifySetup();

        deploy();

        _saveDeployment();

        vm.stopBroadcast();
    }

    function deploy() internal returns (KernelStrategy) {
        implementation = new KernelStrategy();

        bytes memory initData = abi.encodeWithSelector(
            KernelStrategy.initialize.selector, msg.sender, "YieldNest WBNB Buffer - Kernel", "ynWBNBk", 18, 0, true
        );

        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(implementation), address(actors.ADMIN()), initData);

        vault = KernelStrategy(payable(address(proxy)));

        configureVault(vault);

        return vault;
    }

    function configureVault(KernelStrategy vault_) internal {
        _configureDefaultRoles(vault_);
        _configureTemporaryRoles(vault_);

        // set allocator to ynbnbx
        vault_.grantRole(vault_.ALLOCATOR_ROLE(), contracts.YNBNBX());

        // set roles to msg.sender for now
        vault_.grantRole(vault_.KERNEL_DEPENDENCY_MANAGER_ROLE(), msg.sender);
        vault_.grantRole(vault_.DEPOSIT_MANAGER_ROLE(), msg.sender);
        vault_.grantRole(vault_.ALLOCATOR_MANAGER_ROLE(), msg.sender);
        vault_.grantRole(vault_.PROCESSOR_MANAGER_ROLE(), msg.sender);
        vault_.grantRole(vault_.PROVIDER_MANAGER_ROLE(), msg.sender);
        vault_.grantRole(vault_.ASSET_MANAGER_ROLE(), msg.sender);
        vault_.grantRole(vault_.UNPAUSER_ROLE(), msg.sender);

        vault_.setProvider(address(rateProvider));
        vault_.setHasAllocator(true);
        vault_.setStakerGateway(contracts.STAKER_GATEWAY());
        vault_.setSyncDeposit(true);
        vault_.setSyncWithdraw(true);

        vault_.addAsset(contracts.WBNB(), true);
        IStakerGateway stakerGateway = IStakerGateway(contracts.STAKER_GATEWAY());
        vault_.addAssetWithDecimals(stakerGateway.getVault(contracts.CLISBNB()), 18, false);

        vault_.unpause();

        vault_.processAccounting();

        _renounceTemporaryRoles(vault_);
    }
}