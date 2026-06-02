#!/usr/bin/env python3
"""
Stock scanner: gets quotes on supplied tickers and ranks by momentum.
Usage: read tickers from stdin (comma-separated or one per line), outputs JSON
"""

import json, sys, subprocess, os

DEFAULT_MCP = os.path.expanduser("~/.openclaw/workspace/skills/robinhood-agentic/rh-client.mjs")
MCP = os.environ.get("MCP_CLIENT_PATH", DEFAULT_MCP)


def get_quotes(tickers):
    """Call Robinhood MCP for real-time quotes on up to 20 symbols."""
    payload = json.dumps({"symbols": tickers[:20]})
    try:
        result = subprocess.run(
            ["node", MCP, "call", "get_equity_quotes", payload],
            capture_output=True, text=True, timeout=30
        )
    except FileNotFoundError:
        return {"error": f"node not found or MCP client not found at {MCP}"}
    except subprocess.TimeoutExpired:
        return {"error": "MCP call timed out after 30s"}
    except Exception as e:
        return {"error": f"MCP call failed: {str(e)}"}

    if result.returncode != 0:
        return {"error": f"MCP failed: {result.stderr.strip()}"}

    raw = result.stdout.strip()
    if not raw:
        return {"error": "Empty MCP response"}

    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return {"error": f"MCP returned non-JSON: {raw[:200]}"}

    # Handle MCP content envelope
    if isinstance(data, dict) and "content" in data:
        for c in data["content"]:
            if c.get("type") == "text":
                try:
                    return json.loads(c["text"])
                except json.JSONDecodeError:
                    return {"error": "MCP content envelope contains non-JSON text"}
    return data


def rank(tickers):
    """Score tickers by momentum (% change from prior close)."""
    quotes = get_quotes(tickers)
    if not isinstance(quotes, dict) or "error" in quotes:
        return [], quotes.get("error") if isinstance(quotes, dict) else "Unknown error"

    rankings = []
    for sym, q in quotes.items():
        if not isinstance(q, dict):
            continue
        last = float(q.get("last_trade_price", 0) or 0)
        prior = float(q.get("prior_close", 0) or 0)
        if prior <= 0 or abs(last - prior) / prior < 0.005:
            continue  # Skip flat tickers (<0.5% absolute move)

        pct = round(((last - prior) / prior) * 100, 2)
        bid = float(q.get("bid_price", 0) or 0)
        ask = float(q.get("ask_price", 0) or 0)
        spread = round((ask - bid) / prior * 100, 2) if ask > bid else 0.0
        rankings.append({
            "symbol": sym,
            "price": last,
            "prior_close": prior,
            "pct_change": pct,
            "spread_pct": spread,
            "score": round(pct, 2),
        })

    rankings.sort(key=lambda x: x["score"], reverse=True)
    return rankings[:5], None


if __name__ == "__main__":
    tickers_input = sys.stdin.read().strip()
    if not tickers_input:
        print(json.dumps({"error": "No tickers provided — pipe comma-separated symbols to stdin"}))
        sys.exit(1)

    # Accept comma-separated or line-delimited
    tickers = [t.strip().upper() for t in tickers_input.replace("\n", ",").split(",") if t.strip()]
    if not tickers:
        print(json.dumps({"error": "No valid tickers after parsing"}))
        sys.exit(1)

    top, err = rank(tickers)
    result = {
        "top": top,
        "parsed": len(tickers),
        "queried": min(len(tickers), 20),
    }
    if err:
        result["error"] = err
    print(json.dumps(result))
