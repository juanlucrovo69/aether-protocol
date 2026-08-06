// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AetherToken
 * @notice Fixed supply ERC-20 token for Aether Protocol.
 * @dev Total supply is minted once at deployment. No further minting possible.
 */
contract AetherToken is ERC20, ERC20Burnable, Ownable {
    uint256 public constant TOTAL_SUPPLY = 100_000_000 * 1e18; // 100,000,000 AETHER

    constructor(address initialOwner) ERC20("Aether", "AETHER") Ownable(initialOwner) {
        _mint(initialOwner, TOTAL_SUPPLY);
    }

    /**
     * @notice Burns tokens from the caller's balance.
     * @dev Used by BuybackAndBurn contract and users.
     */
    function burn(uint256 amount) public override {
        super.burn(amount);
    }

    /**
     * @notice Burns tokens from a specific account (requires allowance).
     */
    function burnFrom(address account, uint256 amount) public override {
        super.burnFrom(account, amount);
    }
}
