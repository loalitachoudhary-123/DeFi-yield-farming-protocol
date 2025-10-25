? Emergency withdraw without rewards
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

    ? Total rewards available in contract
    function getTotalRewardsAvailable() external view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    ? Pause or unpause reward accumulation
    function pauseRewards(bool status) external onlyOwner updateReward(address(0)) {
        rewardsPaused = status;
        emit RewardsPaused(status);
    }
}
END
// 
update
// 
