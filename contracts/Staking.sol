pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RewardToken.sol";
import "hardhat/console.sol";

contract Staking is Ownable {

    struct User {
        uint256 startTime;
        uint256 stakingBalance;
        uint256 unclaimedReward;
    }

    mapping(address => User) stakers;

    string public name = "Staking";

    IERC20 public lpToken;
    IERC20 public rewardToken;

    uint256 public claimRewardLockTime = 20 * 60 * 60;
    uint256 public lockTime = 10 * 60 * 60;
    // 1/10000 of reward share
    uint256 public rewardShare = 2000; // 20% or 0.2

    event Stake(address indexed from, uint256 amount);
    event Unstake(address indexed from, uint256 amountUnstacked);
    event ClaimReward(address indexed to, uint256 amount);

    constructor(
        IERC20 _lpToken,
        RewardToken _rewardToken
        ) {
            lpToken = _lpToken;
            rewardToken = _rewardToken;
        }

    function stake(uint256 amount) public {
        lpToken.transferFrom(msg.sender, address(this), amount);
        if(stakers[msg.sender].startTime != 0)
            stakers[msg.sender].unclaimedReward = calculateStakingReward() * calculateClaimRewardTimes();
        stakers[msg.sender].stakingBalance += amount;
        stakers[msg.sender].startTime = block.timestamp;
        emit Stake(msg.sender, amount);
    }

    function unstake() public stakingNotEmpty(msg.sender) {
        require(block.timestamp - stakers[msg.sender].startTime > lockTime, "lock is not over yet");

        stakers[msg.sender].unclaimedReward = calculateStakingReward() * calculateClaimRewardTimes();
        lpToken.transfer(msg.sender, stakers[msg.sender].stakingBalance);
        emit Unstake(msg.sender, stakers[msg.sender].stakingBalance);
        stakers[msg.sender].stakingBalance = 0;
    }

    function claim() external stakingNotEmpty(msg.sender) {
        require(stakers[msg.sender].unclaimedReward > 0 || block.timestamp - stakers[msg.sender].startTime > claimRewardLockTime, "reward is not unlocked yet");
        uint256 reward = calculateStakingReward() * calculateClaimRewardTimes() + stakers[msg.sender].unclaimedReward;
        rewardToken.transfer(msg.sender, reward);
        emit ClaimReward(msg.sender, reward);
    }

    function calculateStakingReward() internal view returns (uint256) {
        return (stakers[msg.sender].stakingBalance * rewardShare) / 10000;       
    }

    function calculateClaimRewardTimes() internal view  returns (uint256) {
        return (block.timestamp - stakers[msg.sender].startTime) / claimRewardLockTime;
    }

    function setLockTime(uint256 newLockTime) external onlyOwner {
        lockTime = newLockTime;
    }

    function setClaimLockTime(uint256 newClaimLockTime) external onlyOwner {
        claimRewardLockTime = newClaimLockTime;
    }

    modifier stakingNotEmpty(address sender) {
        require(stakers[sender].stakingBalance > 0, "No stake");
        _;
    }
}