# Google Maps Directions API Error Codes

## Common Error Status Codes

### `OK`
- **Description**: Request was successful
- **Action**: Process response normally

### `NOT_FOUND`
- **Description**: At least one of the locations specified in the request was not found
- **Common Causes**:
  - Misspelled address
  - Non-existent address
  - Address in unsupported country
- **Solutions**:
  - Verify address spelling
  - Use more general location (city instead of street)
  - Check if location exists in Google Maps
  - Try different format (coordinates instead of address)

### `ZERO_RESULTS`
- **Description**: No route could be found between the origin and destination
- **Common Causes**:
  - Impossible route (overseas without ferry/air)
  - Restrictive avoid parameters
  - Mode not available (walking across ocean)
- **Solutions**:
  - Check if route is physically possible
  - Remove avoid restrictions
  - Try different travel mode
  - Add waypoints for complex routes

### `MAX_WAYPOINTS_EXCEEDED`
- **Description**: Too many waypoints were provided
- **Limit**: Maximum 25 waypoints
- **Solutions**:
  - Reduce number of waypoints
  - Split into multiple requests
  - Use optimized waypoint order

### `INVALID_REQUEST`
- **Description**: The provided request was invalid
- **Common Causes**:
  - Missing required parameters
  - Invalid parameter values
  - Malformed URL
- **Solutions**:
  - Check all required parameters are present
  - Validate parameter formats
  - Ensure URL encoding is correct

### `OVER_DAILY_LIMIT`
- **Description**: Daily quota has been exceeded
- **Common Causes**:
  - Exceeded $200 monthly credit
  - High volume of requests
- **Solutions**:
  - Wait until next day (quota resets at midnight Pacific Time)
  - Upgrade billing account
  - Implement request caching
  - Reduce request frequency

### `OVER_QUERY_LIMIT`
- **Description**: Rate limit exceeded (requests per second)
- **Common Causes**:
  - Too many requests in short period
  - Concurrent requests exceeding limit
- **Solutions**:
  - Implement exponential backoff
  - Reduce request rate
  - Add delays between requests
  - Use batch requests (Distance Matrix API)

### `REQUEST_DENIED`
- **Description**: Service denied use of the Directions API
- **Common Causes**:
  - API not enabled in Google Cloud Console
  - Invalid API key
  - Billing not set up
  - Project disabled
- **Solutions**:
  - Verify API is enabled in Cloud Console
  - Check API key validity
  - Ensure billing is set up
  - Verify project is active

### `UNKNOWN_ERROR`
- **Description**: Unknown server error
- **Common Causes**:
  - Google server issues
  - Temporary network problems
- **Solutions**:
  - Retry request after delay
  - Check Google Cloud Status Dashboard
  - Implement retry logic with backoff

## Error Message Format

### Response Structure
```json
{
  "error_message": "Detailed error description",
  "routes": [],
  "status": "ERROR_CODE"
}
```

### Example Error Response
```json
{
  "error_message": "API key not valid. Please pass a valid API key.",
  "routes": [],
  "status": "REQUEST_DENIED"
}
```

## Troubleshooting Guide

### Step 1: Check API Key
```bash
# Test API key validity
curl "https://maps.googleapis.com/maps/api/directions/json?origin=Charlotte+NC&destination=Raleigh+NC&key=YOUR_KEY"
```

### Step 2: Verify API Enabled
1. Go to Google Cloud Console
2. Navigation Menu → APIs & Services → Library
3. Search for "Directions API"
4. Ensure it shows "API enabled"

### Step 3: Check Billing
1. Google Cloud Console → Billing
2. Ensure billing account is linked
3. Verify payment method is valid
4. Check if $200 credit is exhausted

### Step 4: Validate Parameters
```bash
# Minimal valid request
curl "https://maps.googleapis.com/maps/api/directions/json?origin=City+State&destination=City+State&key=KEY"
```

## Rate Limiting Details

### Quotas by Pricing Tier

| Tier | Requests/Day | Requests/Second | Cost |
|------|-------------|----------------|------|
| Free | ~40,000* | 10-50 QPS | $0.005/request |
| Paid | Custom | Custom | Volume discounts |

*Based on $200 monthly credit

### Best Practices to Avoid Limits

1. **Implement Caching**
   ```python
   # Cache results for frequently queried routes
   cache_duration = 3600  # 1 hour for traffic data
   ```

2. **Use Exponential Backoff**
   ```python
   import time
   
   def make_request_with_backoff(url, max_retries=3):
       for attempt in range(max_retries):
           response = make_request(url)
           if response.status != "OVER_QUERY_LIMIT":
               return response
           time.sleep(2 ** attempt)  # Exponential backoff
   ```

3. **Batch Requests**
   - Use Distance Matrix API for multiple origin-destination pairs
   - Combine related queries

4. **Monitor Usage**
   - Track request counts
   - Set up alerts for quota thresholds
   - Use Google Cloud Monitoring

## Specific Error Scenarios

### Scenario 1: Address Not Found
**Problem**: `NOT_FOUND` for valid address
**Solution**:
```bash
# Try coordinates instead
curl "https://maps.googleapis.com/maps/api/directions/json?origin=35.2271,-80.8431&destination=35.7796,-78.6382&key=KEY"
```

### Scenario 2: No Route Available  
**Problem**: `ZERO_RESULTS` for possible route
**Solution**:
```bash
# Remove avoid restrictions
curl "https://maps.googleapis.com/maps/api/directions/json?origin=Start&destination=End&key=KEY"
# Instead of:
curl "https://maps.googleapis.com/maps/api/directions/json?origin=Start&destination=End&avoid=highways|ferries|tolls&key=KEY"
```

### Scenario 3: Rate Limited
**Problem**: `OVER_QUERY_LIMIT` during peak usage
**Solution**:
```python
import time
import random

def make_request_safely(url):
    time.sleep(random.uniform(0.1, 0.5))  # Add jitter
    return make_request(url)
```

## Debugging Tools

### 1. Google Cloud Console
- API Dashboard: Monitor usage, errors, latency
- Logs Viewer: Detailed request logs
- Quotas Page: View and request quota increases

### 2. Command Line Testing
```bash
# Verbose curl for debugging
curl -v "https://maps.googleapis.com/maps/api/directions/json?origin=test&destination=test&key=KEY"

# Test with minimal parameters
curl "https://maps.googleapis.com/maps/api/directions/json?origin=City&destination=City&key=KEY"
```

### 3. Online Validators
- Google Maps Platform API Checker
- Postman collections
- Custom validation scripts

## Prevention Strategies

### 1. Input Validation
- Validate addresses before sending to API
- Use autocomplete for address entry
- Sanitize special characters

### 2. Error Handling
- Implement comprehensive error handling
- Provide user-friendly error messages
- Log errors for analysis

### 3. Monitoring
- Set up alerts for error rate increases
- Monitor quota usage daily
- Track response times and success rates

### 4. Fallback Strategies
- Cache previous successful results
- Use alternative routing services as backup
- Implement degraded functionality when API unavailable