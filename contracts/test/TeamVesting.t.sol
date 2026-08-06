// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AetherToken} from "../src/AetherToken.sol";
import {TeamVesting} from "../src/TeamVesting.sol";

contract TeamVestingTest is Test {
    AetherToken token;
    TeamVesting vesting;

    address owner = address(this);
    address teamMember = address(0xBEEF);

    uint256 constant AMOUNT = 1_000_000 * 1e18;

    function setUp() public {
        token = new AetherToken(owner);
        vesting = new TeamVesting(address(token), owner);

        token.approve(address(vesting), AMOUNT);
    }

    function testCreateSchedule() public {
        uint256 start = block.timestamp;
        vesting.createSchedule(teamMember, AMOUNT, start);

        TeamVesting.Schedule memory s = vesting.getSchedule(teamMember);
        assertEq(s.totalAmount, AMOUNT);
        assertEq(s.claimed, 0);
        assertTrue(s.initialized);
    }

    function testCannotClaimBeforeCliff() public {
        uint256 start = block.timestamp;
        vesting.createSchedule(teamMember, AMOUNT, start);

        vm.prank(teamMember);
        vm.expectRevert("Nothing to claim");
        vesting.claim();
    }

    function testClaimAfterPartialVesting() public {
        uint256 start = block.timestamp;
        vesting.createSchedule(teamMember, AMOUNT, start);

        vm.warp(start + 365 days + (1095 days / 2));

        uint256 releasable = vesting.releasable(teamMember);
        assertGt(releasable, 0);
        assertLt(releasable, AMOUNT);

        vm.prank(teamMember);
        vesting.claim();

        assertEq(token.balanceOf(teamMember), releasable);
    }

    function testFullVesting() public {
        uint256 start = block.timestamp;
        vesting.createSchedule(teamMember, AMOUNT, start);

        vm.warp(start + 365 days + 1095 days + 1);

        uint256 releasable = vesting.releasable(teamMember);
        assertEq(releasable, AMOUNT);

        vm.prank(teamMember);
        vesting.claim();

        assertEq(token.balanceOf(teamMember), AMOUNT);
        assertEq(vesting.releasable(teamMember), 0);
    }
}
