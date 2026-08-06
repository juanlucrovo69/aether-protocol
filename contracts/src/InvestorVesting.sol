// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title InvestorVesting
 * @notice Vesting contract for early backers / strategic allocation.
 * @dev 6-month cliff + 18-month linear vesting. Non-revocable after schedule creation.
 */
contract InvestorVesting is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Schedule {
        uint256 totalAmount;
        uint256 startTime;
        uint256 cliff;          // in seconds
        uint256 duration;       // vesting duration after cliff
        uint256 claimed;
        bool initialized;
    }

    IERC20 public immutable token;
    uint256 public constant CLIFF = 182 days;       // ~6 months
    uint256 public constant DURATION = 547 days;    // ~18 months

    mapping(address => Schedule) public schedules;

    event ScheduleCreated(address indexed beneficiary, uint256 amount, uint256 startTime);
    event Claimed(address indexed beneficiary, uint256 amount);

    constructor(address token_, address initialOwner) Ownable(initialOwner) {
        require(token_ != address(0), "Invalid token");
        token = IERC20(token_);
    }

    /**
     * @notice Creates a vesting schedule for a beneficiary.
     * @dev Can only be called once per beneficiary.
     */
    function createSchedule(address beneficiary, uint256 amount, uint256 startTime) external onlyOwner {
        require(beneficiary != address(0), "Invalid beneficiary");
        require(amount > 0, "Amount must be > 0");
        require(!schedules[beneficiary].initialized, "Schedule already exists");
        require(startTime >= block.timestamp - 1 days, "Start time too old");

        schedules[beneficiary] = Schedule({
            totalAmount: amount,
            startTime: startTime,
            cliff: CLIFF,
            duration: DURATION,
            claimed: 0,
            initialized: true
        });

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit ScheduleCreated(beneficiary, amount, startTime);
    }

    /**
     * @notice Returns the amount currently releasable for a beneficiary.
     */
    function releasable(address beneficiary) public view returns (uint256) {
        Schedule memory s = schedules[beneficiary];
        if (!s.initialized) return 0;

        if (block.timestamp < s.startTime + s.cliff) {
            return 0;
        }

        uint256 elapsed = block.timestamp - (s.startTime + s.cliff);

        if (elapsed >= s.duration) {
            return s.totalAmount - s.claimed;
        }

        uint256 vested = (s.totalAmount * elapsed) / s.duration;
        return vested - s.claimed;
    }

    /**
     * @notice Claims vested tokens for the caller.
     */
    function claim() external nonReentrant {
        uint256 amount = releasable(msg.sender);
        require(amount > 0, "Nothing to claim");

        schedules[msg.sender].claimed += amount;
        token.safeTransfer(msg.sender, amount);

        emit Claimed(msg.sender, amount);
    }

    /**
     * @notice Returns full schedule data.
     */
    function getSchedule(address beneficiary) external view returns (Schedule memory) {
        return schedules[beneficiary];
    }
}
