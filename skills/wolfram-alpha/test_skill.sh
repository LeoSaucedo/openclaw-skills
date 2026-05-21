#!/bin/bash

# Test script for Wolfram Alpha API Skill

set -e

echo "Testing Wolfram Alpha API Skill"
echo "================================"

# Check if AppID is set
if [ -z "$WOLFRAM_APP_ID" ]; then
    echo "Error: WOLFRAM_APP_ID environment variable not set"
    echo "Please set it first: export WOLFRAM_APP_ID='your-appid-here'"
    exit 1
fi

echo "WOLFRAM_APP_ID is set"
echo ""

# Test basic query
echo "1. Testing basic query..."
./scripts/query.sh "2+2"
echo ""

# Test with options
echo "2. Testing with location..."
./scripts/query.sh "weather" --location "Charlotte, NC"
echo ""

echo "Tests completed"
echo ""
echo "Usage: ./scripts/query.sh \"QUERY\" [OPTIONS]"