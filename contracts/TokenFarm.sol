pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RewardToken.sol";

contract Staking is Ownable {

    mapping(address => uint256) public stakingBalance;
    mapping(address => bool) public isStaking;
    mapping(address => bool) public rewardClaimed;
    mapping(address => uint256) public startTime;
    mapping(address => uint256) public pmknBalance;

    string public name = "Staking";

    IERC20 public lpToken;
    RewardToken public rewardToken;

    uint256 public claimRewardLockTime = 20 * 60 * 60;
    uint256 public lockTime = 10 * 60 * 60;
    // 1/10000 of reward share
    uint256 public rewardShare = 2000; // 20% or 0.2

    event Stake(address indexed from, uint256 amount);
    event Unstake(address indexed from, uint256 amountUnstacked, uint256 amountReward);
    event ClaimReward(address indexed to, uint256 amount);

    constructor(
        IERC20 _lpToken,
        RewardToken _rewardToken
        ) {
            lpToken = _lpToken;
            rewardToken = _rewardToken;
        }

    function stake(uint256 amount) public {
        require(
            amount > 0 &&
            lpToken.balanceOf(msg.sender) >= amount,
            "You cannot stake zero tokens");
        require(!isStaking[msg.sender], "already staked");
        lpToken.transferFrom(msg.sender, address(this), amount);
        stakingBalance[msg.sender] += amount;
        startTime[msg.sender] = block.timestamp;
        isStaking[msg.sender] = true;
        rewardClaimed[msg.sender] = false;
        emit Stake(msg.sender, amount);
    }

    function unstake() public stakingNotEmpty(msg.sender) {
        require(block.timestamp - startTime[msg.sender] > lockTime, "lock is not over yet");
        isStaking[msg.sender] = false;
        uint256 amount = stakingBalance[msg.sender];
        stakingBalance[msg.sender] = 0;
        lpToken.transfer(msg.sender, amount);
        emit Unstake(msg.sender, stakingBalance[msg.sender], (stakingBalance[msg.sender] * rewardShare) / 10000);
    }

    function claim() external stakingNotEmpty(msg.sender) {
        require(block.timestamp - startTime[msg.sender] > claimRewardLockTime, "reward is not unlocked yet");
        require(!rewardClaimed[msg.sender], "reward is already claimed");
        rewardClaimed[msg.sender] = true;
        rewardToken.transfer(msg.sender, (stakingBalance[msg.sender] * rewardShare) / 10000);
        emit ClaimReward(msg.sender, (stakingBalance[msg.sender] * rewardShare) / 10000);
    }

    function setLockTime(uint256 newLockTime) external onlyOwner {
        lockTime = newLockTime;
    }

    function setClaimLockTime(uint256 newClaimLockTime) external onlyOwner {
        claimRewardLockTime = newClaimLockTime;
    }

    modifier stakingNotEmpty(address sender) {
        require(isStaking[sender], "No stake");
        _;
    }
}