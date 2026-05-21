---
name: wanikani
description: Query WaniKani Japanese learning data — profile, kanji/vocab lookup, review forecast, SRS progress, and study statistics. Requires a WaniKani API token.
metadata:
  author: github.com/LeoSaucedo
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

Set `WANIKANI_ACCESS_TOKEN` in your environment. Get yours at:
https://www.wanikani.com/settings/personal_access_tokens

## Commands

```bash
python3 scripts/wanikani.py <command> [args]
```

| Command | What it does |
|---|---|
| `user` | Profile info (level, username, plan) |
| `summary` | Today's review forecast + lessons available |
| `subjects <char\|keyword>` | Look up kanji, vocab, or radical by character or meaning |
| `subjects --level <N>` | List all subjects at a level |
| `assignments` | SRS stage distribution |
| `assignments <stage>` | Items in a specific SRS stage (locked/apprentice/guru/master/enlightened/burned or 0-9) |
| `reviews [limit]` | Recent review history |
| `review-stats` | Accuracy statistics |
| `levels` | Level progression timeline |
| `leeches` | Subjects below 70% accuracy |

## Examples

```bash
python3 scripts/wanikani.py user
python3 scripts/wanikani.py subjects 水
python3 scripts/wanikani.py summary
python3 scripts/wanikani.py leeches
```

## Error Handling

- **No token**: Set `WANIKANI_ACCESS_TOKEN` in your environment or `~/.openclaw/.env`
- **HTTP errors**: Displayed with error code and description
- **Rate limiting**: 60 requests per minute
