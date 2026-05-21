---
name: wanikani
description: Query WaniKani Japanese learning data — profile, kanji/vocab lookup, review forecast, SRS progress, and study statistics. Use when Carlos asks about his WaniKani progress, wants to look up a kanji or vocabulary word, check upcoming reviews, or see his study stats.
metadata:
  openclaw:
    emoji: 🈴
    requires:
      bins:
        - bash
        - curl
        - jq
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

Run from the skill directory:

```bash
scripts/wanikani.sh <command> [args]
```

### Profile

```bash
scripts/wanikani.sh user
# 📊 WaniKani Profile — CarlosSaucedo
# Level: 2
# Member since: 2025-09-15
# Plan: free (max level 3)
```

### Review Forecast

```bash
scripts/wanikani.sh summary
# 📝 Review Forecast
# Next review batch: 84 items
# Available at: May 21, 11:00 AM
# Lessons available: 40
```

### Subject Lookup (kanji, vocabulary, radicals)

```bash
scripts/wanikani.sh subjects 水
# 水 [kanji] Water
#   Readings: すい★, みず
#   Level 2

scripts/wanikani.sh subjects --level 3
# Lists all subjects at that level

scripts/wanikani.sh subjects river
# 川 [radical] River
#   Level 1
```

### SRS Stage Distribution

```bash
scripts/wanikani.sh assignments
# Stage 0: 40 items (locked)
# Stage 1: 15 items (apprentice)
# Stage 5: 5 items (guru)

scripts/wanikani.sh assignments apprentice
# Lists items in apprentice SRS stages
```

### Review History

```bash
scripts/wanikani.sh reviews 5
# Review #12345: Subject 8762 — ✅ SRS 5→6 (2026-05-20)
```

### Accuracy Statistics

```bash
scripts/wanikani.sh review-stats
# 📈 Review Statistics
# Items with stats: 84
# Average accuracy: 87%
# ⚠️ Subject 445: 64% accuracy (10 mistakes)
```

### Level Progression

```bash
scripts/wanikani.sh levels
# Level 1: 2025-09-15 → 2026-02-08 → not completed
# Level 2: 2026-02-08 → not passed → not completed
```

### Leeches (struggling subjects)

```bash
scripts/wanikani.sh leeches
# 🐛 Subject 468: 25% — 6 mistakes total
```

## Integration Tips

- Use `wanikani.sh user` for quick check-ins ("how's my Japanese going?")
- Use `wanikani.sh subjects <kanji>` when Carlos encounters an unfamiliar character
- Use `wanikani.sh summary` as part of a daily briefing
- Use `wanikani.sh leeches` to identify problem areas

## Error Handling

- **No token**: Ensure `WANIKANI_ACCESS_TOKEN` is set
- **401**: Token may be expired — regenerate at WaniKani settings
- **Empty results**: Subject may not exist or may require a different spelling
- **Rate limiting**: 60 requests/min — all commands are conservative
