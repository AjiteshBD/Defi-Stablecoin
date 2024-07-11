//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "test/mock/MockV3Aggregator.sol";

contract CodeConstant {
    uint256 public constant WETH_INITIAL_MINT = 10000e8;
    uint256 public constant WBTC_INITIAL_MINT = 10000e8;
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ANVIL_CHAIN_ID = 31337;
    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2000e8;
    int256 public constant BTC_USD_PRICE = 1000e8;
    string public constant WETH_NAME = "WETH";
    string public constant WBTC_NAME = "WBTC";
}

contract HelperConfig is Script, CodeConstant {
    struct NetworkConfig {
        address wethAddress;
        address wbtcAddress;
        address wethUSDPriceFeedAddress;
        address wbtcUSDPriceFeedAddress;
        address account;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getSepoliaConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({
            wethAddress: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wbtcAddress: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            wethUSDPriceFeedAddress: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            wbtcUSDPriceFeedAddress: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            account: 0xbF76C07497A795E948D0EA362BEC83Be6AbCf1EF // Sepolia account
        });
    }

    function getOrCreateAnvilConfig() internal returns (NetworkConfig memory) {
        if (activeNetworkConfig.wbtcAddress != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator ethUSDPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        ERC20Mock weth = new ERC20Mock();
        MockV3Aggregator wbtcUSDPriceFeed = new MockV3Aggregator(DECIMALS, BTC_USD_PRICE);
        ERC20Mock wbtc = new ERC20Mock();
        vm.stopBroadcast();

        return NetworkConfig({
            wethAddress: address(weth),
            wbtcAddress: address(wbtc),
            wethUSDPriceFeedAddress: address(ethUSDPriceFeed),
            wbtcUSDPriceFeedAddress: address(wbtcUSDPriceFeed),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        });
    }
}
