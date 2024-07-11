//SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

pragma solidity ^0.8.19;

import {IDSCEngine} from "./interfaces/IDSCEngine.sol";
import {DecentStableCoin} from "./DecentStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title DSCEngine
 * @author Crytoineer(Ajitesh Mishra)
 *
 * The system is designed to be as minimal as possible and have the token to maintain a $1.0 price.
 * This stablecoin has this properties:
 * - 1 dollar for  Pegging
 * - Exogenous Collateral
 * - Algorithmically Decentralized Stable Coin
 *
 * It is similar to DAI if DAI had no governance, no stability fees, and only baked by WETH and WBTC.
 * Our DSC system should always be overCollateralized. At no time should it be underCollateralized.
 *
 * @notice This is the core contract of DSC System. It handles all the logic for mining DSC, redeeming DSC , depositing and withdrawaing collaterals.
 * @notice This contract is VERY loosely based on Maker DAO DSS (DAI) system.
 */
contract DSCEngine is IDSCEngine, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error DSCEngine__ZeroAmount();
    error DSCEngine__TokensAndPriceFeedsLengthMismatch();
    error DSCEngine__TokenNotAllowed();
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 userHeathFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__BurnFailed();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; //200% overcollateralization
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MINIMUM_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256)) private s_collateralDeposited;
    mapping(address user => uint256 dscminted) private s_dscMinted;
    address[] private s_tokenAddresses;
    DecentStableCoin private s_dscToken;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event DepositCollateral(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(address indexed user, address indexed token, uint256 indexed amount);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier moreThanZero(uint256 _amount) {
        if (_amount <= 0) {
            revert DSCEngine__ZeroAmount();
        }
        _;
    }

    modifier isTokenAllowed(address _token) {
        if (s_priceFeeds[_token] == address(0)) {
            revert DSCEngine__TokenNotAllowed();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(address[] memory _tokenAddresses, address[] memory _priceFeeds, address _dscToken) {
        if (_tokenAddresses.length != _priceFeeds.length) {
            revert DSCEngine__TokensAndPriceFeedsLengthMismatch();
        }
        for (uint8 i = 0; i < _tokenAddresses.length; i++) {
            s_priceFeeds[_tokenAddresses[i]] = _priceFeeds[i];
            s_tokenAddresses.push(_tokenAddresses[i]);
        }
        s_dscToken = DecentStableCoin(_dscToken);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @param _collateral The address of the collateral token to deposit
     * @param _amountCollateral The amount of collateral to deposit
     * @param _amountDSC The amount of DSC to mint
     * @notice This function deposits collateral and mint DSC in one transaction.
     */
    function depositCollateralAndMintDSC(address _collateral, uint256 _amountCollateral, uint256 _amountDSC)
        external
        override
    {
        depositCollateral(_collateral, _amountCollateral);
        mintDSC(_amountDSC);
    }

    /**
     * @notice follows CEI (Checks,Effects,Interactions) pattern
     * @param _collateral The address of the collateral token to deposit
     * @param _amount The amount of collateral to deposit
     */
    function depositCollateral(address _collateral, uint256 _amount)
        public
        override
        moreThanZero(_amount)
        isTokenAllowed(_collateral)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][_collateral] += _amount;
        emit DepositCollateral(msg.sender, _collateral, _amount);
        bool success = IERC20(_collateral).transferFrom(msg.sender, address(this), _amount);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    /**
     *
     * @param _collateral token collateral address to redeem
     * @param _amountCollateral  amount of collateral to redeem
     * @param _amountDSC amount DSC to burn
     * @notice This function redeems collateral and burn DSC in one transaction.
     */
    function redeemCollateralAndBurnDSC(address _collateral, uint256 _amountCollateral, uint256 _amountDSC)
        external
        override
    {
        burnDSC(_amountDSC);
        redeemCollateral(_collateral, _amountCollateral);
    }

    function redeemCollateral(address _collateral, uint256 _amount)
        public
        override
        moreThanZero(_amount)
        isTokenAllowed(_collateral)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][_collateral] -= _amount;
        emit CollateralRedeemed(msg.sender, _collateral, _amount);
        bool success = IERC20(_collateral).transfer(msg.sender, _amount);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function burnDSC(uint256 _amountDSC) public override moreThanZero(_amountDSC) nonReentrant {
        s_dscMinted[msg.sender] -= _amountDSC;

        bool success = s_dscToken.transferFrom(msg.sender, address(this), _amountDSC);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        s_dscToken.burn(_amountDSC);
        _revertIfHealthFactorIsBroken(msg.sender); // probably never this will happen. note to remove in future
    }

    /**
     * @notice follows CEI (Checks,Effects,Interactions) pattern
     * @param _amountDSC The amount of DSC to mint
     * @notice they must have more collateral value than minimum threshold
     */
    function mintDSC(uint256 _amountDSC) public override moreThanZero(_amountDSC) nonReentrant {
        s_dscMinted[msg.sender] += _amountDSC;
        // If they minted too much revert
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = s_dscToken.mint(msg.sender, _amountDSC);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    function liquidate() external override {}

    function getHealthFactor() external view override {}

    /*//////////////////////////////////////////////////////////////
                    PRIVATE & INTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _getAccountInformation(address user)
        internal
        view
        returns (uint256 totalDSCMinted, uint256 collateralValueInUSD)
    {
        totalDSCMinted = s_dscMinted[user];
        collateralValueInUSD = getAccountCollaterValue(user);
    }

    /**
     * @param user The address of the user
     * @return The health factor
     * Returns how close to liquidation the user is
     * If they are undercollateralized then they get liquidated
     */
    function _healthFactor(address user) internal view returns (uint256) {
        // TODO
        //total DSC Minted
        // total collateral deposited
        (uint256 _totalDSCMinted, uint256 _collateralValueInUSD) = _getAccountInformation(user);
        //calculated collateral value liquidate threshold mean we need to overcollateralized
        // ex: 1000 ETH  * 50 = 50,000 /100 = 500
        uint256 collateralAdjustedForThreshold = (_collateralValueInUSD * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        // adjusted collateral value with 18 decimals for division with DSC token to get health factor
        //ex: $150 ETH / 100 DSC  = 1.5
        //150 *50  = 7500 /100 = (75/100)<1 -- undercollateralized
        //ex: 50,000/100 = (500/100) >1  -- overcollateralized
        return (collateralAdjustedForThreshold * PRECISION) / _totalDSCMinted;
    }

    /**
     * @param user The address of the user
     *
     * Returns if they are overcollateralized
     */
    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 _userHealthFactor = _healthFactor(user);
        if (_userHealthFactor > MINIMUM_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(_userHealthFactor);
        }
    }

    /*//////////////////////////////////////////////////////////////
                    PUBLIC & EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getAccountCollaterValue(address user) public view returns (uint256 totalCollateralValue) {
        //loop through each collateral token, get the amount they deposited and map it to
        //the USD value of that token
        for (uint256 i = 0; i < s_tokenAddresses.length; i++) {
            address token = s_tokenAddresses[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValue += getUSDValue(token, amount);
        }
        return totalCollateralValue;
    }

    function getUSDValue(address _token, uint256 _amount) public view returns (uint256) {
        AggregatorV3Interface aggregator = AggregatorV3Interface(s_priceFeeds[_token]);
        (, int256 price,,,) = aggregator.latestRoundData();
        // convert int price to uint then multiply by amount additional precision to same decimals as DSC
        // then divide by precision to get USD value
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * _amount) / PRECISION;
    }
}
