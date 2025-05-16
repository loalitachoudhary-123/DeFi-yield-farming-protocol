const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  console.log("Deploying Project contract...");

  // Get the deployer's signer
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy the Project contract with no constructor parameters
  const Project = await ethers.getContractFactory("Project");
  const project = await Project.deploy();
  await project.deployed();
  console.log("Project deployed to:", project.address);
  
  // For a real deployment, you'd have actual token addresses
  // For this example, let's deploy mock tokens and set them in the contract
  
  // Deploy a mock staking token (in real-world scenario, this would be existing tokens)
  const MockToken = await ethers.getContractFactory("MockERC20");
  const stakingToken = await MockToken.deploy("Staking Token", "STK");
  await stakingToken.deployed();
  console.log("Staking Token deployed to:", stakingToken.address);
  
  const rewardToken = await MockToken.deploy("Reward Token", "RWD");
  await rewardToken.deployed();
  console.log("Reward Token deployed to:", rewardToken.address);

  // Set the staking and reward tokens
  console.log("Setting staking token...");
  await project.setStakingToken(stakingToken.address);
  
  console.log("Setting reward token...");
  await project.setRewardToken(rewardToken.address);

  // Set a reward rate (tokens per second)
  const rewardRate = ethers.utils.parseEther("0.01"); // 0.01 tokens per second
  console.log("Setting reward rate...");
  await project.setRewardRate(rewardRate);
  
  // Add some reward tokens to the contract for testing
  console.log("Transferring initial rewards to the contract...");
  const initialRewards = ethers.utils.parseEther("1000");
  await rewardToken.transfer(project.address, initialRewards);

  console.log("Deployment and configuration completed successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
