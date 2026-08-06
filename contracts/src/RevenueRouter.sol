// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IBuybackAndBurn {
    function receiveFunds(address token, uint256 amount) external;
}

interface IRealYieldPool {
    function receiveFunds(address token, uint256 amount) external;
}

/**
 * @title RevenueRouter
 * @notice Receives protocol revenue and splits it:
 *         80% → BuybackAndBurn
 *         20% → RealYieldPool
 * @dev Can accept any ERC20 fee token. Owner can update destinations.
 */
contract RevenueRouter is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant BUYBACK_BPS = 8000; // 80%
    uint256 public constant YIELD_BPS = 2000;   // 20%
    uint256 public constant BPS_DENOMINATOR = 10000;

    address public buybackAndBurn;
    address public realYieldPool;

    event DestinationsUpdated(address buybackAndBurn, address realYieldPool);
    event RevenueRouted(address indexed token, uint256 totalAmount, uint256 toBuyback, uint256 toYield);

    constructor(address initialOwner, address buybackAndBurn_, address realYieldPool_) Ownable(initialOwner) {
        require(buybackAndBurn_ != address(0) && realYieldPool_ != address(0), "Invalid destinations");
        buybackAndBurn = buybackAndBurn_;
        realYieldPool = realYieldPool_;
    }

    /**
     * @notice Route incoming revenue of a specific token.
     * @dev Caller must approve this contract first, or send tokens then call this.
     */
    function routeRevenue(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "Amount = 0");
        require(token != address(0), "Invalid token");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        uint256 toBuyback = (amount * BUYBACK_BPS) / BPS_DENOMINATOR;
        uint256 toYield = amount - toBuyback; // avoid dust issues

        // Approve and send to destinations
        IERC20(token).forceApprove(buybackAndBurn, toBuyback);
        IBuybackAndBurn(buybackAndBurn).receiveFunds(token, toBuyback);

        IERC20(token).forceApprove(realYieldPool, toYield);
        IRealYieldPool(realYieldPool).receiveFunds(token, toYield);

        emit RevenueRouted(token, amount, toBuyback, toYield);
    }

    /**
     * @notice Update destination contracts (only owner).
     */
    function setDestinations(address buybackAndBurn_, address realYieldPool_) external onlyOwner {
        require(buybackAndBurn_ != address(0) && realYieldPool_ != address(0), "Invalid destinations");
        buybackAndBurn = buybackAndBurn_;
        realYieldPool = realYieldPool_;
        emit DestinationsUpdated(buybackAndBurn_, realYieldPool_);
    }

    /**
     * @notice Emergency withdraw (only owner).
     */
    function emergencyWithdraw(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}
