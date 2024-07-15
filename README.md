# 🌐 Relative Stability Protocol

## Overview
The Relative Stability protocol is designed to maintain a stable value anchored or pegged to $1.00. This protocol leverages Chainlink price feeds and allows users to exchange ETH and BTC for stablecoins. The stability mechanism is algorithmic and decentralized, ensuring that users can only mint stablecoins with sufficient collateral.

## Features

### 1. Relative Stability: Anchored or Pegged to $1.00
- 🔗 **Chainlink Price Feed**: The protocol uses Chainlink price feeds to ensure accurate and reliable price data.
- 💱 **Exchange Function**: Users can exchange ETH and BTC for stablecoins.

### 2. Stability Mechanism (Minting): Algorithmic (Decentralized)
- 💰 **Collateral Requirements**: Users can mint stablecoins only if they have enough collateral. This is enforced through the protocol's code.

### 3. Collateral: Exogenous (Crypto)
- 🪙 **Supported Collateral Types**:
  - Wrapped Ether (WETH)
  - Wrapped Bitcoin (WBTC)

## 📑 Contract Layout Standard

To maintain consistency and readability, the contracts follow a standard layout. Below is the recommended layout for contracts and functions:

### Layout of Contract

```solidity
// Layout of Contract:
// 1. Version
// 2. Imports
// 3. Errors
// 4. Interfaces, Libraries, Contracts
// 5. Type Declarations
// 6. State Variables
// 7. Events
// 8. Modifiers
// 9. Functions

// Layout of Functions:
// 1. Constructor
// 2. Receive function (if exists)
// 3. Fallback function (if exists)
// 4. External functions
// 5. Public functions
// 6. Internal functions
// 7. Private functions
// 8. Internal & private view & pure functions
// 9. External & public view & pure functions
```


## Usage
### 🏗️ Minting Stablecoins
To mint stablecoins, users need to deposit sufficient collateral (WETH or WBTC) into the protocol. The amount of stablecoins that can be minted depends on the value of the collateral provided.

### 🛡️ Collateral Management
The protocol supports managing collateral types and ensuring they meet the required criteria for minting stablecoins.

### 🤝 Contribution
Contributions to the protocol are welcome. Please follow the standard contract layout and function layout when making contributions to maintain consistency and readability.

### 📜 License
This project is licensed under the MIT License.





