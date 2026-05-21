# DeepSeek API Documentation Reference

## Balance Endpoint

### GET /user/balance
Returns the current balance information for the authenticated user.

**URL:** `https://api.deepseek.com/user/balance`

**Headers:**
- `Accept: application/json`
- `Authorization: Bearer <your_api_token>`

**Response Format:**
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

**Fields:**
- `is_available`: Boolean indicating if balance information is available
- `balance_infos`: Array of balance objects (typically one for USD)
  - `currency`: Currency code (e.g., "USD")
  - `total_balance`: Total available balance
  - `granted_balance`: Free credits/granted balance
  - `topped_up_balance`: User-topped-up balance

## Authentication

The DeepSeek API uses Bearer token authentication. Obtain your API token from:
- DeepSeek Platform Dashboard: https://platform.deepseek.com/api-keys

## Environment Variable

Set your token as an environment variable:
```bash
export DEEPSEEK_API_TOKEN="sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

For persistent storage, add to your shell profile:
```bash
echo 'export DEEPSEEK_API_TOKEN="sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"' >> ~/.bashrc
source ~/.bashrc
```

## Rate Limits

- Default rate limits apply
- Check response headers for rate limit information:
  - `X-RateLimit-Limit`: Total requests allowed per period
  - `X-RateLimit-Remaining`: Remaining requests
  - `X-RateLimit-Reset`: Time when limit resets

## Error Responses

Common HTTP status codes:
- `200`: Success
- `400`: Bad request (invalid parameters)
- `401`: Unauthorized (invalid/missing token)
- `403`: Forbidden (insufficient permissions)
- `429`: Too many requests (rate limited)
- `500`: Internal server error