#!/usr/bin/env bash
set -euo pipefail

# Last.fm API Bash Client
# Usage: ./lastfm.sh <method> [args...]
#
# Methods:
#   nowplaying <user>              - Get currently playing track
#   recent <user> [limit]         - Get recent tracks (default: 10)
#   profile <user>                 - Get user profile info
#   top-artists <user> [period] [limit]  - Top artists (period: overall|7day|1month|3month|6month|12month)
#   top-tracks <user> [period] [limit]   - Top tracks
#   top-albums <user> [period] [limit]   - Top albums
#   loved <user> [limit]          - Loved tracks
#   track <artist> <track> [user] - Track info (optional username for personal playcount)
#   artist <artist>               - Artist info
#   album <artist> <album>        - Album info
#   compare <user1> <user2>       - Compare two users' compatibility
#   recent-artists <user> [limit] - Recent unique artists from recent tracks

API_KEY="${LASTFM_API_KEY:-}"
API_BASE="https://ws.audioscrobbler.com/2.0"

if [[ -z "$API_KEY" ]]; then
  echo "LASTFM_API_KEY environment variable not set!" >&2
  echo "   Get one at: https://www.last.fm/api/account/create" >&2
  exit 1
fi

# Generic API call
api_call() {
  local method="$1"
  shift

  curl -s -G --data-urlencode "method=${method}" \
    --data-urlencode "api_key=${API_KEY}" \
    --data-urlencode "format=json" \
    "$@" \
    "$API_BASE" 2>/dev/null
}

case "${1:-help}" in
  nowplaying|np)
    user="$2"
    echo "Now Playing - $user"
    echo "---"
    resp=$(api_call "user.getRecentTracks" --data-urlencode "user=${user}" --data-urlencode "limit=1" --data-urlencode "extended=1")
    nowplaying=$(echo "$resp" | python3 -c "
import sys, json
data = json.load(sys.stdin)
tracks = data.get('recenttracks', {}).get('track', [])
if tracks and '@attr' in tracks[0] and tracks[0]['@attr'].get('nowplaying') == 'true':
    t = tracks[0]
    artist = t.get('artist', {}).get('name', 'Unknown')
    album = t.get('album', {}).get('#text', '')
    name = t.get('name', 'Unknown')
    mbid = t.get('mbid', '')
    print(f'{artist} - {name}')
    if album:
        print(f'   Album: {album}')
    if mbid:
        print(f'   MBID: {mbid}')
else:
    print('NOT_PLAYING')
" 2>/dev/null || echo "ERROR")

    if [[ "$nowplaying" == "NOT_PLAYING" ]]; then
      echo "   Not currently scrobbling anything."
      echo ""
      echo "Last scrobble:"
      last=$(echo "$resp" | python3 -c "
import sys, json
data = json.load(sys.stdin)
tracks = data.get('recenttracks', {}).get('track', [])
if tracks:
    t = tracks[0]
    artist = t.get('artist', {}).get('name', 'Unknown')
    name = t.get('name', 'Unknown')
    print(f'   {artist} - {name}')
" 2>/dev/null)
      echo "$last"
    fi
    ;;

  recent|recent-tracks)
    user="$2"
    limit="${3:-10}"
    echo "Recent Scrobbles - $user (last $limit)"
    echo "---"
    resp=$(api_call "user.getRecentTracks" --data-urlencode "user=${user}" --data-urlencode "limit=${limit}" --data-urlencode "extended=1")
    echo "$resp" | python3 -c "
import sys, json
data = json.load(sys.stdin)
tracks = data.get('recenttracks', {}).get('track', [])
for i, t in enumerate(tracks):
    is_now = '@attr' in t and t['@attr'].get('nowplaying') == 'true'
    indicator = 'NOW' if is_now else '   '
    artist = t.get('artist', {}).get('name', 'Unknown')
    album = t.get('album', {}).get('#text', '') or ''
    name = t.get('name', 'Unknown')
    date_str = ''
    if 'date' in t:
        date_str = t['date'].get('#text', '')
    album_str = f' [{album}]' if album else ''
    print(f'{indicator} {artist} - {name}{album_str}')
    if date_str:
        print(f'      {date_str}')
" 2>/dev/null || echo "Could not parse response. Check username."
    ;;

  profile|user)
    user="$2"
    echo "Last.fm Profile - $user"
    echo "---"
    resp=$(api_call "user.getInfo" --data-urlencode "user=${user}")
    echo "$resp" | python3 -c "
