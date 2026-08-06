// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {RealYieldPool} from "../src/RealYieldPool.sol";
import {AetherToken} from "../src/AetherToken.sol";
import {veAether} from "../src/veAether.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockYieldToken is ERC20 {
    constructor() ERC20("Mock Yield", "YLD") {}
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract RealYieldPoolTest is Test {
    RealYieldPool pool;
    AetherToken aether;
    veAether ve;
    MockYieldToken yieldToken;

    address owner = address(this);
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    uint256 constant LOCK_AMOUNT = 10_000e18;
    uint256 constant YIELD_AMOUNT = 1_000e18;

    function setUp() public {
        aether = new AetherToken(owner);
        ve = new veAether(address(aether));
        pool = new RealYieldPool(owner, address(ve));
        yieldToken = new MockYieldToken();

        aether.transfer(alice, LOCK_AMOUNT);
        aether.transfer(bob, LOCK_AMOUNT / 2);

        vm.startPrank(alice);
        aether.approve(address(ve), LOCK_AMOUNT);
        ve.createLock(LOCK_AMOUNT, block.timestamp + 1460 days);
        vm.stopPrank();

        vm.startPrank(bob);
        aether.approve(address(ve), LOCK_AMOUNT / 2);
        ve.createLock(LOCK_AMOUNT / 2, block.timestamp + 365 days);
        vm.stopPrank();

        yieldToken.mint(address(this), YIELD_AMOUNT);
        yieldToken.approve(address(pool), YIELD_AMOUNT);
        pool.receiveFunds(address(yieldToken), YIELD_AMOUNT);
    }

    function test_ReceiveFunds() public view {
        assertEq(pool.pendingFunds(address(yieldToken)), YIELD_AMOUNT);
    }

    function test_StartEpoch() public {
        pool.startEpoch();
        assertEq(pool.currentEpochId(), 1);
        assertGt(ve.totalVotingPower(), 0);
    }

    function test_AllocateAndClaim() public {
        pool.startEpoch();
        pool.allocateToCurrentEpoch(address(yieldToken));
        assertEq(pool.pendingFunds(address(yieldToken)), 0);

        uint256 alicePower = ve.getVotingPower(alice);
        uint256 bobPower = ve.getVotingPower(bob);
        uint256 totalPower = alicePower + bobPower;

        uint256 expectedAlice = (YIELD_AMOUNT * alicePower) / totalPower;

        vm.prank(alice);
        pool.claim(1, address(yieldToken));
        assertEq(yieldToken.balanceOf(alice), expectedAlice);

        uint256 expectedBob = (YIELD_AMOUNT * bobPower) / totalPower;
        vm.prank(bob);
        pool.claim(1, address(yieldToken));
        assertEq(yieldToken.balanceOf(bob), expectedBob);
    }

    function test_CannotClaimTwice() public {
        pool.startEpoch();
        pool.allocateToCurrentEpoch(address(yieldToken));

        vm.startPrank(alice);
        pool.claim(1, address(yieldToken));
        vm.expectRevert("Already claimed");
        pool.claim(1, address(yieldToken));
        vm.stopPrank();
    }

    function test_ClaimableView() public {
        pool.startEpoch();
        pool.allocateToCurrentEpoch(address(yieldToken));

        uint256 claimable = pool.claimable(1, alice, address(yieldToken));
        assertGt(claimable, 0);

        vm.prank(alice);
        pool.claim(1, address(yieldToken));

        assertEq(pool.claimable(1, alice, address(yieldToken)), 0);
    }

    function test_StartEpochRevertsIfNoVotingPower() public {
        veAether emptyVe = new veAether(address(aether));
        RealYieldPool emptyPool = new RealYieldPool(owner, address(emptyVe));

        vm.expectRevert("No voting power");
        emptyPool.startEpoch();
    }

    function test_EmergencyWithdraw() public {
        pool.emergencyWithdraw(address(yieldToken), alice, YIELD_AMOUNT);
        assertEq(yieldToken.balanceOf(alice), YIELD_AMOUNT);
    }
}
