#!/bin/bash
# Get detailed turn-by-turn directions
# Usage: ./get_directions.sh "Origin" "Destination" [mode]
# Example: ./get_directions.sh "Charlotte NC" "Raleigh NC" driving

API_KEY="$GOOGLE_PLACES_API_KEY"
ORIGIN="${1// /+}"
DEST="${2// /+}"
MODE="${3:-driving}"

if [ -z "$API_KEY" ]; then
    echo "❌ Error: GOOGLE_PLACES_API_KEY environment variable not set"
    exit 1
fi

if [ -z "$ORIGIN" ] || [ -z "$DEST" ]; then
    echo "📝 Usage: $0 \"Origin Address\" \"Destination Address\" [mode]"
    echo "   Modes: driving, walking, bicycling, transit"
    exit 1
fi

# Validate mode
VALID_MODES="driving walking bicycling transit"
if [[ ! " $VALID_MODES " =~ " $MODE " ]]; then
    echo "⚠️  Warning: Invalid mode '$MODE'. Using 'driving'."
    MODE="driving"
fi

echo "📍 Getting $MODE directions..."
echo "   From: $1"
echo "   To: $2"
echo ""

URL="https://maps.googleapis.com/maps/api/directions/json?origin=$ORIGIN&destination=$DEST&mode=$MODE&key=$API_KEY"

if [ "$MODE" = "driving" ]; then
    URL="$URL&departure_time=now"
fi

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

# Parse summary info
DISTANCE=$(echo "$RESPONSE" | grep -o '"text" : "[^"]*"' | head -1 | cut -d'"' -f4)
DURATION=$(echo "$RESPONSE" | grep -o '"text" : "[^"]*"' | head -2 | tail -1 | cut -d'"' -f4)

if [ "$MODE" = "driving" ]; then
    TRAFFIC_DURATION=$(echo "$RESPONSE" | grep -A2 '"duration_in_traffic"' | grep '"text"' | cut -d'"' -f4)
fi

echo "✅ $MODE Directions: $1 → $2"
echo "📏 Total distance: $DISTANCE"
echo "⏱️  Total time: $DURATION"
if [ -n "$TRAFFIC_DURATION" ]; then
    echo "🚦 With traffic: $TRAFFIC_DURATION"
fi
echo ""

# Extract and display steps
echo "📋 Turn-by-turn directions:"
echo ""

# Get steps
STEPS=$(echo "$RESPONSE" | sed -n '/"steps" \[/,/\],/p')

STEP_NUM=1
while IFS= read -r line; do
    if echo "$line" | grep -q '"html_instructions"'; then
        INSTRUCTION=$(echo "$line" | sed 's/.*"html_instructions" : "//; s/",$//; s/<[^>]*>//g; s/&nbsp;/ /g; s/&amp;/\&/g')
        if [ -n "$INSTRUCTION" ]; then
            # Get distance for this step
            DIST_LINE=$(echo "$RESPONSE" | grep -A5 "$line" | grep '"distance"' | head -1)
            STEP_DIST=$(echo "$DIST_LINE" | sed 's/.*"text" : "//; s/".*//')
            
            # Get duration for this step
            DUR_LINE=$(echo "$RESPONSE" | grep -A5 "$line" | grep '"duration"' | head -1)
            STEP_DUR=$(echo "$DUR_LINE" | sed 's/.*"text" : "//; s/".*//')
            
            echo "$STEP_NUM. $INSTRUCTION"
            if [ -n "$STEP_DIST" ] && [ -n "$STEP_DUR" ]; then
                echo "   └─ $STEP_DIST • $STEP_DUR"
            fi
            echo ""
            STEP_NUM=$((STEP_NUM + 1))
        fi
    fi
done <<< "$STEPS"

if [ $STEP_NUM -eq 1 ]; then
    echo "No step-by-step directions available for this route."
fi

echo ""
echo "📍 End of directions"