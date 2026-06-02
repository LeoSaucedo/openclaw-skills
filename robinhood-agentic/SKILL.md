---
name: robinhood-agentic
description: Connect to Robinhood Agentic Trading via MCP — view portfolio, analyze positions, place trades, and execute automated strategies through Robinhood's official MCP server.
metadata:
  author: github.com/LeoSaucedo
  version: "1.0.0"
---

# Robinhood Agentic Trading

Connect to Robinhood Agentic Trading via MCP. This skill lets OpenClaw access your Robinhood Agentic account — view portfolio, analyze positions, place trades, and execute automated strategies.

## Setup

The MCP client (`rh-client.mjs`) handles OAuth 2.1 PKCE authentication to `https://agent.robinhood.com/mcp/trading` and manages token storage/refresh automatically.

### Prerequisites

1. Robinhood Agentic access (still rolling out — you'll get an email)
2. A dedicated Agentic account (created during OAuth flow)
3. Node.js (already on the VPS)

### Install Dependencies

```
cd robinhood-agentic
npm install
```

### First-time Auth

```
node rh-client.mjs auth
```

The script will:
1. Discover Robinhood's OAuth endpoints
2. Generate a PKCE challenge
3. Print an authorization URL → **Open this in your browser**
4. Log into Robinhood, authorize the agent
5. You'll be redirected to `http://localhost:1455/callback?code=XXXX...`
6. **Copy the full redirect URL and paste it** back into the terminal
7. Tokens are stored in `.rh-tokens.json` (gitignored, mode 0600)

## Usage

All commands output to stdout. Errors and status messages go to stderr.

### Check auth status
```
node rh-client.mjs status
```
Returns a JSON object with `authenticated`, `expired`, `expiresAt`, `hasRefreshToken`, and `savedAt`.

### List available MCP tools
```
node rh-client.mjs list-tools
```
Returns a JSON array of tool definitions with names, descriptions, and input schemas.

### Call a tool
```
node rh-client.mjs call <tool_name> '<json_args>'

# Or with stdin for complex args:
echo '{"symbol": "AAPL"}' | node rh-client.mjs call get_quote -
```
Output depends on the MCP tool response — may be plain text or JSON. Error messages go to stderr.

### Refresh token (auto)
Token refresh happens automatically when the access token is within 5 minutes of expiry (only if a refresh token is available). No manual intervention needed unless the refresh token itself expires.

## What OpenClaw Can Do

After auth, OpenClaw can call any tool Robinhood exposes through the MCP server. This typically includes:

- **Portfolio**: account info, balances, positions, P&L
- **Orders**: place market/limit/stop orders, view order history
- **Market data**: quotes, fundamentals, news, historicals
- **Automation**: rebalance, recurring investments, conditional orders

Use `list-tools` first to discover the exact API surface, then call tools as needed.

## Security Notes

- **Separate account**: The Agentic account is separate from your main Robinhood account — fund it with what you're comfortable with the agent managing
- **Tokens stored locally**: OAuth tokens in `.rh-tokens.json` with restrictive 0600 permissions (gitignored, never committed)
- **You're in control**: Robinhood shows trade previews, sends push notifications, and supports instant shutdown
- **Each trade reviewed**: By default, the agent shows what it's about to do before placing orders unless you explicitly enable auto-approval
