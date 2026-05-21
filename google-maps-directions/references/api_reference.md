# Google Maps Directions API Reference

## API Endpoint

```
GET https://maps.googleapis.com/maps/api/directions/json
```

## Required Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `origin` | Starting point | `Charlotte+NC` or `35.2271,-80.8431` |
| `destination` | Ending point | `Raleigh+NC` or `35.7796,-78.6382` |
| `key` | API key | `YOUR_API_KEY` |

## Optional Parameters

### Routing Options
| Parameter | Description | Values |
|-----------|-------------|---------|
| `mode` | Travel mode | `driving` (default), `walking`, `bicycling`, `transit` |
| `alternatives` | Show alternate routes | `true` or `false` |
| `avoid` | Route restrictions | `tolls`, `highways`, `ferries`, `indoor` |
| `units` | Distance units | `metric` or `imperial` (default) |

### Traffic & Timing
| Parameter | Description | Format |
|-----------|-------------|---------|
| `departure_time` | Departure time for traffic | `now` or UNIX timestamp |
| `arrival_time` | Desired arrival time | UNIX timestamp |
| `traffic_model` | Traffic prediction model | `best_guess`, `pessimistic`, `optimistic` |

### Waypoints
| Parameter | Description | Format |
|-----------|-------------|---------|
| `waypoints` | Intermediate stops | `via:Charlotte+NC` or `35.2271,-80.8431` |

### Regionalization
| Parameter | Description | Example |
|-----------|-------------|---------|
| `region` | Region code | `us` |
| `language` | Response language | `en` |

## Response Format

### Success Response (status: "OK")
```json
{
  "geocoded_waypoints": [...],
  "routes": [
    {
      "bounds": {...},
      "copyrights": "Map data ©2026 Google",
      "legs": [
        {
          "distance": {"text": "166 mi", "value": 266815},
          "duration": {"text": "2 hours 34 mins", "value": 9212},
          "duration_in_traffic": {"text": "2 hours 42 mins", "value": 9737},
          "end_address": "Raleigh, NC, USA",
          "end_location": {"lat": 35.7796, "lng": -78.6382},
          "start_address": "Charlotte, NC, USA",
          "start_location": {"lat": 35.2271, "lng": -80.8431},
          "steps": [...],
          "via_waypoint": []
        }
      ],
      "overview_polyline": {...},
      "summary": "I-85 N and I-40 E",
      "warnings": [],
      "waypoint_order": []
    }
  ],
  "status": "OK"
}
```

### Error Responses
| Status | Description | Common Causes |
|--------|-------------|---------------|
| `NOT_FOUND` | Location not found | Invalid address, misspelling |
| `ZERO_RESULTS` | No route found | Impossible route (overseas) |
| `MAX_WAYPOINTS_EXCEEDED` | Too many waypoints | >25 waypoints |
| `INVALID_REQUEST` | Missing parameters | No origin/destination |
| `OVER_DAILY_LIMIT` | API quota exceeded | Daily limit reached |
| `OVER_QUERY_LIMIT` | Rate limit exceeded | Too many requests |
| `REQUEST_DENIED` | API key issue | Invalid key, disabled API |
| `UNKNOWN_ERROR` | Server error | Try again later |

## Traffic Data Availability

### When `duration_in_traffic` is provided:
- Current time requests with `departure_time=now`
- Future time requests (up to 1 week ahead)
- Driving mode only
- Available regions (most urban areas)

### When traffic data may be missing:
- Rural areas with no traffic sensors
- Walking/bicycling/transit modes
- Historical times (beyond prediction range)
- Some countries/regions

## Rate Limits and Quotas

### Free Tier (Google Maps Platform)
- $200 monthly credit
- Directions API: $0.005 per request (~40,000 requests/month)
- Dynamic traffic data: additional cost may apply

### Best Practices
1. **Cache results** - Store frequently used routes
2. **Batch requests** - Use Distance Matrix API for multiple calculations
3. **Validate addresses** - Reduce `NOT_FOUND` errors
4. **Handle errors gracefully** - Implement retry logic
5. **Monitor usage** - Track against $200 monthly credit

## Common Use Cases

### 1. Simple Drive Time
```bash
curl "https://maps.googleapis.com/maps/api/directions/json?origin=Charlotte+NC&destination=Raleigh+NC&key=API_KEY"
```

### 2. With Traffic
```bash
curl "https://maps.googleapis.com/maps/api/directions/json?origin=Charlotte+NC&destination=Raleigh+NC&departure_time=now&key=API_KEY"
```

### 3. Multiple Waypoints
```bash
curl "https://maps.googleapis.com/maps/api/directions/json?origin=Start&destination=End&waypoints=via:Stop1|via:Stop2&key=API_KEY"
```

### 4. Avoid Highways
```bash
curl "https://maps.googleapis.com/maps/api/directions/json?origin=Start&destination=End&avoid=highways&key=API_KEY"
```

## Integration Notes

### Same API Key as Places API
The `GOOGLE_PLACES_API_KEY` works for Directions API if:
1. Directions API is enabled in Google Cloud Console
2. API key has proper permissions

### Enabling the API
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Enable "Directions API"
4. Ensure API key has access

### Cost Considerations
- Each request costs $0.005
- Traffic data may have additional costs
- Monthly $200 credit covers ~40,000 requests
- Monitor usage in Cloud Console