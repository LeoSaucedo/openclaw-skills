#!/bin/bash

# Wolfram Alpha LLM API Query Script
# Usage: ./query.sh "QUERY" [OPTIONS]

set -e

# Default values
MAXCHARS="6800"
TIMEOUT="30"
FORMAT="text"
BASE_URL="https://www.wolframalpha.com/api/v1/llm-api"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for AppID
if [ -z "$WOLFRAM_APP_ID" ]; then
    echo -e "${RED}❌ Error: WOLFRAM_APP_ID environment variable not set${NC}"
    echo "Please set your Wolfram Alpha AppID:"
    echo "  export WOLFRAM_APP_ID='your-appid-here'"
    echo "Or add it to your shell profile (~/.bashrc, ~/.zshrc, etc.)"
    exit 1
fi

# Function to display help
show_help() {
    echo -e "${BLUE}Wolfram Alpha LLM API Query Tool${NC}"
    echo "Usage: $0 \"QUERY\" [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --maxchars N      Limit response to N characters (default: 6800)"
    echo "  --assumption \"A\"  Specify query assumption"
    echo "  --location \"L\"    Add location context (e.g., \"Charlotte, NC\")"
    echo "  --latlong \"LAT,LONG\" Specify latitude/longitude"
    echo "  --time \"DATE\"     Specify date for time-sensitive queries (YYYY-MM-DD)"
    echo "  --units \"SYS\"     Unit system: metric or imperial (default: based on location)"
    echo "  --language \"LANG\" Language code (default: en)"
    echo "  --timeout N       Timeout in seconds (default: 30)"
    echo "  --raw             Return raw API JSON response"
    echo "  --simple          Return structured JSON with text and images"
    echo "  --text            Return plain text output (legacy mode)"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 \"What is the population of France?\""
    echo "  $0 \"integrate x^2 from 0 to 1\" --maxchars 1000"
    echo "  $0 \"weather\" --location \"Charlotte, NC\""
    echo "  $0 \"sunrise\" --latlong \"35.2271,-80.8431\" --time \"2026-02-18\""
    exit 0
}

# Parse arguments
QUERY=""
RAW_MODE=false
SIMPLE_MODE=false
TEXT_MODE=false
PARAMS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_help
            ;;
        --maxchars)
            MAXCHARS="$2"
            shift 2
            ;;
        --assumption)
            PARAMS="$PARAMS&assumption=$(echo "$2" | jq -Rr @uri)"
            shift 2
            ;;
        --location)
            PARAMS="$PARAMS&location=$(echo "$2" | jq -Rr @uri)"
            shift 2
            ;;
        --latlong)
            PARAMS="$PARAMS&latlong=$(echo "$2" | jq -Rr @uri)"
            shift 2
            ;;
        --time)
            PARAMS="$PARAMS&time=$(echo "$2" | jq -Rr @uri)"
            shift 2
            ;;
        --units)
            PARAMS="$PARAMS&units=$(echo "$2" | jq -Rr @uri)"
            shift 2
            ;;
        --language)
            PARAMS="$PARAMS&languagecode=$(echo "$2" | jq -Rr @uri)"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --raw)
            RAW_MODE=true
            shift
            ;;
        --simple)
            SIMPLE_MODE=true
            shift
            ;;
        --text)
            TEXT_MODE=true
            shift
            ;;
        *)
            if [ -z "$QUERY" ]; then
                QUERY="$1"
            else
                echo -e "${RED}❌ Error: Multiple queries provided${NC}"
                echo "Please provide only one query at a time"
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if query was provided
if [ -z "$QUERY" ]; then
    echo -e "${RED}❌ Error: No query provided${NC}"
    show_help
fi

# URL encode the query
ENCODED_QUERY=$(echo "$QUERY" | jq -Rr @uri)

# Build the API URL
API_URL="${BASE_URL}?input=${ENCODED_QUERY}&appid=${WOLFRAM_APP_ID}&maxchars=${MAXCHARS}${PARAMS}"

echo -e "${BLUE}🔍 Querying Wolfram Alpha...${NC}"
echo -e "${YELLOW}Query:${NC} $QUERY"

if [ "$RAW_MODE" = true ]; then
    echo -e "${YELLOW}API URL:${NC} $API_URL"
    echo ""
fi

# Make the API request
RESPONSE=$(curl -s \
    --max-time "$TIMEOUT" \
    -H "Accept: application/json" \
    "$API_URL")

# Check for curl errors
CURL_EXIT_CODE=$?
if [ $CURL_EXIT_CODE -ne 0 ]; then
    if [ $CURL_EXIT_CODE -eq 28 ]; then
        echo -e "${RED}❌ Error: Request timed out after ${TIMEOUT} seconds${NC}"
    else
        echo -e "${RED}❌ Error: Failed to connect to Wolfram Alpha API${NC}"
        echo "Curl exit code: $CURL_EXIT_CODE"
    fi
    exit 1
fi

# Check for API errors
if echo "$RESPONSE" | grep -q "Invalid appid"; then
    echo -e "${RED}❌ Error: Invalid AppID${NC}"
    echo "Please check your WOLFRAM_APP_ID environment variable"
    exit 1
fi

if echo "$RESPONSE" | grep -q "Appid missing"; then
    echo -e "${RED}❌ Error: AppID missing from request${NC}"
    exit 1
fi

if echo "$RESPONSE" | grep -q "error"; then
    ERROR_MSG=$(echo "$RESPONSE" | grep -o '"error"[^,}]*' | cut -d'"' -f4)
    echo -e "${RED}❌ API Error: ${ERROR_MSG}${NC}"
    exit 1
fi

# Handle raw mode
if [ "$RAW_MODE" = true ]; then
    echo "$RESPONSE" | jq .
    exit 0
fi

# Extract result text (try to get the main result)
if echo "$RESPONSE" | grep -q "Result:"; then
    RESULT_TEXT=$(echo "$RESPONSE" | grep -A5 "Result:" | head -10 | sed 's/^Result: //' | sed '/^$/d' | tr '\n' ' ' | sed 's/  */ /g')
else
    # Fallback: use first 500 characters of response
    RESULT_TEXT=$(echo "$RESPONSE" | head -c 500 | tr '\n' ' ' | sed 's/  */ /g')
fi

# Extract image URLs (look for image: https:// patterns)
IMAGE_URLS=$(echo "$RESPONSE" | grep -o 'image: https://[^ ]*' | sed 's/image: //')

# Convert image URLs to JSON array
IMAGE_JSON="[]"
if [ -n "$IMAGE_URLS" ]; then
    IMAGE_JSON=$(echo "$IMAGE_URLS" | jq -R -s 'split("\n") | map(select(length > 0))')
fi

# Handle text mode (legacy)
if [ "$TEXT_MODE" = true ]; then
    echo "$RESULT_TEXT"
    if [ -n "$IMAGE_URLS" ]; then
        echo ""
        echo "--- IMAGES ---"
        echo "$IMAGE_URLS"
    fi
    exit 0
fi

# Default: output structured JSON
jq -n \
    --arg query "$QUERY" \
    --arg text "$RESULT_TEXT" \
    --argjson images "$IMAGE_JSON" \
    '{
        query: $query,
        text: $text,
        images: $images,
        success: true
    }'