import sys, json
data = json.load(sys.stdin)
u = data.get('user', {})
name = u.get('name', 'Unknown')
playcount = u.get('playcount', '0')
country = u.get('country', '')
realname = u.get('realname', '')
registered = u.get('registered', {}).get('#text', '')
url = u.get('url', '')
subscriber = u.get('subscriber', '0')
print(f'  Name:       {realname or name}')
print(f'  Username:   {name}')
if country:
    print(f'  Country:    {country}')
print(f'  Scrobbles:  {playcount}')
print(f'  Registered: {registered}')
sub_flag = 'Yes' if subscriber == '1' else 'No'
print(f'  Subscriber: {sub_flag}')
print(f'  URL:        {url}')
" 2>/dev/null || echo "Could not parse response. Check username."
    ;;

  top-artists)
    user="$2"
    period="${3:-overall}"
    limit="${4:-10}"
    period_label=""
    case "$period" in
      overall) period_label="All Time" ;;
      7day)    period_label="Last 7 Days" ;;
      1month)  period_label="Last Month" ;;
      3month)  period_label="Last 3 Months" ;;
      6month)  period_label="Last 6 Months" ;;
      12month) period_label="Last Year" ;;
      *)       period_label="$period" ;;
    esac
    echo "Top Artists ($period_label) - $user"
    echo "---"
    resp=$(api_call "user.getTopArtists" --data-urlencode "user=${user}" --data-urlencode "period=${period}" --data-urlencode "limit=${limit}")
    echo "$resp" | python3 -c "
import sys, json
data = json.load(sys.stdin)
artists = data.get('topartists', {}).get('artist', [])
for i, a in enumerate(artists):
    rank = a.get('@attr', {}).get('rank', i+1)
    name = a.get('name', 'Unknown')
    plays = a.get('playcount', '0')
    print(f'  {rank}. {name} - {plays} plays')
" 2>/dev/null || echo "No data found."
    ;;

  top-tracks)
    user="$2"
    period="${3:-overall}"
    limit="${4:-10}"
    period_label=""
    case "$period" in
      overall) period_label="All Time" ;;
      7day)    period_label="Last 7 Days" ;;
      1month)  period_label="Last Month" ;;
      3month)  period_label="Last 3 Months" ;;
      6month)  period_label="Last 6 Months" ;;
      12month) period_label="Last Year" ;;
      *)       period_label="$period" ;;
    esac
    echo "Top Tracks ($period_label) - $user"
    echo "---"
    resp=$(api_call "user.getTopTracks" --data-urlencode "user=${user}" --data-urlencode "period=${period}" --data-urlencode "limit=${limit}")
    echo "$resp" | python3 -c "
import sys, json
data = json.load(sys.stdin)
tracks = data.get('toptracks', {}).get('track', [])
for i, t in enumerate(tracks):
    rank = t.get('@attr', {}).get('rank', i+1)
    name = t.get('name', 'Unknown')
    artist = t.get('artist', {}).get('name', 'Unknown')
    plays = t.get('playcount', '0')
    print(f'  {rank}. {artist} - {name} ({plays} plays)')
" 2>/dev/null || echo "No data found."
    ;;

  top-albums)
    user="$2"
    period="${3:-overall}"
    limit="${4:-10}"
    period_label=""
    case "$period" in
      overall) period_label="All Time" ;;
      7day)    period_label="Last 7 Days" ;;
      1month)  period_label="Last Month" ;;
      3month)  period_label="Last 3 Months" ;;
      6month)  period_label="Last 6 Months" ;;
      12month) period_label="Last Year" ;;
      *)       period_label="$period" ;;
    esac
    echo "Top Albums ($period_label) - $user"
    echo "---"
    resp=$(api_call "user.getTopAlbums" --data-urlencode "user=${user}" --data-urlencode "period=${period}" --data-urlencode "limit=${limit}")
    echo "$resp" | python3 -c "
