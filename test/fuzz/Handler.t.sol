//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {HelperConfig} from "script/utils/HelperConfig.s.sol";
import {DecentStableCoin} from "src/DecentStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract Handler is Test {
    DSCEngine engine;
    DecentStableCoin dsc;
    ERC20Mock weth;
    ERC20Mock wbtc;

    constructor(DecentStableCoin _dsc, DSCEngine _dsce) {
        engine = _dsce;
        dsc = _dsc;
        address[] memory collateralAddresses = engine.getCollateralTokens();
        weth = ERC20Mock(collateralAddresses[0]);
        wbtc = ERC20Mock(collateralAddresses[1]);
    }

    function depositCollateral(uint256 collateralSeed, uint256 collateralAmount) public {
        ERC20Mock _collateral = _getCollateralValue(collateralSeed);
        engine.depositCollateral(address(_collateral), collateralAmount);
    }

    function _getCollateralValue(uint256 collaterSeed) private view returns (ERC20Mock) {
        if (collaterSeed % 2 == 0) {
            return weth;
        } else {
            return wbtc;
        }
    }
}
