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

import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DecentStableCoin
 * @author Cryptoineer(Ajitesh Mishra)
 * Collateral : Exogenous(ETH & BTC)
 * Minting: Algorithmic
 * Relative Stability: Pegged to USD
 *
 * @notice This is contract meant to be governed by DSCEngine. This contract is just ERC20
 *  implementation of our stablecoin system.
 */
contract DecentStableCoin is ERC20Burnable, Ownable {
    error DecentStableCoin__MustBeMoreThanZero();
    error DecentStableCoin__BurnAmountExceedsBalance();
    error DecentStableCoin__AddressZero();

    constructor() ERC20("DecentStableCoin", "DSC") Ownable(_msgSender()) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(_msgSender());
        if (_amount <= 0) {
            revert DecentStableCoin__MustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert DecentStableCoin__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DecentStableCoin__AddressZero();
        }
        if (_amount <= 0) {
            revert DecentStableCoin__MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}