import sys, json
data = json.load(sys.stdin)
albums = data.get('topalbums', {}).get('album', [])
for i, a in enumerate(albums):
    rank = a.get('@attr', {}).get('rank', i+1)
    name = a.get('name', 'Unknown')
    artist = a.get('artist', {}).get('name', 'Unknown')
    plays = a.get('playcount', '0')
    print(f'  {rank}. {artist} - {name} ({plays} plays)')
" 2>/dev/null || echo "No data found."
    ;;

  loved|loved-tracks)
    user="$2"
    limit="${3:-10}"
    echo "Loved Tracks - $user"
    echo "---"
    resp=$(api_call "user.getLovedTracks" --data-urlencode "user=${user}" --data-urlencode "limit=${limit}")
    echo "$resp" | python3 -c "
import sys, json
data = json.load(sys.stdin)
tracks = data.get('lovedtracks', {}).get('track', [])
for i, t in enumerate(tracks):
    name = t.get('name', 'Unknown')
    artist = t.get('artist', {}).get('name', 'Unknown')
    date = t.get('date', {}).get('#text', '')
    print(f'  {i+1}. {artist} - {name}')
    if date:
        print(f'      Loved: {date}')
" 2>/dev/null || echo "No loved tracks found."
    ;;

  track|track-info)
    artist="$2"
    track_name="$3"
    user="${4:-}"
    echo "Track Info"
    echo "---"
    params=()
    params+=(--data-urlencode "artist=${artist}")
    params+=(--data-urlencode "track=${track_name}")
    params+=(--data-urlencode "autocorrect=1")
    if [[ -n "$user" ]]; then
      params+=(--data-urlencode "username=${user}")
    fi
    resp=$(api_call "track.getInfo" "${params[@]}")
    echo "$resp" | python3 -c "
import sys, json
data = json.load(sys.stdin)
t = data.get('track', {})
name = t.get('name', 'Unknown')
artist = t.get('artist', {}).get('name', 'Unknown')
album = t.get('album', {}).get('title', '') or ''
duration = t.get('duration', '0')
plays = t.get('playcount', '0')
listeners = t.get('listeners', '0')
url = t.get('url', '')
tags = t.get('toptags', {}).get('tag', [])
userplay = t.get('userplaycount', '')
loved = t.get('userloved', '')

mins = int(duration) // 60 if duration and duration.isdigit() else 0
secs = int(duration) % 60 if duration and duration.isdigit() else 0
duration_str = f'{mins}:{secs:02d}' if mins > 0 else 'Unknown'

print(f'  {artist} - {name}')
if album:
    print(f'  Album:  {album}')
print(f'  Duration: {duration_str}')
print(f'  Plays:   {plays}  |  Listeners: {listeners}')
if userplay:
    print(f'  Your plays: {userplay}')
if loved == '1':
    print(f'  You love this track!')
tag_list = [t.get('name', '') for t in tags[:5]]
if tag_list:
    print(f'  Tags:    {\", \".join(tag_list)}')
print(f'  {url}')
" 2>/dev/null || echo "Track not found."
    ;;

  artist|artist-info)
    artist="$2"
    echo "Artist Info"
    echo "---"
    resp=$(api_call "artist.getInfo" --data-urlencode "artist=${artist}" --data-urlencode "autocorrect=1" --data-urlencode "lang=en")
    echo "$resp" | python3 -c "
import sys, json
data = json.load(sys.stdin)
a = data.get('artist', {})
name = a.get('name', 'Unknown')
plays = a.get('stats', {}).get('playcount', '0')
listeners = a.get('stats', {}).get('listeners', '0')
url = a.get('url', '')
tags = a.get('tags', {}).get('tag', [])
print(f'  {name}')
print(f'  Plays:     {plays}')
print(f'  Listeners: {listeners}')
tag_list = [t.get('name', '') for t in tags[:8]]
if tag_list:
    print(f'  Tags:      {\", \".join(tag_list)}')
