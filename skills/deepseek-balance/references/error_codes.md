# DeepSeek API Error Codes and Troubleshooting

## Common Error Codes

### HTTP 401 - Unauthorized
**Meaning:** Invalid or missing authentication token.

**Possible causes:**
1. Token not set in environment variable
2. Token expired or revoked
3. Incorrect token format
4. Token doesn't have balance permission

**Solutions:**
1. Check if `DEEPSEEK_API_TOKEN` is set: `echo $DEEPSEEK_API_TOKEN`
2. Regenerate token at https://platform.deepseek.com/api-keys
3. Ensure token starts with `sk-`
4. Verify token has appropriate permissions

### HTTP 403 - Forbidden
**Meaning:** Token valid but insufficient permissions.

**Possible causes:**
1. Token doesn't have balance read permission
2. Account restrictions
3. IP address blocked

**Solutions:**
1. Check token permissions in DeepSeek dashboard
2. Contact DeepSeek support if needed
3. Try from different network if IP blocked

### HTTP 429 - Too Many Requests
**Meaning:** Rate limit exceeded.

**Possible causes:**
1. Too many API calls in short period
2. Concurrent requests exceeding limits

**Solutions:**
1. Wait before making another request
2. Implement exponential backoff
3. Check rate limit headers in response

### HTTP 5xx - Server Errors
**Meaning:** DeepSeek API server issues.

**Possible causes:**
1. API maintenance or downtime
2. Server overload
3. Network issues between you and API

**Solutions:**
1. Check DeepSeek status page (if available)
2. Wait and retry later
3. Try from different location/network

## Network Errors

### curl: (6) Could not resolve host
**Meaning:** DNS resolution failed.

**Solutions:**
1. Check internet connection
2. Verify `api.deepseek.com` resolves: `nslookup api.deepseek.com`
3. Try using different DNS (e.g., 8.8.8.8)

### curl: (7) Failed to connect
**Meaning:** Cannot establish connection.

**Solutions:**
1. Check firewall/proxy settings
2. Verify network connectivity
3. Try from different network

### curl: (28) Operation timed out
**Meaning:** Request timeout.

**Solutions:**
1. Increase timeout: `curl --max-time 30`
2. Check network latency
3. API may be slow to respond

## Environment Issues

### "DEEPSEEK_API_TOKEN: unbound variable"
**Meaning:** Environment variable not set in current shell.

**Solutions:**
1. Export variable: `export DEEPSEEK_API_TOKEN="your-token"`
2. Add to shell profile for persistence
3. Use `.env` file with source command

### Permission denied on script
**Meaning:** Script not executable.

**Solutions:**
1. Make executable: `chmod +x check_balance.sh`
2. Run with bash: `bash check_balance.sh`

## Quick Diagnostic Commands

```bash
# Check if token is set
echo "Token set: ${DEEPSEEK_API_TOKEN:+YES}"

# Test basic connectivity
curl -I https://api.deepseek.com

# Test API with token (simple check)
curl -s -H "Authorization: Bearer ${DEEPSEEK_API_TOKEN}" \
  https://api.deepseek.com/user/balance | head -c 100
```

## Getting Help

1. **DeepSeek Documentation:** https://platform.deepseek.com/api-docs
2. **Support:** Contact through DeepSeek platform
3. **Community:** Check forums or Discord for similar issues