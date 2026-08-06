# Aether Protocol – Architecture

**Version:** 0.1  
**Status:** Draft

---

## High-Level Overview

Aether is an onchain trading and settlement protocol focused on value accrual.

Core components:

1. **Trading Engine** (Perp + Spot)
2. **RWA Settlement Module**
3. **Revenue Router**
4. **Buyback & Burn Engine**
5. **veAETHER + Real Yield Distributor**
6. **Treasury + Governance**

---

## Revenue Flow

```
User Trading / RWA Activity
        │
        ▼
   Protocol Fees
        │
        ▼
  RevenueRouter.sol
        │
   ┌───┬───┐
   │         │
  80%       20%
   │         │
   ▼         ▼
BuybackAndBurn   RealYieldPool
   │                 │
   ▼                 ▼
Market Buy → Burn   Claimable by veAETHER
```

All flows are automated and on-chain.

---

## Smart Contract Architecture

### Core Contracts

| Contract              | Responsibility                              |
|-----------------------|---------------------------------------------|
| AetherToken.sol       | ERC-20 token + burn function                |
| veAether.sol          | Vote-escrow locking logic                   |
| RevenueRouter.sol     | Splits incoming fees 80/20                  |
| BuybackAndBurn.sol    | Weekly market buy + burn execution          |
| RealYieldPool.sol     | Holds and distributes real yield            |
| TeamVesting.sol       | Team allocation vesting                     |
| InvestorVesting.sol   | Early backer vesting                        |
| Treasury.sol          | Protocol treasury (Safe compatible)         |

---

## Key Design Decisions

- **Fixed supply** from day one
- **No continuous emissions**
- **Automated buyback** (no manual intervention)
- **Strong lock incentives** via ve model
- **Separate vesting contracts** for clarity and auditability
- **Multisig + progressive governance**

---

## Deployment Plan (Phase 0)

1. Deploy AetherToken
2. Deploy TeamVesting + InvestorVesting
3. Fund vesting contracts
4. Deploy veAether
5. Deploy RevenueRouter + BuybackAndBurn + RealYieldPool
6. Set permissions and roles
7. Transfer ownership to Safe multisig

---

## Security Considerations

- All critical contracts will be audited before mainnet
- Time-locks on major parameter changes
- Emergency pause capability (limited scope)
- No admin ability to mint additional tokens
- No ability to revoke vesting after deployment

---

## Next Steps

- Finalize fee structure
- Complete Foundry test suite
- External audit
- Public testnet deployment
