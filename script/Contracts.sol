// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.24;

interface IContracts {
    function WBNB() external view returns (address);
    function SLISBNB() external view returns (address);
    function BNBX() external view returns (address);

    function YNBNBK() external view returns (address);

    function YNBNBX() external view returns (address);

    function STAKER_GATEWAY() external view returns (address);
    function CLISBNB() external view returns (address);
    function BTCB() external view returns (address);
    function SOLVBTC() external view returns (address);
    function SOLVBTC_BNN() external view returns (address);
}

library MainnetContracts {
    // tokens
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant SLISBNB = 0xB0b84D294e0C75A6abe60171b70edEb2EFd14A1B;
    address public constant BNBX = 0x1bdd3Cf7F79cfB8EdbB955f20ad99211551BA275;

    // btc tokens

    address public constant BTCB = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address public constant SOLVBTC = 0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7;
    address public constant SOLVBTC_BNN = 0x1346b618dC92810EC74163e4c27004c921D446a5;

    address public constant CLISBNB = 0x4b30fcAA7945fE9fDEFD2895aae539ba102Ed6F6;

    // stake managers
    address public constant BNBX_STAKE_MANAGER = 0x3b961e83400D51e6E1AF5c450d3C7d7b80588d28;
    address public constant SLIS_BNB_STAKE_MANAGER = 0x1adB950d8bB3dA4bE104211D5AB038628e477fE6;

    // bnb vault
    address public constant YNBNBk = 0x304B5845b9114182ECb4495Be4C91a273b74B509;
    address public constant YNBNBk_PROXY_ADMIN = 0xB92dBb0Eb889613f5E5B49d14b1F63a199BA7b18;
    address public constant TIMELOCK = 0xd53044093F757E8a56fED3CCFD0AF5Ad67AeaD4a;

    // kernel
    address public constant STAKER_GATEWAY = 0xb32dF5B33dBCCA60437EC17b27842c12bFE83394;
    address public constant KERNEL_CONFIG = 0x45d7Bb73253A908E6160aa5FD9DA083F7Bc6faf5;
    address public constant KERNEL_CONFIG_ADMIN = 0x40f5f0f5E78289B33E450fBCA1cbD8700098cd23;
    address public constant ASSET_REGISTRY = 0xd0B91Fc0a323bbb726faAF8867CdB1cA98c44ABB;

    address public constant PROVIDER = address(123456789); // TODO: Update with deployed Provider
    address public constant BUFFER = address(987654321); // TODO: Update with deployed buffer
}

contract ChapelContracts is IContracts {
    address public constant SLISBNB = 0x80815ee920Bd9d856562633C36D3eB0E43cb15e2;

    function WBNB() external pure override returns (address) {
        return MainnetContracts.WBNB;
    }

    function BNBX() external pure override returns (address) {
        return MainnetContracts.BNBX;
    }

    function YNBNBK() external pure override returns (address) {
        return MainnetContracts.YNBNBk;
    }

    // TODO: Update with deployed YNBNBX
    function YNBNBX() external pure override returns (address) {
        return address(0);
    }

    function STAKER_GATEWAY() external pure override returns (address) {
        return MainnetContracts.STAKER_GATEWAY;
    }

    function CLISBNB() external pure override returns (address) {
        return MainnetContracts.CLISBNB;
    }

    function BTCB() external pure override returns (address) {
        return MainnetContracts.BTCB;
    }

    function SOLVBTC() external pure override returns (address) {
        return MainnetContracts.SOLVBTC;
    }

    function SOLVBTC_BNN() external pure override returns (address) {
        return MainnetContracts.SOLVBTC_BNN;
    }
}

contract BscContracts is IContracts {
    function WBNB() external pure override returns (address) {
        return MainnetContracts.WBNB;
    }

    function SLISBNB() external pure override returns (address) {
        return MainnetContracts.SLISBNB;
    }

    function BNBX() external pure override returns (address) {
        return MainnetContracts.BNBX;
    }

    function YNBNBK() external pure override returns (address) {
        return MainnetContracts.YNBNBk;
    }

    // TODO: Update with deployed YNBNBX
    function YNBNBX() external pure override returns (address) {
        return address(0);
    }

    function STAKER_GATEWAY() external pure override returns (address) {
        return MainnetContracts.STAKER_GATEWAY;
    }

    function CLISBNB() external pure override returns (address) {
        return MainnetContracts.CLISBNB;
    }

    function BTCB() external pure override returns (address) {
        return MainnetContracts.BTCB;
    }

    function SOLVBTC() external pure override returns (address) {
        return MainnetContracts.SOLVBTC;
    }

    function SOLVBTC_BNN() external pure override returns (address) {
        return MainnetContracts.SOLVBTC_BNN;
    }
}
