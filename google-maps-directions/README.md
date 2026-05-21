# google-maps-directions

Google Maps Directions skill for drive time, routes, and traffic-aware navigation data.

## Files

- `SKILL.md` — skill manifest and full usage details
- `scripts/get_drive_time.sh` — travel time and distance
- `scripts/get_directions.sh` — step-by-step directions
- `scripts/get_alternate_routes.sh` — alternate route options
- `references/` — API docs and error references

## Quick Start

```bash
export GOOGLE_PLACES_API_KEY="your_api_key_here"
./scripts/get_drive_time.sh "Origin Address" "Destination Address"
```

## Common Commands

```bash
./scripts/get_directions.sh "Origin" "Destination"
./scripts/get_alternate_routes.sh "Origin" "Destination"
```

## Required Environment Variable

- `GOOGLE_PLACES_API_KEY`
