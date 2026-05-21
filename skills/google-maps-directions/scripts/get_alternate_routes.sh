#!/bin/bash
# Get alternate route options
# Usage: ./get_alternate_routes.sh "Origin" "Destination"
# Example: ./get_alternate_routes.sh "Charlotte NC" "Raleigh NC"

API_KEY="$GOOGLE_PLACES_API_KEY"
ORIGIN="${1// /+}"
DEST="${2// /+}"

if [ -z "$API_KEY" ]; then
    echo "❌ Error: GOOGLE_PLACES_API_KEY environment variable not set"
    exit 1
fi

if [ -z "$ORIGIN" ] || [ -z "$DEST" ]; then
    echo "📝 Usage: $0 \"Origin Address\" \"Destination Address\""
    exit 1
fi

echo "📍 Finding alternate routes..."
echo "   From: $1"
echo "   To: $2"
echo ""

URL="https://maps.googleapis.com/maps/api/directions/json?origin=$ORIGIN&destination=$DEST&alternatives=true&departure_time=now&key=$API_KEY"

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

# Count routes
ROUTE_COUNT=$(echo "$RESPONSE" | grep -c '"routes" : \[')
if [ "$ROUTE_COUNT" -eq 0 ]; then
    echo "No routes found."
    exit 0
fi

echo "🛣️  Found $((ROUTE_COUNT)) route(s):"
echo ""

# Extract each route
ROUTE_NUM=0
while IFS= read -r route_start; do
    ROUTE_NUM=$((ROUTE_NUM + 1))
    
    # Extract this route's section
    ROUTE_SECTION=$(echo "$RESPONSE" | sed -n "/$route_start/,/\"routes\" : \[/p" | head -n -1)
    
    # Get summary if available
    SUMMARY=$(echo "$ROUTE_SECTION" | grep '"summary"' | head -1 | sed 's/.*"summary" : "//; s/".*//')
    
    # Get distance and duration
    DISTANCE=$(echo "$ROUTE_SECTION" | grep -o '"text" : "[^"]*"' | head -1 | cut -d'"' -f4)
    DURATION=$(echo "$ROUTE_SECTION" | grep -o '"text" : "[^"]*"' | head -2 | tail -1 | cut -d'"' -f4)
    TRAFFIC_DURATION=$(echo "$ROUTE_SECTION" | grep -A2 '"duration_in_traffic"' | grep '"text"' | cut -d'"' -f4)
    
    echo "Route $ROUTE_NUM:"
    if [ -n "$SUMMARY" ]; then
        echo "  🛣️  Via: $SUMMARY"
    fi
    echo "  📏 Distance: $DISTANCE"
    echo "  ⏱️  Time: $DURATION"
    if [ -n "$TRAFFIC_DURATION" ]; then
        echo "  🚦 With traffic: $TRAFFIC_DURATION"
        
        # Calculate delay
        DURATION_MIN=$(echo "$DURATION" | sed 's/.*\([0-9]*\) hour.*/\1*60+/; s/.*\([0-9]*\) min.*/\1/' | bc 2>/dev/null || echo "0")
        TRAFFIC_MIN=$(echo "$TRAFFIC_DURATION" | sed 's/.*\([0-9]*\) hour.*/\1*60+/; s/.*\([0-9]*\) min.*/\1/' | bc 2>/dev/null || echo "0")
        
        if [ -n "$DURATION_MIN" ] && [ -n "$TRAFFIC_MIN" ] && [ "$DURATION_MIN" -gt 0 ] 2>/dev/null; then
            DELAY=$((TRAFFIC_MIN - DURATION_MIN))
            if [ "$DELAY" -gt 0 ]; then
                echo "  ⚠️  Traffic delay: +$DELAY minutes"
            elif [ "$DELAY" -lt 0 ]; then
                echo "  ✅ Traffic faster: $DELAY minutes"
            fi
        fi
    fi
    
    # Get first few steps for route preview
    STEPS=$(echo "$ROUTE_SECTION" | sed -n '/"steps" \[/,/\],/p' | head -20)
    STEP_COUNT=$(echo "$STEPS" | grep -c '"html_instructions"')
    
    if [ "$STEP_COUNT" -gt 0 ]; then
        echo "  📍 First few steps:"
        STEP_NUM=1
        while IFS= read -r line; do
            if echo "$line" | grep -q '"html_instructions"' && [ "$STEP_NUM" -le 3 ]; then
                INSTRUCTION=$(echo "$line" | sed 's/.*"html_instructions" : "//; s/",$//; s/<[^>]*>//g; s/&nbsp;/ /g; s/&amp;/\&/g' | cut -c1-50)
                if [ -n "$INSTRUCTION" ]; then
                    echo "     $STEP_NUM. $INSTRUCTION..."
                    STEP_NUM=$((STEP_NUM + 1))
                fi
            fi
        done <<< "$STEPS"
        if [ "$STEP_COUNT" -gt 3 ]; then
            echo "     ... and $((STEP_COUNT - 3)) more steps"
        fi
    fi
    
    echo ""
    
done <<< "$(echo "$RESPONSE" | grep -n '"routes" : \[' | cut -d: -f1 | while read line; do echo "$line"; done)"

echo "💡 Tip: Use './get_directions.sh \"$1\" \"$2\"' for detailed turn-by-turn for a specific route."