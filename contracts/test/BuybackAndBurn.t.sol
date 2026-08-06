// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {BuybackAndBurn} from "../src/BuybackAndBurn.sol";
import {AetherToken} from "../src/AetherToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockFeeToken is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

contract BuybackAndBurnTest is Test {
    BuybackAndBurn buyback;
    AetherToken aether;
    MockFeeToken usdc;

    address owner = address(this);
    address keeper = address(0xKEEPER);
    address alice = address(0xA11CE);
    uint256 constant AMOUNT = 1_000e18;

    function setUp() public {
        aether = new AetherToken(owner);
        usdc = new MockFeeToken();
        buyback = new BuybackAndBurn(owner, address(aether), keeper);
        aether.transfer(address(buyback), AMOUNT);
        usdc.mint(alice, AMOUNT);
    }

    function test_Constructor() public view {
        assertEq(address(buyback.aether()), address(aether));
        assertEq(buyback.keeper(), keeper);
    }

    function test_ReceiveFunds() public {
        vm.startPrank(alice);
        usdc.approve(address(buyback), AMOUNT);
        buyback.receiveFunds(address(usdc), AMOUNT);
        vm.stopPrank();
        assertEq(usdc.balanceOf(address(buyback)), AMOUNT);
    }

    function test_ReceiveFundsRevertsOnZero() public {
        vm.expectRevert("Amount = 0");
        buyback.receiveFunds(address(usdc), 0);
    }

    function test_BurnHeldAether() public {
        uint256 before = aether.balanceOf(address(buyback));
        assertEq(before, AMOUNT);
        vm.prank(keeper);
        buyback.burnHeldAether();
        assertEq(aether.balanceOf(address(buyback)), 0);
    }

    function test_BurnHeldAetherOnlyKeeperOrOwner() public {
        vm.prank(alice);
        vm.expectRevert("Not authorized");
        buyback.burnHeldAether();
    }

    function test_ExecuteBuybackWithAether() public {
        aether.transfer(address(buyback), AMOUNT);
        uint256 balBefore = aether.balanceOf(address(buyback));
        vm.prank(keeper);
        buyback.executeBuyback(address(aether), AMOUNT);
        assertEq(aether.balanceOf(address(buyback)), balBefore - AMOUNT);
    }

    function test_ExecuteBuybackRevertsOnOtherToken() public {
        usdc.mint(address(buyback), AMOUNT);
        vm.prank(keeper);
        vm.expectRevert("Swap not implemented yet. Integrate router first.");
        buyback.executeBuyback(address(usdc), AMOUNT);
    }

    function test_SetKeeper() public {
        address newKeeper = address(0xNEW);
        buyback.setKeeper(newKeeper);
        assertEq(buyback.keeper(), newKeeper);
    }

    function test_SetKeeperOnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        buyback.setKeeper(address(0x123));
    }

    function test_EmergencyWithdraw() public {
        usdc.mint(address(buyback), 500e18);
        buyback.emergencyWithdraw(address(usdc), alice, 500e18);
        assertEq(usdc.balanceOf(alice), AMOUNT + 500e18);
    }

    // ==================== FUZZ TESTS ====================

    function testFuzz_BurnHeldAether(uint256 amount) public {
        amount = bound(amount, 1, 10_000_000e18);
        AetherToken freshAether = new AetherToken(owner);
        BuybackAndBurn freshBuyback = new BuybackAndBurn(owner, address(freshAether), keeper);
        freshAether.transfer(address(freshBuyback), amount);
        vm.prank(keeper);
        freshBuyback.burnHeldAether();
        assertEq(freshAether.balanceOf(address(freshBuyback)), 0);
    }

    function testFuzz_ReceiveFunds(uint256 amount) public {
        amount = bound(amount, 1, 1_000_000e18);
        usdc.mint(alice, amount);
        vm.startPrank(alice);
        usdc.approve(address(buyback), amount);
        buyback.receiveFunds(address(usdc), amount);
        vm.stopPrank();
        assertEq(usdc.balanceOf(address(buyback)), amount);
    }

    function testFuzz_ExecuteBuybackAether(uint256 amount) public {
        amount = bound(amount, 1, 5_000_000e18);
        AetherToken freshAether = new AetherToken(owner);
        BuybackAndBurn freshBuyback = new BuybackAndBurn(owner, address(freshAether), keeper);
        freshAether.transfer(address(freshBuyback), amount);
        vm.prank(keeper);
        freshBuyback.executeBuyback(address(freshAether), amount);
        assertEq(freshAether.balanceOf(address(freshBuyback)), 0);
    }
}
