---
name: wanikani
description: Query WaniKani Japanese learning data — profile, kanji/vocab lookup, review forecast, SRS progress, and study statistics. Use when Carlos asks about his WaniKani progress, wants to look up a kanji or vocabulary word, check upcoming reviews, or see his study stats.
metadata:
  openclaw:
    emoji: 🈴
    requires:
      bins:
        - python3
      env:
        - WANIKANI_ACCESS_TOKEN
    primaryEnv: WANIKANI_ACCESS_TOKEN
    homepage: https://docs.api.wanikani.com
---

# WaniKani Skill

Access your WaniKani Japanese learning data through the WaniKani v2 API.

## Setup

The `WANIKANI_ACCESS_TOKEN` must be set in your environment. Get yours at:
https://www.wanikani.com/settings/personal_access_tokens

## Commands

```bash
python3 scripts/wanikani.py <command> [args]
```

| Command | What it does |
|---|---|
| `user` | Profile info (level, username, plan) |
| `summary` | Today's review forecast + lessons available |
| `subjects <char\|slug>` | Look up a kanji, vocab, or radical |
| `subjects --level <N>` | List all subjects at a level |
| `assignments` | SRS stage distribution |
| `assignments <stage>` | Items in a specific SRS stage |
| `reviews [limit]` | Recent review history |
| `review-stats` | Accuracy statistics |
| `levels` | Level progression timeline |
| `leeches` | Subjects below 70% accuracy |

## Examples

```bash
# Quick profile check
python3 scripts/wanikani.py user

# Kanji lookup
python3 scripts/wanikani.py subjects 水

# Review forecast
python3 scripts/wanikani.py summary

# Problem areas
python3 scripts/wanikani.py leeches
```

## Error Handling

- **No token**: Ensure `WANIKANI_ACCESS_TOKEN` is set in your environment or `~/.openclaw/.env`
- **401**: Token expired — regenerate at WaniKani Settings
- **Rate limiting**: 60 requests per minute
