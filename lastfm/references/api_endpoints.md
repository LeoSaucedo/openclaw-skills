# Last.fm API Endpoints Reference

Base URL: `https://ws.audioscrobbler.com/2.0/`

All requests require `api_key` parameter and `format=json`.

## User Endpoints

### user.getInfo
Profile information for a user.
- **Params**: `user` (required)
- **Returns**: playcount, country, registered date, realname, subscriber status, avatar images

### user.getRecentTracks
Recent scrobbles with nowplaying flag.
- **Params**: `user` (required), `limit` (default 50, max 1000), `page`, `from` (unix ts), `to` (unix ts), `extended` (0|1)
- **extended=1** adds: artist MBID, album MBID, if user loved the track

### user.getTopArtists
Top artists by playcount.
- **Params**: `user` (required), `period` (overall|7day|1month|3month|6month|12month), `limit`, `page`

### user.getTopTracks
Top tracks by playcount.
- **Params**: `user` (required), `period`, `limit`, `page`

### user.getTopAlbums
Top albums by playcount.
- **Params**: `user` (required), `period`, `limit`, `page`

### user.getLovedTracks
Tracks the user has loved.
- **Params**: `user` (required), `limit` (max 1000), `page`

### user.getFriends
User's friends.
- **Params**: `user` (required), `limit`, `page`, `recenttracks` (bool)

### user.getWeeklyChartList
Available weekly chart dates.
- **Params**: `user` (required)

## Track Endpoints

### track.getInfo
Metadata for a track.
- **Params**: `artist` (required*), `track` (required*), `mbid`, `autocorrect` (0|1), `username`
- * Required unless using MBID
- **Returns**: duration, playcount, listeners, tags, album, userplaycount (if username provided), userloved

### track.getSimilar
Similar tracks.
- **Params**: `artist`, `track`, `mbid`, `autocorrect`, `limit`

### track.search
Search for a track.
- **Params**: `track` (required), `limit`, `page`

## Artist Endpoints

### artist.getInfo
Artist metadata and bio.
- **Params**: `artist` (required*), `mbid`, `lang`, `autocorrect`
- **Returns**: playcount, listeners, tags, bio summary, similar artists

### artist.getSimilar
Similar artists.
- **Params**: `artist`, `mbid`, `autocorrect`, `limit`

### artist.search
Search for an artist.
- **Params**: `artist` (required), `limit`, `page`

### artist.getTopTracks
Top tracks for an artist.
- **Params**: `artist` (required), `mbid`, `autocorrect`, `limit`

### artist.getTopAlbums
Top albums for an artist.
- **Params**: `artist` (required), `mbid`, `autocorrect`, `limit`

## Album Endpoints

### album.getInfo
Album metadata with tracklist.
- **Params**: `artist` (required*), `album` (required*), `mbid`, `autocorrect`, `username`
- **Returns**: playcount, listeners, release date, tracklist, tags, images

### album.search
Search for an album.
- **Params**: `album` (required), `limit`, `page`

## Tasteometer

### tasteometer.compare
Compare music taste between two users.
- **Params**: `type1` (user|artist), `value1`, `type2` (user|artist), `value2`
- **Returns**: score (0-1), shared artists

## Library Endpoints

### library.getArtists
Artists in a user's library.
- **Params**: `user` (required), `limit`, `page`

## Geo Endpoints

### geo.getTopArtists
Top artists by country.
- **Params**: `country` (required), `limit`, `page`

### geo.getTopTracks
Top tracks by country.
- **Params**: `country` (required), `limit`, `page`

## Error Codes

| Code | Message | Description |
|------|---------|-------------|
| 2 | Invalid service | Service does not exist |
| 3 | Invalid Method | No method with that name |
| 4 | Authentication Failed | Bad credentials |
| 5 | Invalid format | Format not supported |
| 6 | Invalid parameters | Missing or wrong params |
| 7 | Invalid resource | Resource not found |
| 8 | Operation failed | Something went wrong |
| 9 | Invalid session key | Re-authenticate |
| 10 | Invalid API key | Get a valid key |
| 11 | Service Offline | Try again later |
| 13 | Invalid method signature | Bad signature |
| 16 | Temporary error | Try again |
| 17 | Login required | Profile may be private |
| 26 | Suspended API key | Account suspended |
| 29 | Rate limit exceeded | Too many requests |

Full docs: <https://www.last.fm/api>
