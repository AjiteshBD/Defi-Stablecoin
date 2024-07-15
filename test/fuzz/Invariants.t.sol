//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// What are or Invariants?

// 1. The total supply of DSC should never be greater than the total value of collateral
// 2.  External view function should never revert

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "script/deploy/DeployDSC.s.sol";
import {HelperConfig} from "script/utils/HelperConfig.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentStableCoin} from "src/DecentStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Handler} from "./Handler.t.sol";

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
    Handler handler;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (weth, wbtc, wethUSDPriceFeed, wbtcUSDPriceFeed, account) = config.activeNetworkConfig();
        handler = new Handler(dsc, engine);
        targetContract(address(handler));
    }

    function invariant_ProtocolMustHaveMoreCollateralThanDSC() public view {
        uint256 totalSupply = dsc.totalSupply();
        uint256 wethDeposted = ERC20Mock(weth).balanceOf(address(engine));
        uint256 wbtcDeposited = ERC20Mock(wbtc).balanceOf(address(engine));

        uint256 wethValue = engine.getUSDValue(weth, wethDeposted);
        uint256 wbtcValue = engine.getUSDValue(wbtc, wbtcDeposited);

        console.log("wethValue: %s", wethValue);
        console.log("wbtcValue: %s", wbtcValue);
        console.log("totalsupply: %s", totalSupply);

        assert(wethValue + wbtcValue >= totalSupply);
    }

    function invariant_getterShouldNotRevert() public view {
        engine.getLiquidatorBonus();
        engine.getMinimumHealthFactor();
        engine.getLiquidationPrecision();
        engine.getHealthFactor(msg.sender);
        engine.getLiquidationThreshold();
        engine.getPrecision();
    }
}
