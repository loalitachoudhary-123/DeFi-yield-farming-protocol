Reward tokens created per block
    uint256 public lastRewardBlock;       Accumulated rewards per share, scaled by 1e12

    uint256 public totalStaked;

    struct UserInfo {
        uint256 amountStaked;
        uint256 rewardDebt;  If user already staked, send pending rewards before updating share
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
// 
End
// 
