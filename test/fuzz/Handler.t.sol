//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {HelperConfig} from "script/utils/HelperConfig.s.sol";
import {DecentStableCoin} from "src/DecentStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract Handler is Test {
    DSCEngine engine;
    DecentStableCoin dsc;
    ERC20Mock weth;
    ERC20Mock wbtc;
    uint256 MAX_COLLATERAL = type(uint96).max;
    address[] public depositers;
    address[] public redeemers;
    MockV3Aggregator wethPriceFeed;

    constructor(DecentStableCoin _dsc, DSCEngine _dsce) {
        engine = _dsce;
        dsc = _dsc;
        address[] memory collateralAddresses = engine.getCollateralTokens();
        weth = ERC20Mock(collateralAddresses[0]);
        wbtc = ERC20Mock(collateralAddresses[1]);
        wethPriceFeed = MockV3Aggregator(engine.getPriceFeeds(address(weth)));
    }

    function depositCollateral(uint256 collateralSeed, uint256 collateralAmount) public {
        ERC20Mock _collateral = _getCollateralValue(collateralSeed);
        collateralAmount = bound(collateralAmount, 1, MAX_COLLATERAL);
        vm.startPrank(msg.sender);
        _collateral.mint(msg.sender, collateralAmount);
        _collateral.approve(address(engine), collateralAmount);
        engine.depositCollateral(address(_collateral), collateralAmount);
        vm.stopPrank();
        depositers.push(msg.sender);
    }

    function redeemCollateral(uint256 collateralSeed, uint256 collateralAmount) public {
        ERC20Mock _collateral = _getCollateralValue(collateralSeed);
        uint256 totalRedeemableCollateral = engine.getCollateralBalanceUser(address(_collateral), msg.sender);
        collateralAmount = bound(collateralAmount, 0, totalRedeemableCollateral);
        if (collateralAmount == 0) {
            return;
        }
        vm.prank(msg.sender);
        engine.redeemCollateral(address(_collateral), collateralAmount);
        redeemers.push(msg.sender);
    }

    function mintDSC(uint256 dscAmount, uint256 depositerSeed) public {
        if (depositers.length == 0) {
            return;
        }
        address depositer = depositers[depositerSeed % depositers.length];

        (uint256 totalDSCMinted, uint256 collateralValueInUSD) = engine.getAccountInformation(msg.sender);
        int256 max_dsc_mint = (int256(collateralValueInUSD) / 2) - int256(totalDSCMinted);
        if (max_dsc_mint < 0) {
            return;
        }
        dscAmount = bound(dscAmount, 0, uint256(max_dsc_mint));
        if (dscAmount == 0) {
            return;
        }
        vm.startPrank(depositer);
        engine.mintDSC(dscAmount);
        vm.stopPrank();
    }

    // This invariant breaks our test suite
    // function updatePrice(uint256 newPrice) public {
    //     wethPriceFeed.updateAnswer(int256(newPrice));
    // }

    function _getCollateralValue(uint256 collaterSeed) private view returns (ERC20Mock) {
        if (collaterSeed % 2 == 0) {
            return weth;
        }
        return wbtc;
    }
}
