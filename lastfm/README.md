# Last.fm API Skill

Query Last.fm scrobble data, music charts, user profiles, and compare music tastes — all from the command line.

## Features

- **Now Playing** — See what anyone is listening to right now
- **User Profiles** — Scrobble counts, registered date, country, subscriber status
- **Top Charts** — Artists, tracks, and albums by any period (7 days to all time)
- **Track & Artist Info** — Metadata, play counts, tags, album details
- **Taste Compatibility** — Compare two users and find shared artists
- **Loved Tracks** — Browse a user's loved/favorited tracks
- **Raw JSON Access** — Pass-through for any Last.fm API method

## Prerequisites

- **Bash 4+** with `curl` and `python3`
- A [Last.fm API key](https://www.last.fm/api/account/create) (free, read-only)

## Installation

```bash
# Clone or copy the skill into your workspace
export LASTFM_API_KEY="your_api_key_here"
```

Optionally set a default username:

```bash
export LASTFM_USER="your_lastfm_username"
```

## Configuration

| Variable | Required | Purpose |
|---|---|---|
| `LASTFM_API_KEY` | Yes | API authentication (read-only) |
| `LASTFM_USER` | No | Default username when none specified |

## Usage

All commands go through the unified CLI script:

```bash
./scripts/lastfm.sh <command> [args...]
```

### Real-Time

```bash
# What's playing right now
./scripts/lastfm.sh np USERNAME

# Recent scrobbles
./scripts/lastfm.sh recent USERNAME

# Compact overview (scrobbles + now playing + weekly top 5)
./scripts/lastfm.sh quick USERNAME
```

### Charts & Stats

```bash
# Top artists (period: overall|7day|1month|3month|6month|12month)
./scripts/lastfm.sh top-artists USERNAME 7day 15

# Top tracks
./scripts/lastfm.sh top-tracks USERNAME 1month 20

# Top albums
./scripts/lastfm.sh top-albums USERNAME 3month 10

# Loved/favorited tracks
./scripts/lastfm.sh loved USERNAME

# Recently played unique artists
./scripts/lastfm.sh recent-artists USERNAME
```

### Music Discovery

```bash
# Track metadata with optional personal playcount
./scripts/lastfm.sh track "Radiohead" "Karma Police"
./scripts/lastfm.sh track "Radiohead" "Karma Police" USERNAME

# Artist info with tags and stats
./scripts/lastfm.sh artist "Bon Iver"

# Album info with tracklist
./scripts/lastfm.sh album "Radiohead" "OK Computer"

# Search artists or tracks
./scripts/lastfm.sh search artist "lofi"
./scripts/lastfm.sh search track "dream pop"
```

### Social

```bash
# Compare taste compatibility (returns percentage + shared artists)
./scripts/lastfm.sh compare USER1 USER2
```

### Raw API Access

```bash
# Any Last.fm API method with arbitrary params
./scripts/lastfm.sh json "artist.getInfo" --data-urlencode "artist=Radiohead"
```

## Command Reference

| Command | Arguments | Description |
|---|---|---|
| `np` / `nowplaying` | `<user>` | Currently playing (or last scrobble) |
| `recent` | `<user> [limit]` | Recent scrobbles (default 10, max 200) |
| `profile` / `user` | `<user>` | Full profile info |
| `top-artists` | `<user> [period] [n]` | Top artists (default: overall, 10) |
| `top-tracks` | `<user> [period] [n]` | Top tracks |
| `top-albums` | `<user> [period] [n]` | Top albums |
| `loved` | `<user> [limit]` | Loved tracks |
| `recent-artists` | `<user> [n]` | Unique artists from last 200 scrobbles |
| `track` | `<artist> <track> [user]` | Track metadata |
| `artist` | `<artist>` | Artist info |
| `album` | `<artist> <album>` | Album info with tracklist |
| `search` | `artist\|track <query>` | Search Last.fm |
| `compare` | `<user1> <user2>` | Taste compatibility |
| `quick` | `<user>` | Compact overview |
| `json` / `raw` | `<method> [params]` | Raw API response |

### Period Values

| Value | Period |
|---|---|
| `overall` | All time |
| `7day` | Last 7 days |
| `1month` | Last month |
| `3month` | Last 3 months |
| `6month` | Last 6 months |
| `12month` | Last year |

## API Reference

Full endpoint documentation in `references/api_endpoints.md`. Base URL:

```
https://ws.audioscrobbler.com/2.0/
```

All requests require `api_key` and `format=json` parameters.

## Error Handling

| Error | Meaning | Fix |
|---|---|---|
| Missing API key | `LASTFM_API_KEY` not set | Get a key and set the env var |
| Invalid user (code 6) | User not found or private profile | Check the username |
| Rate limited (code 29) | Too many requests | Wait and retry |
| Parse failure | Unexpected response format | Falls back to raw JSON extraction |

## License

MIT — see `LICENSE` for details.
