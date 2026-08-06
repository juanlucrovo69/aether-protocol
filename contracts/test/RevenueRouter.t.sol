// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {RevenueRouter} from "../src/RevenueRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Simple mock ERC20 for testing
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Fee Token", "FEE") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// Mock destinations that just accept tokens
contract MockBuyback {
    mapping(address => uint256) public received;

    function receiveFunds(address token, uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        received[token] += amount;
    }
}

contract MockYieldPool {
    mapping(address => uint256) public received;

    function receiveFunds(address token, uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        received[token] += amount;
    }
}

contract RevenueRouterTest is Test {
    RevenueRouter router;
    MockERC20 feeToken;
    MockBuyback buyback;
    MockYieldPool yieldPool;

    address owner = address(this);
    address alice = address(0xA11CE);

    uint256 constant AMOUNT = 10_000e18;

    function setUp() public {
        feeToken = new MockERC20();
        buyback = new MockBuyback();
        yieldPool = new MockYieldPool();

        router = new RevenueRouter(owner, address(buyback), address(yieldPool));

        // Mint fee tokens to alice
        feeToken.mint(alice, AMOUNT);
    }

    function test_ConstructorSetsDestinations() public view {
        assertEq(router.buybackAndBurn(), address(buyback));
        assertEq(router.realYieldPool(), address(yieldPool));
    }

    function test_RouteRevenueSplitsCorrectly() public {
        vm.startPrank(alice);
        feeToken.approve(address(router), AMOUNT);
        router.routeRevenue(address(feeToken), AMOUNT);
        vm.stopPrank();

        uint256 expectedBuyback = (AMOUNT * 8000) / 10000; // 80%
        uint256 expectedYield = AMOUNT - expectedBuyback;  // 20%

        assertEq(buyback.received(address(feeToken)), expectedBuyback);
        assertEq(yieldPool.received(address(feeToken)), expectedYield);
        assertEq(feeToken.balanceOf(address(router)), 0);
    }

    function test_RouteRevenueRevertsOnZeroAmount() public {
        vm.startPrank(alice);
        feeToken.approve(address(router), AMOUNT);
        vm.expectRevert("Amount = 0");
        router.routeRevenue(address(feeToken), 0);
        vm.stopPrank();
    }

    function test_RouteRevenueRevertsWithoutApproval() public {
        vm.prank(alice);
        vm.expectRevert(); // SafeERC20 will revert
        router.routeRevenue(address(feeToken), AMOUNT);
    }

    function test_SetDestinationsOnlyOwner() public {
        MockBuyback newBuyback = new MockBuyback();
        MockYieldPool newYield = new MockYieldPool();

        router.setDestinations(address(newBuyback), address(newYield));
        assertEq(router.buybackAndBurn(), address(newBuyback));
        assertEq(router.realYieldPool(), address(newYield));
    }

    function test_SetDestinationsRevertsIfNotOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        router.setDestinations(address(0x1), address(0x2));
    }

    function test_EmergencyWithdraw() public {
        // Send some tokens directly to router
        feeToken.mint(address(router), 1000e18);

        router.emergencyWithdraw(address(feeToken), alice, 1000e18);
        assertEq(feeToken.balanceOf(alice), AMOUNT + 1000e18);
    }

    function test_Constants() public view {
        assertEq(router.BUYBACK_BPS(), 8000);
        assertEq(router.YIELD_BPS(), 2000);
        assertEq(router.BPS_DENOMINATOR(), 10000);
    }
}
