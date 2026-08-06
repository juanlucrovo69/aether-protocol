// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IAetherToken {
    function burn(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title BuybackAndBurn
 * @notice Receives 80% of protocol revenue and executes buyback + burn of $AETHER.
 * @dev Simplified version. In production this will integrate with a DEX router.
 */
contract BuybackAndBurn is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IAetherToken public immutable aether;
    address public keeper;

    event FundsReceived(address indexed token, uint256 amount);
    event BuybackExecuted(address indexed tokenSpent, uint256 amountSpent, uint256 aetherBurned);
    event KeeperUpdated(address newKeeper);
    event EmergencyWithdraw(address token, address to, uint256 amount);

    constructor(address initialOwner, address aether_, address keeper_) Ownable(initialOwner) {
        require(aether_ != address(0), "Invalid AETHER");
        aether = IAetherToken(aether_);
        keeper = keeper_;
    }

    modifier onlyKeeperOrOwner() {
        require(msg.sender == keeper || msg.sender == owner(), "Not authorized");
        _;
    }

    function receiveFunds(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "Amount = 0");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit FundsReceived(token, amount);
    }

    function executeBuyback(address token, uint256 amountIn) external onlyKeeperOrOwner nonReentrant {
        require(amountIn > 0, "Amount = 0");
        require(IERC20(token).balanceOf(address(this)) >= amountIn, "Insufficient balance");

        uint256 aetherBurned;

        if (token == address(aether)) {
            aether.burn(amountIn);
            aetherBurned = amountIn;
        } else {
            revert("Swap not implemented yet. Integrate router first.");
        }

        emit BuybackExecuted(token, amountIn, aetherBurned);
    }

    function burnHeldAether() external onlyKeeperOrOwner {
        uint256 balance = aether.balanceOf(address(this));
        require(balance > 0, "No AETHER to burn");
        aether.burn(balance);
        emit BuybackExecuted(address(aether), balance, balance);
    }

    function setKeeper(address newKeeper) external onlyOwner {
        keeper = newKeeper;
        emit KeeperUpdated(newKeeper);
    }

    function emergencyWithdraw(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
        emit EmergencyWithdraw(token, to, amount);
    }
}
