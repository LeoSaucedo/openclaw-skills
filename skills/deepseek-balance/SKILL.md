---
name: deepseek-balance
description: Check DeepSeek API balance and usage. Use when the user asks about -  "Check my DeepSeek balance", "How much API credit do I have left?", "What's my DeepSeek usage?", "DeepSeek account status", "API token balance", or any query related to DeepSeek platform credits, usage, or account information.
metadata:
  author: github.com/LeoSaucedo
---

# deepseek-balance

## Quick Start

To check your DeepSeek API balance:

1. **Ensure your API token is set** as an environment variable:
   ```bash
   export DEEPSEEK_API_TOKEN="sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
   ```

2. **Run the balance check** using the provided script or direct curl command.

## How to Check Balance

### Using the Script (Recommended)

The `scripts/check_balance.sh` script handles error checking and formatting:

```bash
./scripts/check_balance.sh
```

### Manual curl Command

If you prefer to run directly:

```bash
curl -L -X GET 'https://api.deepseek.com/user/balance' \
  -H 'Accept: application/json' \
  -H "Authorization: Bearer ${DEEPSEEK_API_TOKEN}"
```

## Expected Response Format

The API returns JSON in this format:
```json
{
  "is_available": true,
  "balance_infos": [
    {
      "currency": "USD",
      "total_balance": "1.85",
      "granted_balance": "0.00",
      "topped_up_balance": "1.85"
    }
  ]
}
```

## Formatting the Response

When displaying the balance to the user:

1. **Check if token is set** - Show error if `DEEPSEEK_API_TOKEN` is empty
2. **Make API call** - Handle network/API errors gracefully
3. **Parse response** - Extract balance information
4. **Format output** - Present in a friendly, readable format

### Example Output Format:
```
💰 DeepSeek Balance: $1.85
- Total: $1.85
- Granted: $0.00 (free credits)
- Topped up: $1.85 (your payments)
```

## Error Handling

### Common Issues and Solutions:

1. **Token not set:**
   - Error: "DEEPSEEK_API_TOKEN environment variable is not set"
   - Solution: Export the token: `export DEEPSEEK_API_TOKEN="your-token"`

2. **API Errors (HTTP 401, 403, 429, 5xx):**
   - Display the HTTP status code and error message
   - Suggest common fixes based on status code
   - See [Error Codes](references/error_codes.md) for detailed troubleshooting

3. **Network Errors:**
   - Check connectivity to `api.deepseek.com`
   - Suggest network troubleshooting steps

## Maintaining Agent Personality

When implementing this skill, respect and maintain whatever personality the OpenClaw instance running it has. Do not impose a specific personality - instead, adapt to the existing tone and style of the agent. Return results in a way that matches the agent's established communication style.

## References

For detailed information, consult:
- [API Documentation](references/api_docs.md) - DeepSeek API endpoints and formats
- [Error Codes](references/error_codes.md) - Troubleshooting common issues

## Scripts

- `scripts/check_balance.sh` - Main script to check balance with proper error handling
