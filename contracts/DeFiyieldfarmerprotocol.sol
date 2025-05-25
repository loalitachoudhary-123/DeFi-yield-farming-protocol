// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


 */
contract Project is Ownable, ReentrancyGuard {
    IERC20 public stakingToken;
    IERC20 public rewardToken;

    uint256 public rewardRate = 0.01 ether;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public totalStaked;
    bool public rewardsPaused;

    mapping(address => uint256) public userStakedBalance;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event RewardRateUpdated(uint256 newRate);
    event StakingTokenSet(address tokenAddress);
    event RewardTokenSet(address tokenAddress);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RecoveredTokens(address token, uint256 amount);
    event RewardsPaused(bool status);

    constructor() Ownable(msg.sender) {
        lastUpdateTime = block.timestamp;
    }

    modifier updateReward(address account) {
        if (!rewardsPaused) {
            rewardPerTokenStored = rewardPerToken();
            lastUpdateTime = block.timestamp;
            if (account != address(0)) {
                rewards[account] = earned(account);
                userRewardPerTokenPaid[account] = rewardPerTokenStored;
            }
        }
        _;
    }

    function setStakingToken(address _stakingToken) external onlyOwner {
        require(_stakingToken != address(0), "Invalid token address");
        stakingToken = IERC20(_stakingToken);
        emit StakingTokenSet(_stakingToken);
    }

    function setRewardToken(address _rewardToken) external onlyOwner {
        require(_rewardToken != address(0), "Invalid token address");
        rewardToken = IERC20(_rewardToken);
        emit RewardTokenSet(_rewardToken);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) return rewardPerTokenStored;
        return rewardPerTokenStored + (
            ((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / totalStaked
        );
    }

    function earned(address account) public view returns (uint256) {
        return (
            (userStakedBalance[account] * 
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18
        ) + rewards[account];
    }

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(address(stakingToken) != address(0), "Staking token not set");
        require(amount > 0, "Cannot stake 0");

        totalStaked += amount;
        userStakedBalance[msg.sender] += amount;

        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Stake transfer failed");

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(address(stakingToken) != address(0), "Staking token not set");
        require(amount > 0, "Cannot withdraw 0");
        require(userStakedBalance[msg.sender] >= amount, "Not enough staked");

        totalStaked -= amount;
        userStakedBalance[msg.sender] -= amount;

        bool success = stakingToken.transfer(msg.sender, amount);
        require(success, "Withdraw transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    function claimReward() external nonReentrant updateReward(msg.sender) {
        require(address(rewardToken) != address(0), "Reward token not set");
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            bool success = rewardToken.transfer(msg.sender, reward);
            require(success, "Reward transfer failed");
            emit RewardClaimed(msg.sender, reward);
        }
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner updateReward(address(0)) {
        rewardRate = _rewardRate;
        emit RewardRateUpdated(_rewardRate);
    }

    // 🔒 NEW FUNCTION 1: Emergency withdraw without rewards
    function emergencyWithdraw() external nonReentrant {
        uint256 amount = userStakedBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        totalStaked -= amount;
        userStakedBalance[msg.sender] = 0;
        rewards[msg.sender] = 0;

        bool success = stakingToken.transfer(msg.sender, amount);
        require(success, "Emergency withdraw failed");

        emit EmergencyWithdraw(msg.sender, amount);
    }

    // 🧾 NEW FUNCTION 2: View user's info
    function getUserInfo(address user) external view returns (
        uint256 stakedAmount,
        uint256 pendingReward
    ) {
        stakedAmount = userStakedBalance[user];
        pendingReward = earned(user);
    }

    // 💰 NEW FUNCTION 3: Total rewards available in contract
    function getTotalRewardsAvailable() external view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    // ⚠️ NEW FUNCTION 4: Recover accidentally sent tokens
    function recoverERC20(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot recover staking token");
        require(tokenAddress != address(rewardToken), "Cannot recover reward token");

        IERC20(tokenAddress).transfer(msg.sender, amount);
        emit RecoveredTokens(tokenAddress, amount);
    }

    // 🛑 NEW FUNCTION 5: Pause/Unpause rewards
    function pauseRewards(bool status) external onlyOwner updateReward(address(0)) {
        rewardsPaused = status;
        emit RewardsPaused(status);
    }
}
