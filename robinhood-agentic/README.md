# Robinhood Agentic Trading

MCP client for [Robinhood Agentic Trading](https://robinhood.com/us/en/support/articles/agentic-trading-overview/) — connect an AI agent to a dedicated Robinhood account for automated investing.

## Install

```bash
cd robinhood-agentic
npm install
```

## Authentication

Robinhood Agentic uses OAuth 2.1 with PKCE. Run the auth command and follow the prompts:

```bash
node rh-client.mjs auth
```

This opens a browser for Robinhood login, then you paste the redirect URL back. Tokens are stored in `.rh-tokens.json` with 0600 permissions and never committed.

Set `RH_TOKEN_FILE` to override the token storage path. Set `RH_DEBUG=1` for verbose logging.

## Usage

```bash
# Check auth status
node rh-client.mjs status

# Discover available MCP tools
node rh-client.mjs list-tools

# Call a tool
node rh-client.mjs call get_portfolio
node rh-client.mjs call place_order '{"symbol":"AAPL","quantity":1,"side":"buy"}'

# Pipe complex args from stdin
echo '{"symbol":"AAPL"}' | node rh-client.mjs call get_quote -
```

## How It Works

- Uses `@modelcontextprotocol/sdk` v1.29 Streamable HTTP transport
- Connects to `https://agent.robinhood.com/mcp/trading`
- OAuth 2.1 PKCE with manual paste flow (headless-friendly)
- Automatic token refresh at 5 minutes before expiry
- RFC 8707 resource indicators, RFC 7591 dynamic client registration

## Requirements

- Robinhood Agentic access (rolling out — wait for email)
- A dedicated Agentic account (separate from your main Robinhood)
- Node.js ≥ 18

## Security

- Separate Agentic account isolates AI trades from your main portfolio
- OAuth tokens stored with restrictive 0600 permissions, gitignored
- Trade previews and push notifications on every order
- Spending caps and instant shutdown available in Robinhood settings
