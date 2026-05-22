# alpaca-trading

Interact with an Alpaca paper trading account from OpenClaw — check balance, view positions, place orders, and manage holdings.

## Files

- `SKILL.md` — skill manifest and usage guidance
- `scripts/alpaca.mjs` — CLI script for all Alpaca API interactions

## Quick Start

```bash
export ALPACA_API_KEY="your-paper-api-key"
export ALPACA_API_SECRET="your-paper-api-secret"
node scripts/alpaca.mjs account
```

## Commands

| Command | Description |
|---------|-------------|
| `account` | Balance, equity, daily P&L, buying power |
| `positions` | All open positions with unrealized P&L |
| `ticker <sym>` | Asset info and pricing |
| `orders [n]` | Recent order history |
| `buy <sym> <qty>` | Market buy order |
| `sell <sym> <qty>` | Market sell order |
| `close <sym>` | Close position |
| `close-all` | Close all positions |

## Required Environment Variables

- `ALPACA_API_KEY` — Alpaca paper trading API key
- `ALPACA_API_SECRET` — Alpaca paper trading API secret
