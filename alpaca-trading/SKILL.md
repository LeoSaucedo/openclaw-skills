---
name: alpaca-trading
description: Check Alpaca paper trading account balance, positions, ticker stats, place buy/sell orders, view order history, and close positions. Use when the user asks to view their trading account, check their P&L, place a trade, sell a position, get a stock quote, or manage their Alpaca portfolio.
---

# Alpaca Trading

Use the bundled CLI script for all Alpaca interactions. Every command outputs JSON to stdout; errors go to stderr.

## Quick reference

```bash
node <skill_dir>/scripts/alpaca.mjs <command> [args]
```

| Command | Args | Description |
|---------|------|-------------|
| `account` | — | Balance, equity, daily P&L, buying power |
| `positions` | — | All open positions with unrealized P&L |
| `ticker` | `<symbol>` | Latest price and asset info |
| `orders` | `[limit=10]` | Recent orders |
| `buy` | `<symbol> <qty>` | Market buy order |
| `sell` | `<symbol> <qty>` | Market sell order |
| `close` | `<symbol>` | Close entire position |
| `close-all` | — | Close all positions |

## Workflow

1. Resolve `<skill_dir>` to the absolute path of this skill's directory
2. Run the script and capture stdout (JSON) and stderr
3. Format the JSON output into a readable message for the user — use **Discord-friendly formatting** (no markdown tables on Discord, use lists instead)
4. Always confirm before placing orders (buy/sell/close/close-all) — show what will happen and ask the user to confirm
