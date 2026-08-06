// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title veAether
 * @notice Vote-escrow locking for AETHER.
 * @dev Simplified implementation. Lock duration 3 months – 4 years.
 *      Longer lock = higher voting power and yield boost (up to 2.5x).
 *      This is a foundational version – full production version will include
 *      proper point history and slope calculations similar to Curve.
 */
contract veAether is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct LockedBalance {
        uint256 amount;
        uint256 end; // unlock timestamp
    }

    IERC20 public immutable token;

    uint256 public constant MIN_LOCK = 90 days;      // 3 months
    uint256 public constant MAX_LOCK = 1460 days;    // 4 years
    uint256 public constant MAX_BOOST = 250;         // 2.5x (in basis points / 100)

    mapping(address => LockedBalance) public locked;
    mapping(address => uint256) public votingPower;

    uint256 public totalLocked;
    uint256 public totalVotingPower;

    event Locked(address indexed user, uint256 amount, uint256 unlockTime);
    event IncreasedAmount(address indexed user, uint256 amount);
    event IncreasedTime(address indexed user, uint256 unlockTime);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address token_) {
        require(token_ != address(0), "Invalid token");
        token = IERC20(token_);
    }

    function createLock(uint256 amount, uint256 unlockTime) external nonReentrant {
        require(amount > 0, "Amount = 0");
        require(locked[msg.sender].amount == 0, "Already locked");
        require(unlockTime > block.timestamp + MIN_LOCK, "Lock too short");
        require(unlockTime <= block.timestamp + MAX_LOCK, "Lock too long");

        locked[msg.sender] = LockedBalance({
            amount: amount,
            end: unlockTime
        });

        uint256 power = _calculatePower(amount, unlockTime);
        votingPower[msg.sender] = power;
        totalLocked += amount;
        totalVotingPower += power;

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit Locked(msg.sender, amount, unlockTime);
    }

    function increaseAmount(uint256 amount) external nonReentrant {
        LockedBalance memory lock = locked[msg.sender];
        require(lock.amount > 0, "No existing lock");
        require(lock.end > block.timestamp, "Lock expired");
        require(amount > 0, "Amount = 0");

        uint256 oldPower = votingPower[msg.sender];
        locked[msg.sender].amount += amount;

        uint256 newPower = _calculatePower(locked[msg.sender].amount, lock.end);
        votingPower[msg.sender] = newPower;
        totalLocked += amount;
        totalVotingPower = totalVotingPower - oldPower + newPower;

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit IncreasedAmount(msg.sender, amount);
    }

    function increaseUnlockTime(uint256 newUnlockTime) external nonReentrant {
        LockedBalance memory lock = locked[msg.sender];
        require(lock.amount > 0, "No existing lock");
        require(lock.end > block.timestamp, "Lock expired");
        require(newUnlockTime > lock.end, "New time must be later");
        require(newUnlockTime <= block.timestamp + MAX_LOCK, "Lock too long");

        uint256 oldPower = votingPower[msg.sender];
        locked[msg.sender].end = newUnlockTime;

        uint256 newPower = _calculatePower(lock.amount, newUnlockTime);
        votingPower[msg.sender] = newPower;
        totalVotingPower = totalVotingPower - oldPower + newPower;

        emit IncreasedTime(msg.sender, newUnlockTime);
    }

    function withdraw() external nonReentrant {
        LockedBalance memory lock = locked[msg.sender];
        require(lock.amount > 0, "No lock");
        require(block.timestamp >= lock.end, "Lock not expired");

        uint256 amount = lock.amount;
        uint256 power = votingPower[msg.sender];

        delete locked[msg.sender];
        delete votingPower[msg.sender];

        totalLocked -= amount;
        totalVotingPower -= power;

        token.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function _calculatePower(uint256 amount, uint256 unlockTime) internal view returns (uint256) {
        if (unlockTime <= block.timestamp) return 0;

        uint256 remaining = unlockTime - block.timestamp;
        if (remaining > MAX_LOCK) remaining = MAX_LOCK;

        uint256 boost = 100 + (150 * remaining / MAX_LOCK); // 100 = 1x, 250 = 2.5x
        return (amount * boost) / 100;
    }

    function getVotingPower(address user) external view returns (uint256) {
        LockedBalance memory lock = locked[user];
        if (lock.amount == 0 || block.timestamp >= lock.end) return 0;
        return _calculatePower(lock.amount, lock.end);
    }
}
