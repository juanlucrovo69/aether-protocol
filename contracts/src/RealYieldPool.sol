// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IVeAether {
    function getVotingPower(address user) external view returns (uint256);
    function totalVotingPower() external view returns (uint256);
}

/**
 * @title RealYieldPool
 * @notice Receives 20% of protocol revenue and distributes it as real yield to veAETHER holders.
 * @dev Simplified epoch-based distribution.
 */
contract RealYieldPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IVeAether public immutable veAether;

    struct Epoch {
        uint256 totalVotingPower;
        mapping(address => uint256) tokenAmounts;
        mapping(address => mapping(address => bool)) claimed;
        bool finalized;
    }

    uint256 public currentEpochId;
    mapping(uint256 => Epoch) public epochs;
    mapping(address => uint256) public pendingFunds;

    event FundsReceived(address indexed token, uint256 amount);
    event EpochStarted(uint256 indexed epochId, uint256 totalVotingPower);
    event EpochFinalized(uint256 indexed epochId);
    event Claimed(uint256 indexed epochId, address indexed user, address indexed token, uint256 amount);

    constructor(address initialOwner, address veAether_) Ownable(initialOwner) {
        require(veAether_ != address(0), "Invalid veAether");
        veAether = IVeAether(veAether_);
    }

    function receiveFunds(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "Amount = 0");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        pendingFunds[token] += amount;
        emit FundsReceived(token, amount);
    }

    function startEpoch() external onlyOwner {
        currentEpochId += 1;
        uint256 tvp = veAether.totalVotingPower();
        require(tvp > 0, "No voting power");

        epochs[currentEpochId].totalVotingPower = tvp;
        emit EpochStarted(currentEpochId, tvp);
    }

    function allocateToCurrentEpoch(address token) external onlyOwner {
        uint256 amount = pendingFunds[token];
        require(amount > 0, "No pending funds");
        require(currentEpochId > 0, "No active epoch");

        pendingFunds[token] = 0;
        epochs[currentEpochId].tokenAmounts[token] += amount;
    }

    function finalizeEpoch(uint256 epochId) external onlyOwner {
        require(epochId > 0 && epochId <= currentEpochId, "Invalid epoch");
        epochs[epochId].finalized = true;
        emit EpochFinalized(epochId);
    }

    function claim(uint256 epochId, address token) external nonReentrant {
        Epoch storage epoch = epochs[epochId];
        require(epoch.totalVotingPower > 0, "Epoch not started");
        require(!epoch.claimed[token][msg.sender], "Already claimed");

        uint256 userPower = veAether.getVotingPower(msg.sender);
        require(userPower > 0, "No voting power");

        uint256 totalAmount = epoch.tokenAmounts[token];
        require(totalAmount > 0, "No funds for this token");

        uint256 claimAmount = (totalAmount * userPower) / epoch.totalVotingPower;
        require(claimAmount > 0, "Nothing to claim");

        epoch.claimed[token][msg.sender] = true;
        IERC20(token).safeTransfer(msg.sender, claimAmount);

        emit Claimed(epochId, msg.sender, token, claimAmount);
    }

    function claimable(uint256 epochId, address user, address token) external view returns (uint256) {
        Epoch storage epoch = epochs[epochId];
        if (epoch.totalVotingPower == 0 || epoch.claimed[token][user]) return 0;

        uint256 userPower = veAether.getVotingPower(user);
        if (userPower == 0) return 0;

        uint256 totalAmount = epoch.tokenAmounts[token];
        return (totalAmount * userPower) / epoch.totalVotingPower;
    }

    function emergencyWithdraw(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}
