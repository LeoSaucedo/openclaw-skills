# Email Triage — Installation & Schema

First-time setup for the email triage skill.

## Folder Structure

```
email-triage/
├── SKILL.md              # The skill definition (lives in skills/email-triage/ but works from workspace root)
├── accounts.json         # [REQUIRED] Email accounts to triage (see below)
├── state.json            # [AUTO] Tracks lastRun timestamp + counters
├── seen.json             # [AUTO] Thread deduplication per account, auto-prunes >4h
├── whitelist.json        # [USER-EDITABLE] Senders/domains that ALWAYS stay in inbox
├── blacklist.json        # [USER-EDITABLE] Senders/domains that ALWAYS go to waiting list
├── log.jsonl             # [AUTO] Working log — last 24h. JSONL format.
├── audit.jsonl           # [AUTO] Archive log — last 90 days. JSONL format.
└── learned.db            # [AUTO-CREATED] SQLite DB for pattern learning
```

## Step 1: Create accounts.json

```json
[
  {
    "email": "you@gmail.com",
    "waitingLabel": "Boxbe Waiting List"
  }
]
```

Each account object requires:
- `email`: The Gmail address (must be configured in gog auth)
- `waitingLabel`: The Gmail label name used as the "waiting list" (e.g., "Boxbe Waiting List")

## Step 2: Create seed files

**whitelist.json:**
```json
{
  "_help": "Senders or domains here ALWAYS stay in inbox.",
  "_rules": "Match is case-insensitive. Domain matches everything@domain.com. Full email matches exactly.",
  "senders": [],
  "domains": []
}
```

**blacklist.json:**
```json
{
  "_help": "Senders or domains here ALWAYS go to Waiting List.",
  "_rules": "Match is case-insensitive. Domain matches everything@domain.com. Full email matches exactly.",
  "senders": [],
  "domains": []
}
```

**state.json:**
```json
{
  "_help": "State tracker for email triage cron job",
  "lastRun": null,
  "totalProcessed": 0,
  "totalKeptInInbox": 0,
  "totalSentToWaitingList": 0
}
```

**seen.json** (start empty):
```json
{}
```

## Step 3: Create learned.db

The SQLite DB is auto-created on first triage run. Schema:

```sql
CREATE TABLE patterns (
    keyword TEXT PRIMARY KEY,
    score REAL NOT NULL DEFAULT 0,
    updates INTEGER NOT NULL DEFAULT 0,
    confidence REAL NOT NULL DEFAULT 0.5
);

CREATE TABLE domains (
    domain TEXT PRIMARY KEY,
    score REAL NOT NULL DEFAULT 0,
    updates INTEGER NOT NULL DEFAULT 0,
    confidence REAL NOT NULL DEFAULT 0.5
);

CREATE TABLE essence_types (
    name TEXT PRIMARY KEY,
    score REAL NOT NULL DEFAULT 0,
    updates INTEGER NOT NULL DEFAULT 0,
    confidence REAL NOT NULL DEFAULT 0.5
);

CREATE TABLE metadata (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
```

The DB will be seeded with initial metadata on first triage run:
- `cycle`: "0"
- `decay_rate`: "0.97"

To create the DB manually:
```bash
sqlite3 email-triage/learned.db < email-triage/init.sql
```

## Database Schema Detail

### patterns
Stores learned keyword weights. Each keyword extracted from email subjects gets a score.
- **keyword**: Lowercase word from subject (PRIMARY KEY)
- **score**: Sliding weight — positive = keep signal, negative = waiting signal
- **updates**: How many times this keyword has been scored
- **confidence**: 0-1 confidence of the score (starts at 0.55, maxes at 1.0)

### domains
Stores learned sender domain weights.
- **domain**: Bare domain from sender address e.g. `cotopaxi.com` (PRIMARY KEY)
- **score**: Sliding weight
- **updates**: Count of scoring events
- **confidence**: 0-1 confidence

### essence_types
Stores learned email category weights.
- **name**: Category name e.g. `marketing_promo`, `travel_alert`, `newsletter` (PRIMARY KEY)
- **score**: Sliding weight
- **updates**: Count of scoring events
- **confidence**: 0-1 confidence

### metadata
Key-value store for operational state.
- **cycle**: Number of feedback sweep cycles completed
- **decay_rate**: Multiplier applied to all scores per cycle (default 0.97)

## Log Format (log.jsonl / audit.jsonl)

Each line is a JSON object:
```json
{
  "ts": "2026-06-01T12:42:00-04:00",
  "decision": "WAITING",
  "threadId": "19e83f7cb645a38b",
  "sender": "donotreply@example.com",
  "subject": "Check out our newsletter",
  "account": "you@gmail.com",
  "reason": "newsletter, AI eval WAITING"
}
```

Fields:
- **ts**: ISO 8601 timestamp with timezone offset
- **decision**: One of `WHITELIST`, `BLACKLIST`, `KEPT`, `WAITING`
- **threadId**: Gmail thread ID
- **sender**: From address
- **subject**: Email subject line
- **account**: Which Gmail account this belongs to
- **reason**: Human-readable classification reason

## Step 4: Set up cron jobs

Two cron jobs needed (configured via `openclaw cron add` or the cron tool):

### Triage (every 45 min)

```json
{
  "name": "Email Triage — AI Inbox Filter",
  "enabled": true,
  "schedule": { "kind": "every", "everyMs": 2700000 },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Execute the email triage skill. Read skills/email-triage/SKILL.md and follow it exactly. The skill will load USER.md and MEMORY.md only when needed (do NOT pre-load them).",
    "timeoutSeconds": 120,
    "lightContext": true,
    "model": "deepseek/deepseek-v4-flash",
    "thinking": "low"
  },
  "delivery": { "mode": "none" }
}
```

### Feedback Sweep (daily, e.g., 3 AM)

```json
{
  "name": "Email Triage — Daily Feedback Sweep",
  "enabled": true,
  "schedule": { "kind": "cron", "expr": "0 3 * * *", "tz": "America/New_York" },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Read skills/email-triage/SKILL.md. Execute ONLY the \"Feedback Sweep (Daily Cron)\" section at the bottom. Do NOT run the main triage workflow. Do NOT load USER.md or MEMORY.md.",
    "timeoutSeconds": 600,
    "lightContext": true,
    "model": "deepseek/deepseek-v4-flash",
    "thinking": "low"
  },
  "delivery": { "mode": "none" }
}
```

> **Note:** Adjust the Feedback Sweep schedule to avoid collisions with other cron jobs (e.g., Memory Dreaming Promotion, Daily Memory Extraction). See your existing cron schedule first.

## Step 5: Verify

Test the pipeline:
```bash
# Accounts load
cat email-triage/accounts.json | python3 -c "import json,sys; print(len(json.load(sys.stdin)))"

# DB exists and has tables
sqlite3 email-triage/learned.db ".tables"

# State is valid JSON
cat email-triage/state.json | python3 -m json.tool > /dev/null

# Gog works for each account
gog email search "is:unread" --max 1 --account you@gmail.com
```
