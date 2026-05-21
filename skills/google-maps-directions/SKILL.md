---
name: google-maps-directions
description: Calculate driving times distances and routes using Google Maps Directions API with real-time traffic data. Use when the user asks for drive time traffic directions commute time or routing between locations. Requires GOOGLE_PLACES_API_KEY environment variable same key works for Directions API.
metadata:
  author: github.com/LeoSaucedo
---

# Google Maps Directions

## Overview

This skill enables accurate travel time and distance calculations using Google Maps Directions API with real-time traffic consideration. It provides drive times, distances, step-by-step directions, and traffic-aware duration estimates between any two locations.

## Quick Start

### Basic Drive Time Calculation

To get drive time between two locations:

```bash
./scripts/get_drive_time.sh "Origin Address" "Destination Address"
```

Example:
```bash
./scripts/get_drive_time.sh "123 Main St, Anytown USA" "Tech Hub Office, Anytown USA"
```

### API Key Requirement

The skill requires `GOOGLE_PLACES_API_KEY` environment variable (same key used for goplaces skill). Verify it's set:

```bash
echo $GOOGLE_PLACES_API_KEY | wc -c  # Should show >0 characters
```

## Core Capabilities

### 1. Drive Time with Traffic

Get normal duration and traffic-adjusted duration:

```bash
# Using the script
./scripts/get_drive_time.sh "Charlotte NC" "Raleigh NC"

# Direct curl (for reference)
curl "https://maps.googleapis.com/maps/api/directions/json?origin=Charlotte+NC&destination=Raleigh+NC&departure_time=now&key=$GOOGLE_PLACES_API_KEY"
```

**Output includes:**
- Distance (miles/km)
- Normal duration (without traffic)
- Duration with traffic (when available)
- Traffic delay calculation

### 2. Step-by-Step Directions

Get detailed turn-by-turn directions:

```bash
./scripts/get_directions.sh "Origin" "Destination"
```

The script returns:
- Total distance and time
- Each step with instructions
- Distance and time per step
- Maneuvers (turns, highway exits, etc.)

### 3. Multiple Travel Modes

Support for different travel modes:
- `driving` (default) - Car with traffic consideration
- `walking` - Pedestrian routes
- `bicycling` - Bike paths and routes
- `transit` - Public transportation

```bash
./scripts/get_directions.sh "Origin" "Destination" walking
```

### 4. Alternative Routes

Get multiple route options when available:

```bash
./scripts/get_alternate_routes.sh "Origin" "Destination"
```

## Common Use Cases

### Commute Time Calculation
```bash
./scripts/get_drive_time.sh "Home Address" "Work Address"
```

### Trip Planning
```bash
./scripts/get_directions.sh "Charlotte NC" "Atlanta GA"
```

### Real-time Traffic Check
```bash
./scripts/get_traffic_delay.sh "Current Location" "Destination"
```

### Distance Matrix (Multiple Origins/Destinations)
See [references/distance_matrix.md](references/distance_matrix.md) for advanced usage.

## Error Handling

Common errors and solutions:

1. **"ZERO_RESULTS"**: No route found between locations
   - Check address spelling
   - Try more general locations (city names instead of specific addresses)

2. **"NOT_FOUND"**: Location not recognized
   - Use standard address format
   - Include city and state

3. **"REQUEST_DENIED"**: API key issue
   - Verify `GOOGLE_PLACES_API_KEY` is set
   - Ensure Directions API is enabled in Google Cloud Console

4. **No traffic data**: `duration_in_traffic` missing
   - Traffic data may not be available for the route/time
   - Use `departure_time=now` parameter

## Advanced Features

### Departure Time Specification
Calculate travel time for future departures:

```bash
./scripts/get_drive_time.sh "Origin" "Destination" "tomorrow 8:00 AM"
```

### Waypoints
Add intermediate stops to route:
```bash
./scripts/get_route_with_waypoints.sh "Start" "Stop1,Stop2,Stop3" "End"
```

### Avoidances
Avoid tolls, highways, or ferries:
```bash
./scripts/get_directions.sh "Origin" "Destination" driving "tolls|highways"
```

## Resources

### scripts/
- `get_drive_time.sh` - Basic drive time with traffic
- `get_directions.sh` - Detailed turn-by-turn directions
- `get_alternate_routes.sh` - Multiple route options
- `get_traffic_delay.sh` - Traffic delay calculation
- `get_route_with_waypoints.sh` - Routes with intermediate stops

### references/
- `api_reference.md` - Google Maps Directions API documentation
- `error_codes.md` - Complete error code reference
- `distance_matrix.md` - Advanced multi-point calculations
- `best_practices.md` - Usage tips and optimization

## Performance Tips

1. **Cache results** for frequently queried routes
2. **Batch requests** using Distance Matrix API for multiple calculations
3. **Use city names** when precise addresses aren't needed (faster)
4. **Set appropriate departure_time** for accurate traffic data
5. **Handle rate limits** - Google API has usage limits

## Integration Examples

### With goplaces skill
```bash
# First find a place
goplaces search "coffee shop" --limit 1
# Then calculate drive time
./scripts/get_drive_time.sh "Current Location" "Coffee Shop Address"
```

### For trip planning
```bash
# Calculate total trip time with multiple stops
./scripts/get_route_with_waypoints.sh "Home" "Gas Station,Grocery Store" "Destination"
```

## Notes

- Traffic data is most accurate for current time and near-future
- Some rural areas may not have traffic data
- Walking and bicycling times don't include traffic considerations
- Transit times include schedule information when available
- API has daily usage limits (check Google Cloud Console)