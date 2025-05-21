Technical Overview
The protocol consists of a main Project contract that handles:

Token staking functionality
Reward calculation and distribution
Withdrawal mechanisms
Protocol configuration

Users can stake their tokens and earn rewards in proportion to their share of the total staked amount. Rewards accrue continuously and can be claimed at any time.
How It Works

Users approve the Project contract to spend their tokens
Users stake their tokens into the contract
The contract tracks each user's stake and the total staked amount
Rewards accumulate based on the staking duration and amount
Users can claim rewards or withdraw their stake at any time

Future Scope

Multiple Token Support: Enable farming with different token pairs
Time-lock Options: Add time-lock staking options for higher APY
Governance Integration: Implement DAO governance for protocol parameters
Reward Boosting Mechanisms: Add features to boost rewards based on staking duration
Cross-chain Expansion: Deploy to additional EVM-compatible blockchains
Automated Compounding: Implement auto-compounding strategies for optimal yields
Liquidity Mining Programs: Launch liquidity mining campaigns for protocol growth

Development and Deployment
This project uses Hardhat for development, testing, and deployment. The contract is configured to deploy to Core Testnet 2.
Installation
bashnpm install
Testing
bashnpx hardhat test
Deployment
bashnpx hardhat run scripts/deploy.js --network coreTestnet2
Security Considerations

The contract uses OpenZeppelin's ReentrancyGuard to prevent reentrancy attacks
Owner privileges are limited to setting reward rates
All functions follow the Checks-Effects-Interactions pattern
Extensive testing has been performed to ensure correct functionality

License
MIT

Contract address: 0x5D2e12d93EA2Bf5E3dDEa0f0cB721a93820deD82
![Screenshot 2025-05-21 183646](https://github.com/user-attachments/assets/08d60b7f-7521-4aa9-9921-697211ee2699)