print(f'  {url}')
" 2>/dev/null || echo "Artist not found."
    ;;

  album|album-info)
    artist="$2"
    album_name="$3"
    echo "Album Info"
    echo "---"
    resp=$(api_call "album.getInfo" --data-urlencode "artist=${artist}" --data-urlencode "album=${album_name}" --data-urlencode "autocorrect=1")
    echo "$resp" | python3 -c "
import sys, json
data = json.load(sys.stdin)
a = data.get('album', {})
name = a.get('name', 'Unknown')
artist = a.get('artist', 'Unknown')
plays = a.get('playcount', '0')
listeners = a.get('listeners', '0')
url = a.get('url', '')
tracks = a.get('tracks', {}).get('track', []) if isinstance(a.get('tracks'), dict) else a.get('tracks', [])
tags = a.get('tags', {}).get('tag', [])

print(f'  {artist} - {name}')
print(f'  Plays:     {plays}')
print(f'  Listeners: {listeners}')
if tracks:
    print(f'  Tracks:')
    for i, t in enumerate(tracks, 1):
        if isinstance(t, dict):
            track_name = t.get('name', 'Unknown')
            dur = t.get('duration', '0')
            if dur.isdigit() and int(dur) > 0:
                m = int(dur) // 60
                s = int(dur) % 60
                print(f'    {i:2d}. {track_name} ({m}:{s:02d})')
            else:
                print(f'    {i:2d}. {track_name}')
tag_list = [t.get('name', '') for t in tags[:5]]
if tag_list:
    print(f'  Tags:      {\", \".join(tag_list)}')
print(f'  {url}')
" 2>/dev/null || echo "Album not found."
    ;;

  compare|compatibility)
    user1="$2"
    user2="$3"
    echo "Compatibility - $user1 vs $user2"
    echo "---"
    resp=$(api_call "tasteometer.compare" --data-urlencode "type1=user" --data-urlencode "value1=${user1}" --data-urlencode "type2=user" --data-urlencode "value2=${user2}")
    echo "$resp" | python3 -c "
import sys, json
data = json.load(sys.stdin)
result = data.get('comparison', {}).get('result', {})
score = result.get('score', '0')
artists = result.get('artists', {}).get('artist', [])
score_pct = float(score) * 100 if score else 0
print(f'  Compatibility: {score_pct:.1f}%')
if artists:
    print(f'  Shared artists:')
    for a in artists:
        print(f'    - {a.get(\"name\", \"Unknown\")}')
" 2>/dev/null || echo "Could not compare users."
    ;;

  recent-artists)
    user="$2"
    limit="${3:-10}"
    echo "Recent Artists - $user"
    echo "---"
    resp=$(api_call "user.getRecentTracks" --data-urlencode "user=${user}" --data-urlencode "limit=200" --data-urlencode "extended=1")
    echo "$resp" | python3 -c "
import sys, json
from collections import Counter
data = json.load(sys.stdin)
tracks = data.get('recenttracks', {}).get('track', [])
artists = []
for t in tracks:
    artists.append(t.get('artist', {}).get('name', 'Unknown'))
counts = Counter(artists)
for i, (artist, count) in enumerate(counts.most_common($limit), 1):
    print(f'  {i}. {artist} - {count} plays')
" 2>/dev/null || echo "Could not parse."
    ;;

  search|search-artist|search-track)
    search_type="${2:-artist}"
    query="$3"
    echo "Searching $search_type: $query"
    echo "---"
    if [[ "$search_type" == "artist" ]]; then
      method="artist.search"
    else
      method="track.search"
    fi
    resp=$(api_call "$method" --data-urlencode "${search_type}=${query}" --data-urlencode "limit=10")
    echo "$resp" | python3 -c "
import sys, json
data = json.load(sys.stdin)

if '$search_type' == 'artist':
    results = data.get('results', {}).get('artistmatches', {}).get('artist', [])
else:
    results = data.get('results', {}).get('trackmatches', {}).get('track', [])

if not results:
    print('No results found.')
    sys.exit(0)

for i, r in enumerate(results[:10], 1):
    name = r.get('name', 'Unknown')
    listeners = r.get('listeners', '')
    if '$search_type' == 'track':
        artist = r.get('artist', '')
        print(f'  {i}. {artist} - {name}')
    else:
        print(f'  {i}. {name} (listeners: {listeners})')
