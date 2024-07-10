//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IDSCEngine {
    function depositCollateralAndMintDSC(address _collateral, uint256 _amount) external;

    function depositCollateral(address _collateral, uint256 _amount) external;

    function redeemCollateralAndBurnDSC() external;

    function redeemCollateral() external;

    function burnDSC() external;

    function mintDSC(uint256 _amountDSC) external;

    function liquidate() external;

    function getHealthFactor() external view;
}
