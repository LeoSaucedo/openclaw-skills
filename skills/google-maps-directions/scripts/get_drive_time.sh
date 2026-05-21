#!/bin/bash
# Google Maps drive time calculator with traffic
# Usage: ./get_drive_time.sh "Origin" "Destination" [departure_time]
# Example: ./get_drive_time.sh "Charlotte NC" "Raleigh NC" "now"

API_KEY="$GOOGLE_PLACES_API_KEY"
ORIGIN="${1// /+}"
DEST="${2// /+}"
DEPARTURE_TIME="${3:-now}"

if [ -z "$API_KEY" ]; then
    echo "❌ Error: GOOGLE_PLACES_API_KEY environment variable not set"
    echo "   Set it with: export GOOGLE_PLACES_API_KEY=\"your-api-key\""
    exit 1
fi

if [ -z "$ORIGIN" ] || [ -z "$DEST" ]; then
    echo "📝 Usage: $0 \"Origin Address\" \"Destination Address\" [departure_time]"
    echo "   Examples:"
    echo "   $0 \"Charlotte NC\" \"Raleigh NC\""
    echo "   $0 \"123 Main St, Anytown USA\" \"Tech Hub Office, Anytown USA\" \"tomorrow 8:00\""
    exit 1
fi

# Convert departure time to timestamp if not "now"
if [ "$DEPARTURE_TIME" != "now" ]; then
    # Try to parse date string (requires date command)
    if command -v date >/dev/null 2>&1; then
        TIMESTAMP=$(date -d "$DEPARTURE_TIME" +%s 2>/dev/null)
        if [ -n "$TIMESTAMP" ]; then
            DEPARTURE_TIME="$TIMESTAMP"
        else
            echo "⚠️  Warning: Could not parse departure time '$DEPARTURE_TIME', using 'now'"
            DEPARTURE_TIME="now"
        fi
    else
        echo "⚠️  Warning: date command not available, using 'now'"
        DEPARTURE_TIME="now"
    fi
fi

echo "📍 Calculating drive time..."
echo "   From: $1"
echo "   To: $2"
if [ "$3" ]; then
    echo "   Departure: $3"
fi
echo ""

# Build URL
if [ "$DEPARTURE_TIME" = "now" ]; then
    URL="https://maps.googleapis.com/maps/api/directions/json?origin=$ORIGIN&destination=$DEST&departure_time=now&key=$API_KEY"
else
    URL="https://maps.googleapis.com/maps/api/directions/json?origin=$ORIGIN&destination=$DEST&departure_time=$DEPARTURE_TIME&key=$API_KEY"
fi

# Make API call
RESPONSE=$(curl -s "$URL")
STATUS=$(echo "$RESPONSE" | grep -o '"status" : "[^"]*"' | head -1 | cut -d'"' -f4)

if [ "$STATUS" != "OK" ]; then
    ERROR_MSG=$(echo "$RESPONSE" | grep -o '"error_message" : "[^"]*"' | cut -d'"' -f4)
    echo "❌ API Error: $STATUS"
    if [ -n "$ERROR_MSG" ]; then
        echo "   $ERROR_MSG"
    fi
    exit 1
fi

# Parse response
DISTANCE=$(echo "$RESPONSE" | grep -o '"text" : "[^"]*"' | head -1 | cut -d'"' -f4)
DURATION=$(echo "$RESPONSE" | grep -o '"text" : "[^"]*"' | head -2 | tail -1 | cut -d'"' -f4)
TRAFFIC_DURATION=$(echo "$RESPONSE" | grep -A2 '"duration_in_traffic"' | grep '"text"' | cut -d'"' -f4)

# Calculate traffic delay if available
if [ -n "$TRAFFIC_DURATION" ] && [ "$TRAFFIC_DURATION" != "$DURATION" ]; then
    # Extract minutes from duration strings
    DURATION_MIN=$(echo "$DURATION" | sed 's/.*\([0-9]*\) hour.*/\1*60+/; s/.*\([0-9]*\) min.*/\1/' | bc 2>/dev/null || echo "0")
    TRAFFIC_MIN=$(echo "$TRAFFIC_DURATION" | sed 's/.*\([0-9]*\) hour.*/\1*60+/; s/.*\([0-9]*\) min.*/\1/' | bc 2>/dev/null || echo "0")
    
    if [ -n "$DURATION_MIN" ] && [ -n "$TRAFFIC_MIN" ] && [ "$DURATION_MIN" -gt 0 ] 2>/dev/null; then
        DELAY=$((TRAFFIC_MIN - DURATION_MIN))
        if [ "$DELAY" -gt 0 ]; then
            DELAY_TEXT="(+$DELAY min delay)"
        elif [ "$DELAY" -lt 0 ]; then
            DELAY_TEXT="($DELAY min faster)"
        else
            DELAY_TEXT="(no delay)"
        fi
    else
        DELAY_TEXT=""
    fi
else
    DELAY_TEXT="(traffic data not available)"
fi

echo "✅ Route: $1 → $2"
echo "📏 Distance: $DISTANCE"
echo "⏱️  Normal time: $DURATION"

if [ -n "$TRAFFIC_DURATION" ]; then
    echo "🚦 With traffic: $TRAFFIC_DURATION $DELAY_TEXT"
else
    echo "🚦 Traffic data: Not available for this route"
fi

# Show summary
echo ""
echo "📊 Summary:"
echo "   $DISTANCE • $DURATION normally"
if [ -n "$TRAFFIC_DURATION" ]; then
    echo "   $TRAFFIC_DURATION with current traffic $DELAY_TEXT"
fi