//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "script/deploy/DeployDSC.s.sol";
import {HelperConfig} from "script/utils/HelperConfig.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentStableCoin} from "src/DecentStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "test/mock/MockV3Aggregator.sol";

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

    address public USER = makeAddr("user");
    uint256 public constant INITIAL_WETH = 10 ether;
    uint256 public constant INITIAL_COLLATERAL = 1 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (weth, wbtc, wethUSDPriceFeed, wbtcUSDPriceFeed, account) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, INITIAL_WETH);
    }

    /*//////////////////////////////////////////////////////////////
                              PRICE TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetUSDValue() public view {
        uint256 ethAmount = 15e18;
        // 1 ETH = 2000 USD; 15 * 2000 = 30000e18 USD
        (, int256 price,,,) = MockV3Aggregator(wethUSDPriceFeed).latestRoundData();
        console.log("price: ", price);
        uint256 expectedUSDValue = (uint256(price) * ethAmount) / 1e8; //300e18;
        assertEq(engine.getUSDValue(weth, ethAmount), expectedUSDValue);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT COLLATERAL TEST
    //////////////////////////////////////////////////////////////*/

    function testDepositZeroCollateral() public {
        vm.prank(USER);
        ERC20Mock(weth).approve(address(engine), INITIAL_WETH);
        vm.expectRevert(DSCEngine.DSCEngine__ZeroAmount.selector);
        engine.depositCollateral(address(weth), 0);
    }
}
