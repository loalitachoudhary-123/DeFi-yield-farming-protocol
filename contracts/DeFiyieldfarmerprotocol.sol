// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DeFiyieldfarmerprotocol
 * @dev Simplified yield farming protocol with staking and reward token
 */
contract DeFiYieldFarmerProtocol is ERC20, Ownable {
    IERC20 public stakingToken;

    uint256 public rewardRatePerBlock;    // Reward tokens created per block
    uint256 public lastRewardBlock;       // Last block number that rewards distribution occurred
    uint256 public accRewardPerShare;     // Accumulated rewards per share, scaled by 1e12

    uint256 public totalStaked;

    struct UserInfo {
        uint256 amountStaked;
        uint256 rewardDebt;  // Reward debt for user
    }

    mapping(address => UserInfo) public userInfo;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRate);

    /**
     * @param _stakingToken Address of the token users stake (e.g., a stablecoin or LP token)
     * @param _rewardRatePerBlock Number of reward tokens minted per block
     */
    constructor(IERC20 _stakingToken, uint256 _rewardRatePerBlock) ERC20("DeFi Yield Token", "DLY") {
        stakingToken = _stakingToken;
        rewardRatePerBlock = _rewardRatePerBlock;
        lastRewardBlock = block.number;
    }

    /**
     * @dev View function to see pending rewards for a user
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 _accRewardPerShare = accRewardPerShare;
        uint256 _totalStaked = totalStaked;

        if (block.number > lastRewardBlock && _totalStaked != 0) {
            uint256 blocks = block.number - lastRewardBlock;
            uint256 reward = blocks * rewardRatePerBlock;
            _accRewardPerShare += (reward * 1e12) / _totalStaked;
        }
        return ((user.amountStaked * _accRewardPerShare) / 1e12) - user.rewardDebt;
    }

    /**
     * @dev Update reward variables to be up-to-date.
     * Called before any user action altering staking balances.
     */
    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }

        uint256 _totalStaked = totalStaked;
        if (_totalStaked == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 blocks = block.number - lastRewardBlock;
        uint256 reward = blocks * rewardRatePerBlock;

        _mint(address(this), reward);

        accRewardPerShare += (reward * 1e12) / _totalStaked;
        lastRewardBlock = block.number;
    }

    /**
     * @dev Stake staking tokens to earn rewards
     * @param amount Amount of staking tokens to deposit
     */
    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake zero");
        UserInfo storage user = userInfo[msg.sender];

        updatePool();

        // If user already staked, send pending rewards before updating share
        if (user.amountStaked > 0) {
            uint256 pending = ((user.amountStaked * accRewardPerShare) / 1e12) - user.rewardDebt;
            if (pending > 0) {
                _safeRewardTransfer(msg.sender, pending);
                emit RewardClaimed(msg.sender, pending);
            }
        }

        stakingToken.transferFrom(msg.sender, address(this), amount);

        user.amountStaked += amount;
        totalStaked += amount;
        user.rewardDebt = (user.amountStaked * accRewardPerShare) / 1e12;

        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Withdraw staked tokens and claim rewards
     * @param amount Amount of staked tokens to withdraw
     */
    function withdraw(uint256 amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amountStaked >= amount, "Withdraw amount exceeds stake");

        updatePool();

        uint256 pending = ((user.amountStaked * accRewardPerShare) / 1e12) - user.rewardDebt;
        if (pending > 0) {
            _safeRewardTransfer(msg.sender, pending);
            emit RewardClaimed(msg.sender, pending);
        }

        if (amount > 0) {
            user.amountStaked -= amount;
            totalStaked -= amount;
            stakingToken.transfer(msg.sender, amount);
            emit Withdrawn(msg.sender, amount);
        }

        user.rewardDebt = (user.amountStaked * accRewardPerShare) / 1e12;
    }

    /**
     * @dev Safely transfer reward tokens, fallback to contract balance if insufficient
     */
    function _safeRewardTransfer(address to, uint256 amount) internal {
        uint256 rewardBal = balanceOf(address(this));
        if (amount > rewardBal) {
            _transfer(address(this), to, rewardBal);
        } else {
            _transfer(address(this), to, amount);
        }
    }

    /**
     * @dev Owner can update reward rate per block
     * @param newRate New reward amount minted per block
     */
    function updateRewardRate(uint256 newRate) external onlyOwner {
        updatePool();
        rewardRatePerBlock = newRate;
        emit RewardRateUpdated(newRate);
    }
}
