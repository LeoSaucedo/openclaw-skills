---
name: ada-trader
description: Automated daily swing trading strategy — scans pre-market movers, picks momentum stocks, buys at open, manages exits at afternoon check with stop-loss and profit targets. Designed for small cash accounts ($500) using Robinhood Agentic MCP.
metadata:
  author: github.com/LeoSaucedo
  version: "1.0.0"
  openclaw:
    emoji: "📈"
    requires:
      bins: ["node", "pnpm", "python3"]
      skills: ["robinhood-agentic"]
---

# Ada Trader

Daily swing trading with dynamic stock selection. Scans pre-market movers, ranks by momentum, buys at open, manages exits with stop-loss and profit targets.

## Account Requirements

- Cash account (no PDT rule)
- T+1 settlement
- Funded Robinhood Agentic account (separate from main)
- Complete investor profile (one-time Robinhood requirement)

## Setup

### 1. Install Dependencies

The Robinhood Agentic skill must be installed and authenticated:
```bash
cd robinhood-agentic && pnpm install && node rh-client.mjs auth
```

### 2. Create Cron Jobs

Two crons required, both pointing at this skill:

**Morning Routine** (M-F, 9:30 AM ET):
```
schedule: "30 9 * * 1-5" (America/New_York)
payload: "Read the ada-trader skill and execute the Morning Routine. Post to your trading channel."
delivery: announce to your trading channel
timeout: 600s, thinking: medium
```

**Afternoon Routine** (M-F, 3:30 PM ET):
```
schedule: "30 15 * * 1-5" (America/New_York)
payload: "Read the ada-trader skill and execute the Afternoon Routine. Post to your trading channel."
delivery: announce to your trading channel
timeout: 600s, thinking: minimal
```

### 3. Customize

Adjust max positions in the Strategy Parameters table. Trade size is automatically set to **10% of total account value** — no manual editing needed.

---

## Strategy Parameters

| Parameter | Value |
|---|---|
| Chunk size | 10% of account value (auto-calculated) |
| Max positions | 5 (or until settled cash exhausted) |
| Stop-loss | -5% from entry |
| Profit target | +10% from entry |
| Daily sell rule | Close the oldest open position every afternoon |

---

## Stock Selection

Pick fresh tickers each morning — no static watchlist. Use web_search for:
- "top pre-market movers today high volume"
- "stocks with biggest pre-market gains today"

Compile 10-15 tickers with an absolute move of at least ±0.5% in pre-market. Prefer stocks with clear catalysts (earnings, analyst upgrades, sector momentum, news). Flat market = fewer picks.

---

## Morning Routine

### 1. Find Today's Movers
Search for pre-market movers and compile 10-15 tickers.

### 2. Rank With Scanner
```bash
echo "TICKER1,TICKER2,..." | python3 ~/.openclaw/workspace/skills/ada-trader/scripts/scanner.py
```
Pick the top-ranked symbol. The scanner calls the Robinhood MCP for live quotes and ranks by momentum (% change from prior close).

### 3. Announce the Pick
Post to channel: symbol, current price, % change, catalyst, target +10%, stop -5%.

### 4. Check Portfolio & Calculate Chunk
```bash
node ~/.openclaw/workspace/skills/robinhood-agentic/rh-client.mjs call get_portfolio '{"account_number":"<ACCT>"}'
```
Extract `total_value`. Calculate **chunk = total_value × 0.10** (rounded to 2 decimals). Verify settled cash ≥ chunk. Get account_number from `get_accounts` if needed. If not enough cash, post why and skip.

### 5. Review & Place Buy Order

First, review the order to surface pre-trade warnings:
```bash
node ~/.openclaw/workspace/skills/robinhood-agentic/rh-client.mjs call review_equity_order '{"account_number":"<ACCT>","symbol":"<PICK>","side":"buy","type":"market","dollar_amount":"<CHUNK>","time_in_force":"gfd","market_hours":"regular_hours"}'
```
Post any alerts from the review output to the channel. Then place the order:
```bash
node ~/.openclaw/workspace/skills/robinhood-agentic/rh-client.mjs call place_equity_order '{"account_number":"<ACCT>","symbol":"<PICK>","side":"buy","type":"market","dollar_amount":"<CHUNK>","time_in_force":"gfd","market_hours":"regular_hours"}'
```
Replace `<CHUNK>` with the calculated 10% value (e.g. `"50.00"` for a $500 account).
The user handles final approval in the Robinhood app. Advanced users may skip the review step if they understand the risks.

---

## Afternoon Routine

### 1. Check Positions
```bash
node ~/.openclaw/workspace/skills/robinhood-agentic/rh-client.mjs call get_equity_positions '{"account_number":"<ACCT>"}'
```

### 2. Get Current Quotes
```bash
node ~/.openclaw/workspace/skills/robinhood-agentic/rh-client.mjs call get_equity_quotes '{"symbols":["TICKER1","TICKER2"]}'
```
Calculate P&L: (current_price - avg_cost) / avg_cost × 100.

### 3. Apply Sell Rules
- P&L ≥ +10% → SELL (profit target)
- P&L ≤ -5% → SELL (stop-loss)
- OLDEST open position → SELL (maintain daily rhythm — sell at least 1 per day)
- P&L between -3% and -5% AND market weakening → SELL (EOD risk cut)

### 4. Review & Place Sell Orders

First, review the sell order to surface any pre-trade warnings:
```bash
node ~/.openclaw/workspace/skills/robinhood-agentic/rh-client.mjs call review_equity_order '{"account_number":"<ACCT>","symbol":"<TICKER>","side":"sell","type":"market","quantity":"<ALL SHARES FROM POSITIONS>","time_in_force":"gfd","market_hours":"regular_hours"}'
```
Post any alerts. Then place:
```bash
node ~/.openclaw/workspace/skills/robinhood-agentic/rh-client.mjs call place_equity_order '{"account_number":"<ACCT>","symbol":"<TICKER>","side":"sell","type":"market","quantity":"<ALL SHARES FROM POSITIONS>","time_in_force":"gfd","market_hours":"regular_hours"}'
```
Use `quantity` (number of shares), NOT `dollar_amount`, for sell orders. The user handles final approval in the Robinhood app. Advanced users may skip the review step if they understand the risks.

### 5. Report
Post to channel: what sold, P&L per position, remaining positions.
