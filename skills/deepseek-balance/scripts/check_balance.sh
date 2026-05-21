#!/bin/bash
# DeepSeek Balance Check Script
# Usage: ./check_balance.sh

# Check if DEEPSEEK_API_TOKEN is set
if [ -z "${DEEPSEEK_API_TOKEN}" ]; then
    echo "❌ Error: DEEPSEEK_API_TOKEN environment variable is not set."
    echo "Please set your DeepSeek API token with:"
    echo "  export DEEPSEEK_API_TOKEN='your-token-here'"
    exit 1
fi

# Make the API request
response=$(curl -s -L -X GET 'https://api.deepseek.com/user/balance' \
  -H 'Accept: application/json' \
  -H "Authorization: Bearer ${DEEPSEEK_API_TOKEN}" \
  -w "\n%{http_code}")

# Split response and HTTP code
http_code=$(echo "$response" | tail -n1)
api_response=$(echo "$response" | head -n -1)

# Check for curl errors
if [ $? -ne 0 ]; then
    echo "❌ Network error: Failed to connect to DeepSeek API."
    echo "Possible causes:"
    echo "  - Network connectivity issues"
    echo "  - API endpoint may be down"
    echo "  - DNS resolution problems"
    exit 1
fi

# Check HTTP status code
if [ "$http_code" != "200" ]; then
    echo "❌ API Error: HTTP $http_code"
    
    case $http_code in
        401)
            echo "Authentication failed. Your DEEPSEEK_API_TOKEN may be invalid or expired."
            echo "Please check your token and try again."
            ;;
        403)
            echo "Forbidden. Your token may not have permission to access balance information."
            ;;
        429)
            echo "Rate limited. Too many requests. Please wait before trying again."
            ;;
        500|502|503|504)
            echo "Server error. DeepSeek API may be experiencing issues. Try again later."
            ;;
        *)
            echo "Response: $api_response"
            ;;
    esac
    exit 1
fi

# Parse and display the balance
echo "$api_response"