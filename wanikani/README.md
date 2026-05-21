# wanikani

WaniKani Japanese study data via the v2 API — profile, kanji/vocab lookup, review forecast, SRS progress, and study statistics.

## Quick Start

```bash
# Set your API token
export WANIKANI_ACCESS_TOKEN="your-token-here"

# Check your profile
python3 scripts/wanikani.py user

# Look up a kanji
python3 scripts/wanikani.py subjects 水

# See upcoming reviews
python3 scripts/wanikani.py summary

# Find problem areas
python3 scripts/wanikani.py leeches
```

## Requirements

- Python 3
- `WANIKANI_ACCESS_TOKEN` environment variable

## Commands

| Command | Description |
|---|---|
| `user` | Profile info |
| `summary` | Review forecast |
| `subjects <char|keyword>` | Look up kanji/vocab/radical |
| `subjects --level <N>` | List subjects at a level |
| `assignments` | SRS stage distribution |
| `assignments <stage>` | Filter by SRS stage |
| `reviews [limit]` | Recent reviews |
| `review-stats` | Accuracy stats |
| `levels` | Level progression |
| `leeches` | Struggling subjects |
