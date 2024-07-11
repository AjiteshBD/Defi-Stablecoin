//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "script/deploy/DeployDSC.s.sol";
import {HelperConfig} from "script/utils/HelperConfig.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentStableCoin} from "src/DecentStableCoin.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DSCEngine engine;
    DecentStableCoin dsc;
    HelperConfig config;
    address wethUSDPriceFeed;
    address wbtcUSDPriceFeed;
    address weth;
    address wbtc;
    address account;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (weth, wbtc, wethUSDPriceFeed, wbtcUSDPriceFeed, account) = config.activeNetworkConfig();
    }

    /*//////////////////////////////////////////////////////////////
                              PRICE TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetUSDValue() public view {
        uint256 ethAmount = 15e18;
        // 1 ETH = 2000 USD; 15 * 2000 = 30000e18 USD
        uint256 expectedUSDValue = 30000e18;
        assertEq(engine.getUSDValue(weth, ethAmount), expectedUSDValue);
    }
}
