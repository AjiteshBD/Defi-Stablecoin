//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// What are or Invariants?

// 1. The total supply of DSC should never be greater than the total value of collateral
// 2.  External view function should never revert

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "script/deploy/DeployDSC.s.sol";
import {HelperConfig} from "script/utils/HelperConfig.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentStableCoin} from "src/DecentStableCoin.sol";

contract InvariantsTest is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine engine;
    DecentStableCoin dsc;
    HelperConfig config;
    address wethUSDPriceFeed;
    address wbtcUSDPriceFeed;
    address weth;
    address wbtc;
    address account;
    //constructor test
    address[] public tokenAddresses;
    address[] public priceFeeds;
    ///
    address public USER = makeAddr("user");
    uint256 public constant INITIAL_WETH = 100 ether;
    uint256 public constant INITIAL_COLLATERAL = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (weth, wbtc, wethUSDPriceFeed, wbtcUSDPriceFeed, account) = config.activeNetworkConfig();
    }
}
