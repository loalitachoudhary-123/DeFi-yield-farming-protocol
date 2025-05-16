// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Project
 * @dev A DeFi yield farming contract where users can stake tokens and earn rewards
 */
contract Project is Ownable, ReentrancyGuard {
    // The token being staked (default to a predefined token)
    IERC20 public stakingToken;
    
    // The token given as rewards (default to a predefined token)
    IERC20 public rewardToken;
    
    // Reward rate per second (default: 0.01 tokens per second)
    uint256 public rewardRate = 0.01 ether;
    
    // Last time rewards were updated
    uint256 public lastUpdateTime;
    
    // Reward per token stored
    uint256 public rewardPerTokenStored;
    
    // Total staked tokens
    uint256 public totalStaked;
    
    // User staking info
    mapping(address => uint256) public userStakedBalance;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    // Events
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event RewardRateUpdated(uint256 newRate);
    event StakingTokenSet(address tokenAddress);
    event RewardTokenSet(address tokenAddress);

    /**
     * @dev Constructor initializes the contract with default values
     * No input parameters required
     */
    constructor() Ownable(msg.sender) {
        // Initialize with default values
        lastUpdateTime = block.timestamp;
    }

    /**
     * @dev Update the reward variables
     */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /**
     * @dev Sets the staking token
     * @param _stakingToken The address of the token to stake
     */
    function setStakingToken(address _stakingToken) external onlyOwner {
        require(_stakingToken != address(0), "Invalid token address");
        stakingToken = IERC20(_stakingToken);
        emit StakingTokenSet(_stakingToken);
    }

    /**
     * @dev Sets the reward token
     * @param _rewardToken The address of the token for rewards
     */
    function setRewardToken(address _rewardToken) external onlyOwner {
        require(_rewardToken != address(0), "Invalid token address");
        rewardToken = IERC20(_rewardToken);
        emit RewardTokenSet(_rewardToken);
    }

    /**
     * @dev Calculate the reward per token
     * @return The reward per token
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        
        return rewardPerTokenStored + (
            ((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / totalStaked
        );
    }

    /**
     * @dev Calculate the earned rewards for an account
     * @param account The account to calculate rewards for
     * @return The earned rewards
     */
    function earned(address account) public view returns (uint256) {
        return (
            (userStakedBalance[account] * 
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18
        ) + rewards[account];
    }

    /**
     * @dev Stake tokens in the contract
     * @param amount The amount of tokens to stake
     */
    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(address(stakingToken) != address(0), "Staking token not set");
        require(amount > 0, "Cannot stake 0");
        
        totalStaked += amount;
        userStakedBalance[msg.sender] += amount;
        
        // Transfer staking tokens to this contract
        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Stake transfer failed");
        
        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Withdraw staked tokens
     * @param amount The amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(address(stakingToken) != address(0), "Staking token not set");
        require(amount > 0, "Cannot withdraw 0");
        require(userStakedBalance[msg.sender] >= amount, "Not enough staked");
        
        totalStaked -= amount;
        userStakedBalance[msg.sender] -= amount;
        
        // Transfer staking tokens back to the user
        bool success = stakingToken.transfer(msg.sender, amount);
        require(success, "Withdraw transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev Claim earned rewards
     */
    function claimReward() external nonReentrant updateReward(msg.sender) {
        require(address(rewardToken) != address(0), "Reward token not set");
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            
            // Transfer reward tokens to the user
            bool success = rewardToken.transfer(msg.sender, reward);
            require(success, "Reward transfer failed");
            
            emit RewardClaimed(msg.sender, reward);
        }
    }

    /**
     * @dev Update the reward rate (only owner)
     * @param _rewardRate New reward rate
     */
    function setRewardRate(uint256 _rewardRate) external onlyOwner updateReward(address(0)) {
        rewardRate = _rewardRate;
        emit RewardRateUpdated(_rewardRate);
    }
}
