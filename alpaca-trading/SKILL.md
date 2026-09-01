---
name: alpaca-trading
description: Check Alpaca trading account balance, positions, ticker stats, place buy/sell orders, view order history, and close positions. Supports both paper and live trading via ALPACA_ENV. Use when the user asks to view their trading account, check their P&L, place a trade, sell a position, get a stock quote, or manage their Alpaca portfolio.
metadata:
  author: github.com/LeoSaucedo
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

## Prerequisites

Set these environment variables (or place them in a `.env` file — see the script's `loadEnv()` for supported locations):

| Variable | Description |
|----------|-------------|
| `ALPACA_API_KEY` | Alpaca API key ID (also accepts `APCA_API_KEY_ID`) |
| `ALPACA_API_SECRET` | Alpaca API secret key (also accepts `APCA_API_SECRET_KEY`) |
| `ALPACA_ENV` | Set to `"live"` for live trading (defaults to paper) |

## Confirmation Guard

Mutating commands (`buy`, `sell`, `close`, `close-all`) require explicit confirmation. Pass `--yes`/`-y` or set `ALPACA_CONFIRM=1` to skip the prompt.

The script will fail with a clear error if either is missing.

## Workflow

1. Resolve `<skill_dir>` to the absolute path of this skill's directory
2. Run the script and capture stdout (JSON) and stderr
3. Format the JSON output into a readable message for the user — use **Discord-friendly formatting** (no markdown tables on Discord, use lists instead)
4. Before placing orders (`buy`, `sell`, `close`, `close-all`): always confirm with the user what will happen. To auto-approve, pass `--yes` or set `ALPACA_CONFIRM=1`
