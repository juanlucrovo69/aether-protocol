# AETHER Tokenomics

**Version:** 1.0  
**Status:** Draft – Ready for internal review  
**Last Updated:** August 2026

---

## 1. Token Overview

| Parameter       | Value                          |
|-----------------|--------------------------------|
| Name            | Aether                         |
| Ticker          | $AETHER                        |
| Standard        | ERC-20                         |
| Total Supply    | 100,000,000 (fixed)            |
| Inflation       | None                           |
| Initial Chain   | Base (multi-chain planned)     |

$AETHER is the value accrual and governance token of the Aether Protocol. Its sole purpose is to capture protocol revenue and align long-term capital with the growth of trading volume and RWA settlement activity.

---

## 2. Token Utility

- **Value Accrual**  
  80% of all protocol revenue → automated weekly buyback & burn  
  20% of all protocol revenue → real yield distributed to veAETHER holders

- **Governance**  
  veAETHER holders control protocol parameters, fee switches, treasury spending, and major upgrades.

- **Boosted Rewards**  
  Locking $AETHER into veAETHER grants up to 2.5x multiplier on real yield share.

- **Access**  
  Future institutional products and higher-tier RWA features may require minimum veAETHER balances.

---

## 3. Supply Allocation

| Category                    | %    | Amount        | Notes                                      |
|-----------------------------|------|---------------|--------------------------------------------|
| Community & Ecosystem       | 35%  | 35,000,000    | Incentives, airdrops, grants, liquidity    |
| Protocol Treasury           | 25%  | 25,000,000    | Multisig + governance controlled           |
| Team & Core Contributors    | 18%  | 18,000,000    | 4-year vesting                             |
| Early Backers / Strategic   | 12%  | 12,000,000    | 2-year vesting                             |
| Liquidity & Market Making   | 10%  | 10,000,000    | Initial DEX + CEX liquidity                |

**Total:** 100,000,000 $AETHER

---

## 4. Vesting Schedule

### Team & Core Contributors (18%)
- Cliff: **12 months**
- Linear vesting after cliff: **36 months**
- Total lock period: **48 months**
- On-chain, non-revocable

### Early Backers / Strategic (12%)
- Cliff: **6 months**
- Linear vesting after cliff: **18 months**
- Total lock period: **24 months**
- On-chain, non-revocable

### Community & Ecosystem (35%)
Released progressively based on growth milestones and incentive programs. No large unlock cliffs.

### Treasury (25%)
Available at TGE but subject to multisig + on-chain governance for any spending.

### Liquidity (10%)
Fully available at TGE for market making.

---

## 5. Value Accrual Mechanics

### Revenue Split
```
Protocol Revenue (Trading Fees + RWA Settlement Fees + Other)
        │
        ├── 80% → BuybackAndBurn (weekly automated)
        └── 20% → RealYieldPool → veAETHER holders
```

### Buyback & Burn
- Executed weekly via automated keeper (Chainlink / Gelato)
- Tokens are purchased on the open market and permanently burned
- Fully transparent and verifiable on-chain

### veAETHER (Vote-Escrow)
- Lock duration: 3 months → 4 years
- Longer lock = higher voting power + higher real yield share
- Maximum boost: **2.5x**
- veAETHER is non-transferable

### Real Yield
- Sourced 100% from protocol revenue (no token emissions)
- Distributed proportionally to veAETHER balances
- Claimable after each epoch

---

## 6. Emission & Inflation Policy

- **Zero inflation**. Total supply is permanently fixed.
- Supply can only decrease through the buyback & burn mechanism.
- No continuous emissions to subsidize yields.

---

## 7. Governance

- Voting power is determined exclusively by veAETHER balance.
- Scope includes fee parameters, treasury allocations, protocol upgrades, and market listings.
- Progressive decentralization from multisig to full on-chain governance.

---

## 8. Design Principles

1. Real yield over emissions
2. Strong long-term capital alignment via locking
3. Fully transparent revenue flow
4. Conservative vesting for team and early capital
5. Institutional-grade clarity and predictability

---

**Document Owner:** Core Team  
**Next Review:** After final fee structure and contract freeze
