# Aether Protocol

**High-performance onchain trading venue + RWA settlement layer with aggressive real yield and buyback mechanics.**

$AETHER is designed for long-term capital. 80% of all protocol revenue is used for weekly buyback & burn. 20% is distributed as real yield to veAETHER holders.

## Core Value Proposition

- Fixed supply (100,000,000 $AETHER)
- Zero inflation
- Automated weekly buyback & burn (80% of revenue)
- Real yield to locked holders (20% of revenue)
- Vote-escrow model (veAETHER) with up to 2.5x boost
- Conservative vesting for team and early backers
- Transparent on-chain revenue flow

## Tokenomics Summary

| Category                  | Allocation | Amount       |
|---------------------------|------------|--------------|
| Community & Ecosystem     | 35%        | 35,000,000   |
| Protocol Treasury         | 25%        | 25,000,000   |
| Team & Core Contributors  | 18%        | 18,000,000   |
| Early Backers / Strategic | 12%        | 12,000,000   |
| Liquidity & Market Making | 10%        | 10,000,000   |

**Full tokenomics:** [docs/tokenomics.md](docs/tokenomics.md)

## Vesting

- **Team**: 12-month cliff + 36-month linear (total 48 months)
- **Investors**: 6-month cliff + 18-month linear (total 24 months)

All vesting is on-chain and non-revocable after deployment.

## Repository Structure

```
├── contracts/
│   ├── src/           # Core smart contracts
│   ├── test/          # Foundry tests
│   └── script/        # Deployment scripts
├── docs/
│   ├── tokenomics.md
│   └── architecture.md
├── audits/            # Audit reports (to be added)
└── frontend/          # Dashboard (coming)
```

## Tech Stack

- Solidity 0.8.24+
- Foundry
- OpenZeppelin Contracts
- Chainlink / Gelato Keepers (for automated buyback)

## Status

**Phase 0 – Foundation**  
Smart contracts under active development.  
Not yet audited. Do not use in production.

## License

MIT

---

Built for long-term alignment.  
Questions → open an issue or contact the core team.
