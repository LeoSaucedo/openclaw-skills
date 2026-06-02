#!/usr/bin/env python3
"""
Stock scanner: gets quotes on supplied tickers and ranks by momentum.
Usage: python3 scanner.py [ACCOUNT_NUMBER]
  - Reads tickers from stdin (comma-separated or one per line)
  - Calls Robinhood MCP get_equity_quotes
  - Ranks by % change from prior close
  - Outputs top 5 as JSON
"""

import json, sys, subprocess, os

MCP = os.path.expanduser("~/.openclaw/workspace/skills/robinhood-agentic/rh-client.mjs")

def get_quotes(tickers):
    """Call Robinhood MCP for real-time quotes on up to 20 symbols."""
    payload = json.dumps({"symbols": tickers[:20]})
    result = subprocess.run(
        ["node", MCP, "call", "get_equity_quotes", payload],
        capture_output=True, text=True, timeout=30
    )
    if result.returncode != 0:
        print(json.dumps({"error": f"MCP failed: {result.stderr.strip()}"}))
        sys.exit(1)

    raw = result.stdout.strip()
    if not raw:
        print(json.dumps({"error": "Empty MCP response"}))
        sys.exit(1)

    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        print(json.dumps({"error": f"JSON parse: {raw[:200]}"}))
        sys.exit(1)

    # Handle MCP content envelope
    if isinstance(data, dict) and "content" in data:
        for c in data["content"]:
            if c.get("type") == "text":
                return json.loads(c["text"])
    return data


def rank(tickers):
    """Score tickers by momentum (% change from prior close)."""
    quotes = get_quotes(tickers)
    if not quotes or "error" in quotes:
        return []

    rankings = []
    for sym, q in quotes.items():
        if not isinstance(q, dict):
            continue
        last = float(q.get("last_trade_price", 0) or 0)
        prior = float(q.get("prior_close", 0) or 0)
        if prior <= 0 or abs(last - prior) / prior < 0.003:
            continue  # Skip flat tickers (<0.3% move)

        pct = round(((last - prior) / prior) * 100, 2)
        spread = round((float(q.get("bid_price", 0) or 0) - float(q.get("ask_price", 0) or 0)) / prior * 100, 2)
        rankings.append({
            "symbol": sym,
            "price": last,
            "prior_close": prior,
            "pct_change": pct,
            "spread_pct": spread,
            "score": round(pct, 2),
        })

    rankings.sort(key=lambda x: x["score"], reverse=True)
    return rankings[:5]


if __name__ == "__main__":
    tickers_input = sys.stdin.read().strip()
    if not tickers_input:
        print(json.dumps({"error": "No tickers provided"}))
        sys.exit(1)

    # Accept comma-separated or line-delimited
    tickers = [t.strip().upper() for t in tickers_input.replace("\n", ",").split(",") if t.strip()]
    if not tickers:
        print(json.dumps({"error": "No valid tickers"}), file=sys.stderr)
        sys.exit(1)

    top = rank(tickers)
    print(json.dumps({"top": top, "scanned": len(tickers)}))
