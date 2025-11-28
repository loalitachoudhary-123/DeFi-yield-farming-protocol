// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title DeFiYieldFarmerProtocol
 * @dev Simple single‑pool yield farming contract: stake one ERC20 token, earn another as rewards
 * @notice Uses a standard rewardPerToken accumulator for proportional, time-based rewards
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract DeFiYieldFarmerProtocol {
    IERC20 public stakingToken;   // token users stake
    IERC20 public rewardToken;    // token users earn as rewards
    address public owner;

    uint256 public rewardRate;        // rewards per second
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    uint256 public totalStaked;

    mapping(address => uint256) public userStake;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardRateUpdated(uint256 newRate);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    constructor(
        address _stakingToken,
        address _rewardToken,
        uint256 _rewardRate
    ) {
        require(_stakingToken != address(0) && _rewardToken != address(0), "Zero address");
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRate = _rewardRate;
        lastUpdateTime = block.timestamp;
    }

    /**
     * @dev View: current reward per staked token
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) return rewardPerTokenStored;
        uint256 timeDelta = block.timestamp - lastUpdateTime;
        return rewardPerTokenStored + (timeDelta * rewardRate * 1e18) / totalStaked;
    }

    /**
     * @dev View: earned rewards for an account
     */
    function earned(address account) public view returns (uint256) {
        uint256 rptDelta = rewardPerToken() - userRewardPerTokenPaid[account];
        return (userStake[account] * rptDelta) / 1e18 + rewards[account];
    }

    /**
     * @dev Stake tokens into the farm
     * @param amount Amount of stakingToken to stake
     */
    function stake(uint256 amount)
        external
        updateReward(msg.sender)
    {
        require(amount > 0, "Amount = 0");

        totalStaked += amount;
        userStake[msg.sender] += amount;

        require(
            stakingToken.transferFrom(msg.sender, address(this), amount),
            "Stake transfer failed"
        );

        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Withdraw staked tokens
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount)
        external
        updateReward(msg.sender)
    {
        require(amount > 0, "Amount = 0");
        require(userStake[msg.sender] >= amount, "Insufficient stake");

        totalStaked -= amount;
        userStake[msg.sender] -= amount;

        require(
            stakingToken.transfer(msg.sender, amount),
            "Withdraw transfer failed"
        );

        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev Claim accumulated rewards
     */
    function getReward()
        external
        updateReward(msg.sender)
    {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No reward");

        rewards[msg.sender] = 0;
        require(
            rewardToken.transfer(msg.sender, reward),
            "Reward transfer failed"
        );

        emit RewardPaid(msg.sender, reward);
    }

    /**
     * @dev Owner can update reward emission rate
     * @param _rewardRate New reward rate per second
     */
    function setRewardRate(uint256 _rewardRate)
        external
        onlyOwner
        updateReward(address(0))
    {
        rewardRate = _rewardRate;
        emit RewardRateUpdated(_rewardRate);
    }

    /**
     * @dev Emergency: owner can recover tokens accidentally sent (not stakingToken)
     */
    function rescueTokens(address token, uint256 amount) external onlyOwner {
        require(token != address(stakingToken), "Cannot rescue staking token");
        require(IERC20(token).transfer(msg.sender, amount), "Rescue failed");
    }

    /**
     * @dev Transfer ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }
}
