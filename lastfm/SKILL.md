---
name: lastfm
description: Interact with the Last.fm API for scrobble stats, music profiles, top charts, and discovery. Use when the user asks about their Last.fm stats, what someone is listening to, top artists/tracks/albums, now playing status, profile info, loved tracks, artist/track/album details, search Last.fm, or compare music taste with another user. Requires LASTFM_API_KEY environment variable.
metadata:
  author: github.com/LeoSaucedo
---

# Last.fm API Skill

## Quick Start

### Setup

1. **Get an API key** at <https://www.last.fm/api/account/create>
2. **Set the environment variable**:
   ```bash
   export LASTFM_API_KEY="your_api_key_here"
   ```
   Or add it to OpenClaw's environment config.

### One-Query Commands

All commands go through the CLI script:

```bash
cd ~/.openclaw/workspace/skills/lastfm
./scripts/lastfm.sh <command> <args...>
```

For quick responses the AI should inline curl calls directly (see API Reference below) — use the CLI for complex multi-call flows or when user wants formatted output.

## Common User Queries

### "What's [user] listening to right now?"

```bash
./scripts/lastfm.sh np USERNAME
# Shows ▶️ Now: Artist — Song
```

### "Show me [user]'s stats"

```bash
./scripts/lastfm.sh quick USERNAME
# Compact overview: scrobbles, now playing, top 5 artists and tracks this week
```

### "Top artists this month"

```bash
./scripts/lastfm.sh top-artists USERNAME 1month 15
```

### "Profile info"

```bash
./scripts/lastfm.sh profile USERNAME
```

### "Recent scrobbles"

```bash
./scripts/lastfm.sh recent USERNAME 5
```

## Script Reference

| Command | Args | Description |
|---|---|---|
| `np\|nowplaying` | `<user>` | Currently playing track (or last scrobble) |
| `recent` | `<user> [limit]` | Recent scrobbles (default 10, max 200) |
| `profile\|user` | `<user>` | Profile info: scrobbles, country, registered date |
| `top-artists` | `<user> [period] [n]` | Top artists by period (default: overall, 10) |
| `top-tracks` | `<user> [period] [n]` | Top tracks by period |
| `top-albums` | `<user> [period] [n]` | Top albums by period |
| `loved` | `<user> [limit]` | Loved tracks |
| `recent-artists` | `<user> [n]` | Unique artists from recent 200 scrobbles |
| `compare` | `<user1> <user2>` | Taste compatibility score + shared artists |
| `track` | `<artist> <track> [user]` | Track metadata (optional username for personal playcount) |
| `artist` | `<artist>` | Artist info, tags, stats |
| `album` | `<artist> <album>` | Album info with tracklist |
| `search` | `artist\|track <query>` | Search Last.fm |
| `stats\|quick` | `<user>` | Compact overview: scrobbles + now playing + weekly top 5 |
| `json\|raw` | `<method> [params]` | Raw JSON response for any API method |

### Period Values

- `overall` – All time
- `7day` – Last 7 days
- `1month` – Last month
- `3month` – Last 3 months
- `6month` – Last 6 months
- `12month` – Last year

## API Reference (Inline Curl)

For fastest responses, use curl directly when the user asks a single question:

```bash
# Now playing (check @attr.nowplaying)
curl -s "https://ws.audioscrobbler.com/2.0/?method=user.getRecentTracks&user=USER&api_key=${LASTFM_API_KEY}&format=json&limit=1&extended=1"

# Profile
curl -s "https://ws.audioscrobbler.com/2.0/?method=user.getInfo&user=USER&api_key=${LASTFM_API_KEY}&format=json"

# Top artists (period: overall|7day|1month|3month|6month|12month)
curl -s "https://ws.audioscrobbler.com/2.0/?method=user.getTopArtists&user=USER&api_key=${LASTFM_API_KEY}&format=json&period=7day&limit=10"

# Top tracks
curl -s "https://ws.audioscrobbler.com/2.0/?method=user.getTopTracks&user=USER&api_key=${LASTFM_API_KEY}&format=json&period=7day&limit=10"

# Track info
curl -s "https://ws.audioscrobbler.com/2.0/?method=track.getInfo&artist=ARTIST&track=TRACK&api_key=${LASTFM_API_KEY}&format=json&autocorrect=1"

# Artist info
curl -s "https://ws.audioscrobbler.com/2.0/?method=artist.getInfo&artist=ARTIST&api_key=${LASTFM_API_KEY}&format=json"

# Loved tracks
curl -s "https://ws.audioscrobbler.com/2.0/?method=user.getLovedTracks&user=USER&api_key=${LASTFM_API_KEY}&format=json&limit=20"

# Compatibility
curl -s "https://ws.audioscrobbler.com/2.0/?method=tasteometer.compare&type1=user&value1=USER1&type2=user&value2=USER2&api_key=${LASTFM_API_KEY}&format=json"
```

## Example Quick Responses

### "What's playing"

Extract from `user.getRecentTracks` — check if first track has `@attr.nowplaying == "true"`:

```
🎵 Now Playing — USERNAME
► Artist — Song Title
   Album: Album Name
```

### "Stats overview"

Combine `user.getInfo` + `user.getTopArtists(7day, 5)`:

```
📊 USERNAME — 85,432 scrobbles
▶️ Now: Artist — Song
── 7-Day Artists ──
1. Top Artist — 42
2. Second Artist — 38
3. Third Artist — 31
```

## Default Username

When the user doesn't specify a username, check the `$LASTFM_USER` environment variable (if set).

## Error Handling

- **Missing API key**: Tell user to get one at <https://www.last.fm/api/account/create> and set `LASTFM_API_KEY`
- **Invalid user (6)**: User not found or profile is private
- **Rate limited (29)**: Wait and retry
- **Parsing failures**: Response format varies slightly; fall back to raw JSON extraction with python3 or jq
