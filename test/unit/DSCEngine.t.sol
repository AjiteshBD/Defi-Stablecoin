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

        ERC20Mock(weth).mint(USER, INITIAL_WETH);
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function testConstructorRevert() public {
        tokenAddresses.push(weth);
        priceFeeds.push(wethUSDPriceFeed);
        priceFeeds.push(wbtcUSDPriceFeed);
        vm.expectRevert(DSCEngine.DSCEngine__TokensAndPriceFeedsLengthMismatch.selector);
        new DSCEngine(tokenAddresses, priceFeeds, address(dsc));
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

    function testGetTokenFromUSD() public view {
        uint256 usdAmount = 100 ether;
        uint256 expectedAmount = 0.05 ether;
        assertEq(expectedAmount, engine.getTokenFromUSD(weth, usdAmount));
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

    function testNotAllowedCollateralDepositRevert() public {
        vm.prank(USER);
        ERC20Mock randToken = new ERC20Mock();
        randToken.mint(USER, 10e18);
        randToken.approve(address(engine), 10e18);
        vm.expectRevert(DSCEngine.DSCEngine__TokenNotAllowed.selector);
        engine.depositCollateral(address(randToken), 10e18);
    }

    modifier Collateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), INITIAL_COLLATERAL);
        engine.depositCollateral(address(weth), INITIAL_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCollateralDeposit() public Collateral {
        (uint256 totalDSCMinted, uint256 collateralValueInUSD) = engine.getAccountInformation(USER);
        uint256 expectedDSCMinted = 0;
        uint256 expectedCollateral = engine.getTokenFromUSD(weth, collateralValueInUSD);
        assertEq(expectedCollateral, INITIAL_COLLATERAL);
        assertEq(expectedDSCMinted, totalDSCMinted);
    }
}
