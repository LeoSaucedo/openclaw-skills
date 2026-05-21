# Wolfram Alpha API Skill

Simple interface to Wolfram Alpha's computational knowledge engine.

## Quick Start

```bash
# Set your AppID
export WOLFRAM_APP_ID="your-appid-here"

# Run a query
./scripts/query.sh "2+2"
```

## Usage

```bash
./scripts/query.sh "QUERY" [OPTIONS]
```

### Examples

```bash
./scripts/query.sh "population of France"
./scripts/query.sh "solve x^2 + 2x + 1 = 0"
./scripts/query.sh "100 miles to km"
```

### Options

- `--maxchars N` - Limit response length
- `--location "CITY, STATE"` - Add location context
- `--time "YYYY-MM-DD"` - Specify date
- `--units "metric"` - Unit system
- `--raw` - JSON output
- `--simple` - Simple text output

## Files

- `scripts/query.sh` - Main query script
- `SKILL.md` - Skill documentation
- `test_skill.sh` - Test script