" 2>/dev/null || echo "No results found."
    ;;

  help|--help|-h)
    echo "Last.fm API Client"
    echo ""
    echo "Usage: ./lastfm.sh <command> [args...]"
    echo ""
    echo "User Commands:"
    echo "  np|nowplaying    <user>              Currently playing track"
    echo "  recent           <user> [limit]       Recent scrobbles (default: 10)"
    echo "  profile|user     <user>              Profile info & stats"
    echo "  top-artists      <user> [period] [n]  Top artists"
    echo "  top-tracks       <user> [period] [n]  Top tracks"
    echo "  top-albums       <user> [period] [n]  Top albums"
    echo "  loved             <user> [limit]       Loved tracks"
    echo "  recent-artists   <user> [n]           Recently played artists"
    echo "  compare          <user1> <user2>       Taste compatibility"
    echo ""
    echo "Discovery:"
    echo "  track            <artist> <track> [user]  Track info"
    echo "  artist           <artist>                 Artist info"
    echo "  album            <artist> <album>         Album info"
    echo "  search           artist|track <query>     Search"
    echo ""
    echo "Quick Stats:"
    echo "  ./lastfm.sh quick <user>              Compact overview"
    ;;

  stats|quick)
    user="$2"
    echo "Quick Stats - $user"
    echo "==="
    # Profile
    resp=$(api_call "user.getInfo" --data-urlencode "user=${user}")
    echo "$resp" | python3 -c "
import sys, json
data = json.load(sys.stdin)
u = data.get('user', {})
sc = u.get('playcount', '?')
cty = u.get('country', '?') or '?'
print(f'  Scrobbles: {sc}  |  Country: {cty}')
" 2>/dev/null || true

    # Now playing
    resp2=$(api_call "user.getRecentTracks" --data-urlencode "user=${user}" --data-urlencode "limit=1" --data-urlencode "extended=1")
    echo "$resp2" | python3 -c "
import sys, json
data = json.load(sys.stdin)
tracks = data.get('recenttracks', {}).get('track', [])
if tracks:
    t = tracks[0]
    is_now = '@attr' in t and t['@attr'].get('nowplaying') == 'true'
    artist = t.get('artist', {}).get('name', 'Unknown')
    name = t.get('name', 'Unknown')
    if is_now:
        print(f'  Now:  {artist} - {name}')
    else:
        print(f'  Last: {artist} - {name}')
" 2>/dev/null || true

    # Top artists this week
    echo ""
    echo "  Top Artists (7-day):"
    resp3=$(api_call "user.getTopArtists" --data-urlencode "user=${user}" --data-urlencode "period=7day" --data-urlencode "limit=5")
    echo "$resp3" | python3 -c "
import sys, json
data = json.load(sys.stdin)
artists = data.get('topartists', {}).get('artist', [])
for i, a in enumerate(artists[:5], 1):
    name = a.get('name', 'Unknown')
    plays = a.get('playcount', '0')
    print(f'    {i}. {name} - {plays}')
" 2>/dev/null || true

    echo ""
    echo "  Top Tracks (7-day):"
    resp4=$(api_call "user.getTopTracks" --data-urlencode "user=${user}" --data-urlencode "period=7day" --data-urlencode "limit=5")
    echo "$resp4" | python3 -c "
import sys, json
data = json.load(sys.stdin)
tracks = data.get('toptracks', {}).get('track', [])
for i, t in enumerate(tracks[:5], 1):
    name = t.get('name', 'Unknown')
    artist = t.get('artist', {}).get('name', 'Unknown')
    plays = t.get('playcount', '0')
    print(f'    {i}. {artist} - {name} ({plays})')
" 2>/dev/null || true
    ;;

  json|raw)
    # Pass through any method and return raw JSON
    method="${2:-user.getInfo}"
    shift 2
    api_call "$method" "$@"
    ;;

  *)
    echo "Usage: ./lastfm.sh <command> [args...]"
    echo "Run './lastfm.sh help' for full command list."
    exit 1
    ;;
esac
