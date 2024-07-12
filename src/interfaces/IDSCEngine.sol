//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IDSCEngine {
    function depositCollateralAndMintDSC(address _collateral, uint256 _amountCollateral, uint256 _amountDSC) external;

    function depositCollateral(address _collateral, uint256 _amount) external;

    function redeemCollateralAndBurnDSC(address _collateral, uint256 _amountCollateral, uint256 _amountDSC) external;

    function redeemCollateral(address _collateral, uint256 _amount) external;

    function burnDSC(uint256 _amountDSC) external;

    function mintDSC(uint256 _amountDSC) external;

    function liquidate(address _collateral, address _user, uint256 _debtToCover) external;

    function getHealthFactor() external view;
}
