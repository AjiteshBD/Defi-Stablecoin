//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {HelperConfig} from "script/utils/HelperConfig.s.sol";
import {DecentStableCoin} from "src/DecentStableCoin.sol";

contract Handler is Test {
    DSCEngine engine;
    DecentStableCoin dsc;

    constructor(DecentStableCoin _dsc, DSCEngine _dsce) {
        engine = _dsce;
        dsc = _dsc;
    }

    function depositCollateral(address collateralSeed, uint256 collateralAmount) public {
        engine.depositCollateral(collateralSeed, collateralAmount);
    }
}
