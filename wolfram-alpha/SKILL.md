---
name: wolfram-alpha
description: Query Wolfram Alpha LLM API for computational knowledge, mathematics, science, and factual data.
metadata:
  author: github.com/LeoSaucedo
---

# Wolfram Alpha API Skill

Query Wolfram Alpha's computational knowledge engine.

## Usage

```bash
./scripts/query.sh "QUERY" [OPTIONS]
```

## Examples

```bash
./scripts/query.sh "What is the population of France?"
./scripts/query.sh "integrate x^2 from 0 to 1"
./scripts/query.sh "convert 100 miles to kilometers"
```

## Options

- `--maxchars N` - Limit response to N characters (default: 6800)
- `--assumption "ASSUMPTION"` - Specify query assumption
- `--location "CITY, STATE"` - Add location context
- `--latlong "LAT,LONG"` - Specify latitude/longitude
- `--time "YYYY-MM-DD"` - Specify date for time-sensitive queries
- `--units "metric"` - Specify unit system (metric/imperial)
- `--language "en"` - Language code (default: en)
- `--timeout N` - Timeout in seconds (default: 30)
- `--raw` - Return raw API JSON response
- `--simple` - Return structured JSON with text and images (default)
- `--text` - Return plain text output (legacy)

## Setup

Set your Wolfram Alpha AppID:

```bash
export WOLFRAM_APP_ID="your-appid-here"
```

## Error Handling

Common errors and solutions:

1. **"Invalid appid (403)"** - Check WOLFRAM_APP_ID environment variable
2. **"Appid missing (403)"** - AppID not set or empty
3. **HTTP 501** - Query cannot be interpreted, try rephrasing
4. **HTTP 400** - Missing input parameter, check query syntax
5. **No results** - Query may be outside Wolfram Alpha's knowledge domain

## Best Practices

### Query Optimization
- Use concise, keyword-based queries
- Be specific about what you want to compute
- Use proper mathematical notation when possible
- For ambiguous terms, add clarifying context

### Response Processing
- The API returns LLM-optimized text with clear formatting
- Mathematical results use proper notation
- Unit conversions include both values
- Complex results are structured with sections

### Rate Limiting
- Free tier has limited daily requests
- Commercial plans available for higher usage
- Implement caching for frequent queries

## Integration Examples

### With OpenClaw Assistant
```bash
# In an OpenClaw session
exec: ./scripts/query.sh "distance from Earth to Moon"
```

### For Research Tasks
```bash
# Get multiple related facts
./scripts/fact.sh "GDP of China"
./scripts/fact.sh "population of China"
./scripts/fact.sh "area of China"
```

### Mathematical Problem Solving
```bash
# Solve complex math problems
./scripts/math.sh "integrate e^(-x^2) from -infinity to infinity"
./scripts/math.sh "Fourier transform of sin(x)"
```

## Examples Directory

Check `examples/` for sample queries and outputs:
- `examples/mathematics.md` - Math query examples
- `examples/science.md` - Science and engineering
- `examples/geography.md` - Geography and demographics
- `examples/everyday.md` - Everyday calculations

## Resources

### References
- `references/api_reference.md` - Complete API documentation
- `references/error_codes.md` - Error code explanations
- `references/query_guide.md` - Query formulation guide
- `references/units.md` - Supported units and conversions

### External Links
- [Wolfram Alpha LLM API Documentation](https://products.wolframalpha.com/llm-api/documentation)
- [Developer Portal](https://developer.wolframalpha.com)
- [API Terms of Use](https://products.wolframalpha.com/api/termsofuse)
- [Full Results API](https://products.wolframalpha.com/api/documentation)

## Notes

- Queries should be in English (non-English queries are auto-translated)
- Results are optimized for LLM consumption
- Some topics may be restricted (contact Wolfram for access)
- Image URLs are included in Markdown format
- Mathematical notation uses proper LaTeX-style formatting
- The API has daily request limits based on your plan