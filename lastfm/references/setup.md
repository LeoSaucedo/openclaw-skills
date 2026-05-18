# Last.fm Skill Setup

## One-Time Setup

### 1. Get a Last.fm API Key

1. Go to <https://www.last.fm/api/account/create>
2. Create an API account (free, just need a Last.fm account)
3. Copy your API key

### 2. Set the Environment Variable

**In OpenClaw config:**
```bash
openclaw config set env.LASTFM_API_KEY "your_api_key"
```

**Or in shell profile:**
```bash
echo 'export LASTFM_API_KEY="your_api_key"' >> ~/.bashrc
source ~/.bashrc
```

### 3. Verify It Works

```bash
cd ~/.openclaw/workspace/skills/lastfm
./scripts/lastfm.sh profile USERNAME
```

If you see profile data — it's working.

## Quick Test

```bash
# Test with a known public user
./scripts/lastfm.sh np RJ
./scripts/lastfm.sh quick RJ
./scripts/lastfm.sh top-artists RJ 7day 5
./scripts/lastfm.sh loved RJ 5
```

## API Key Security

- Treat your API key like a password
- It's a read-only key (no scrobbling ability), but don't share it publicly
- Stored in env var to avoid hardcoding
