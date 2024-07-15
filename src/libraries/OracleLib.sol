//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title OracleLib
 * @author Cryptoineer(Ajitesh Mishra)
 * @notice This library is used to check the chainlink oracle for stale data.
 * If the price is stable it will revert and render DSCEngine unusable.
 *
 * We want DSCEngine to be usable even if the chainlink oracle is not working.
 *
 * Known Issue: If the chainlink oracle is not working then we got lots of asset locked in protocol -- to bad.
 */
library OracleLib {
    error OracleLib__StalePrice();

    uint256 public constant TIMEOUT = 3 hours; // 3 hours = 3 * 60 * 60 = 10800

    function stalePriceCheckLatestRoundData(AggregatorV3Interface _priceFeed)
        external
        view
        returns (uint80 id, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        (id, answer, startedAt, updatedAt, answeredInRound) = AggregatorV3Interface(_priceFeed).latestRoundData();
        uint256 secondSince = block.timestamp - updatedAt;

        if (secondSince > TIMEOUT) revert OracleLib__StalePrice();

        return (id, answer, startedAt, updatedAt, answeredInRound);
    }
}
