# alpaca-trading

Interact with an Alpaca trading account from OpenClaw — check balance, view positions, place orders, and manage holdings. Supports both paper and live trading via `ALPACA_ENV`.

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

- `ALPACA_API_KEY` — Alpaca API key ID (also accepts `APCA_API_KEY_ID`)
- `ALPACA_API_SECRET` — Alpaca API secret key (also accepts `APCA_API_SECRET_KEY`)
- `ALPACA_ENV` — Set to `"live"` for live trading (defaults to paper)

## Confirmation

Mutating commands (`buy`, `sell`, `close`, `close-all`) require confirmation. Pass `--yes`/`-y` or set `ALPACA_CONFIRM=1` to auto-approve.
