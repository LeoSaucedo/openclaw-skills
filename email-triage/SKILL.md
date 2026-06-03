---
name: email-triage
description: Gmail inbox triage with self-learning SQLite pattern database. Multi-account support with whitelist/blacklist, keyword-domain-essence scoring, and daily feedback sweep learning. Use when the user asks to check email, triage inbox, or during automated email triage cron runs.
metadata:
  author: github.com/LeoSaucedo
  openclaw:
    requires:
      bins: ["python3", "sqlite3", "gog"]
---

# Email Triage

AI gatekeeper — important stays in inbox, noise goes to a configurable waiting label. Self-learning from feedback sweeps.

> **First-time setup:** See [INSTALL.md](INSTALL.md) for DB schema, folder structure, seed files, and cron job configuration.
>
> **Repo note:** This file lives at `email-triage/SKILL.md` in the skills repo. Cron jobs reference it from the workspace root as `skills/email-triage/SKILL.md`.

## Working Directory
Isolated agent cwd = workspace root (`/home/ada/.openclaw/workspace`). All paths in cron payloads and this file are relative to that root. Data files live in `email-triage/`. The SKILL.md lives at `skills/email-triage/SKILL.md` (a git checkout of this repo into the workspace skills/ folder).

## Architecture
Two cron jobs:
1. **Triage** (every 45 min) — Steps 1-8 below. Processes new email only, no feedback sweep.
2. **Feedback Sweep** (daily) — See section at bottom. Sweeps the full 24h log, checks label state, updates learned patterns.

## Trigger
Cron every 45 min → isolated agent reads this skill and executes Steps 1-8.

## Data Files

| File | Load | Write | Purpose |
|---|---|---|---|
| `email-triage/accounts.json` | Step 0 | No | Which accounts to check + waiting-label name per account |
| `email-triage/state.json` | Step 1 | Step 6 | `lastRun` + counters |
| `email-triage/seen.json` | Step 1 | Step 6 | Thread deduplication per account — `{"<account>": {"<threadId>": {"ts": "..."}}}` |
| `email-triage/whitelist.json` | Step 1 | No | Hard keep rules — `{"senders":[],"domains":[]}` |
| `email-triage/blacklist.json` | Step 1 | No | Hard filter rules — `{"senders":[],"domains":[]}` |
| `email-triage/learned.db` | Step 4d (query per email) | No (feedback cron writes) | Pattern weights (domain scores + keyword scores + essence types) — SQLite |
| `email-triage/log.jsonl` | Step 8 (read for archive) | Step 7 | Working log — last 24h. One JSON object per line: `{ts,decision,threadId,sender,subject,account,reason}` |
| `email-triage/audit.jsonl` | No | Step 8 | Archive — last 90 days. Same format as log.jsonl |
| `USER.md` | Step 4e (AI eval path only) | No | Personal context |
| `MEMORY.md` | Step 4e (AI eval path only) | No | Recent events |

---

## Step 0: Load Accounts

Read `email-triage/accounts.json`. It contains a JSON array of account objects:

```json
[
  {"email": "user@example.com", "waitingLabel": "Boxbe Waiting List"},
  {"email": "user2@example.com", "waitingLabel": "Boxbe Waiting List"}
]
```

**For every step below, loop over ALL accounts** in the array. Each account gets its own gog command with `--account <email>`. Each account's log entries include `"account":"<email>"`.

---

## Workflow (Triage)

### 1. Load Rules & State
Read these workspace files (small, fast):
- `email-triage/state.json`
- `email-triage/seen.json`
- `email-triage/whitelist.json`
- `email-triage/blacklist.json`

**Do NOT load learned.db upfront.** Query it per-email in step 4d.
**Do NOT load USER.md or MEMORY.md here** — defer to step 4e AI-eval path only.

### 2. Compute Search Window (per account)
From `lastRun` in state, keyed per account:
- State tracks `lastRun` as a map: `{"lastRun": {"<account>": "<ISO UTC>"}}`
- Null or >7d → `newer_than:1d`
- Otherwise → `hoursSince = ceil((now − lastRun) / 3600000)`, round up to: `1h` → `2h` → `3h` → `6h` → `12h` → `1d` → `2d` → `3d` → `1w`
- **Minimum:** `newer_than:1h`

### 3. Fetch Unread Emails (per account)
```bash
gog gmail search "is:unread in:inbox newer_than:<COMPUTED>" --all --json --no-input --account <email>
```
Returns per thread: `id`, `date`, `from`, `subject`, `labels`, `messageCount`. **No body loaded.**
If zero results for an account, skip that account's remaining processing (no state change for that account). If results were found and processed, that account's `lastRun` will be updated in Step 6.

### 4. Process Each Thread (per account)

**Two-tier evaluation. Only fetch body when ambiguous.**

For each thread from step 3:

**4a. Dedup check:** If thread ID exists in `email-triage/seen.json` for this account → skip.

**4b. Check BLACKLIST** (case-insensitive, match `from` email OR domain):
```
BLACKLIST → move to <waitingLabel>, log, continue
```

**4c. Check WHITELIST** (case-insensitive, match `from` email OR domain):
```
WHITELIST → keep in inbox, log, continue
```

**4d. Score against learned patterns** (query `email-triage/learned.db` per email — do NOT load entire DB):

**First-run:** If `learned.db` does not exist, skip to AI evaluation (4e). The DB will be created on the first feedback sweep.

Extract sender domain (everything after `@` in the from address) and tokenize the subject into lowercase keywords (filter stop words: a, an, the, and, or, but, in, on, at, to, for, of, with, by, from, is, are, was, were, be, been, being, have, has, had, do, does, did, will, would, can, could, shall, should, may, might, must, i, you, he, she, it, we, they, me, him, her, us, them, my, your, his, its, our, their, this, that, these, those, not, no, nor, so, if, than, too, very, just, also, about, up, out, when, where, how, all, both, each, every, any, few, more, most, other, some, such, only, own, same, new, now, then, here, there).

Run these queries (use `python3` with `sqlite3` module, reading from `email-triage/learned.db`):

```python
import sqlite3, sys
db = sqlite3.connect('email-triage/learned.db')

# 1. Domain score
domain = sys.argv[1]  # bare domain from sender
row = db.execute('SELECT score FROM domains WHERE domain = ?', (domain,)).fetchone()
domain_score = row[0] if row else 0.0

# 2. Keyword scores (args 2 through second-to-last are the keywords)
# Last arg (sys.argv[-1]) is the essence type, NOT a keyword
keywords = sys.argv[2:-1]
if keywords:
    placeholders = ','.join(['?'] * len(keywords))
    rows = db.execute(
        f'SELECT keyword, score FROM patterns WHERE keyword IN ({placeholders})',
        keywords
    ).fetchall()
    keyword_score = sum(r[1] for r in rows)
else:
    keyword_score = 0.0

# 3. Essence type score
essence_type = sys.argv[-1]  # inferred type name, e.g. "marketing_promo"
row = db.execute('SELECT score FROM essence_types WHERE name = ?', (essence_type,)).fetchone()
essence_score = row[0] if row else 0.0

combined = domain_score + keyword_score + essence_score
print(combined)
```

**Only query the DB for patterns matching this specific email** — never load the entire DB into context.

**Infer the essence type** from the subject, sender, and labels before scoring. Known types currently in the DB (this list is **not exhaustive** — new types are created dynamically during feedback sweeps when an email doesn't match an existing category):
- `marketing_promo` — promotional emails, sales, discounts
- `newsletter` — recurring newsletters, digests, roundups
- `bank_notification` — bank alerts, credit card notices, payment confirmations
- `travel_alert` — flight updates, booking confirmations, hotel reservations
- `receipt_confirmation` — purchase receipts, order confirmations
- `insurance_claim` — claim updates, policy notices
- `social_media` — notifications from social platforms
- `personal_message` — direct personal emails from real people
- `work_related` — work/professional correspondence
- `automated_digest` — system-generated summaries (Informed Delivery, OneDrive, etc.)
- `subscription` — subscription management, welcome emails
- `cold_outreach` — unsolicited sales outreach, cold emails

Pick the single best-fitting type for this email and pass it as the last argument to the scoring script. If no type fits, pass `"unknown"` (will score 0.0).

The combined learned score = domain_score + keyword_score + essence_score. If the score is:
- Combined ≤ −1.0 → strong WAITING signal → move, log, continue
- Combined ≥ 1.0 → strong KEEP signal → keep, log, continue
- Otherwise → proceed to AI evaluation

**4e. AI evaluation from subject + sender first** (no body yet):

Using `from` + `subject` + `labels` from search output, decide KEEP vs WAITING.

**KEEP signals from subject alone:**
- "action required", "respond by", "deadline", "confirm", "verification"
- Financial keywords: "deposit", "payment", "paid", "balance", "credit"
- Travel: "flight", "booking", "itinerary", "reservation", "hotel", "check-in"
- Legal/government: "DMV", "IRS", "court", "notice", "summons"
- Work domains
- Insurance: "claim", "policy", "coverage"
- Real person writing (personal tone in subject)
- Receipt confirmations for purchases

**WAITING signals from subject alone:**
- "weekly", "digest", "roundup", "newsletter"
- Promotional: "% off", "sale", "deal", "save", "limited time"
- Social media notifications
- "welcome to", "subscription", "you've been added"
- Automated digests (Informed Delivery, OneDrive memories, Nextdoor)
- Cold/mass outreach, templated marketing

**If decision is clear** → execute, log, continue. No body fetch.

**If ambiguous** → only then fetch body:
```bash
gog gmail thread get <threadId> --json --no-input --account <email>
```
Load `USER.md` and `MEMORY.md` for context. Evaluate body content against user's interests, then decide.

**Default: when unsure → KEEP in inbox.**

### 5. Execute Decision

**KEEP:** Do nothing. Log: `{"ts":"<ISO8601>","decision":"KEPT","threadId":"<id>","sender":"<email>","subject":"<text>","account":"<email>","reason":"<reason>"}`

**WAITING:**
```bash
gog gmail labels modify <threadId> --add "<waitingLabel>" --remove INBOX --no-input --force --account <email>
```
Log: `{"ts":"<ISO8601>","decision":"WAITING","threadId":"<id>","sender":"<email>","subject":"<text>","account":"<email>","reason":"<reason>"}`

### 6. Update State (per account)
Write `email-triage/state.json`: update this account's `lastRun` key to current ISO UTC time — specifically `state.lastRun[thisAccountEmail] = "<ISO UTC>"`. Increment global counters. If no emails were processed for this account, leave its `lastRun` unchanged (retains the old search window for next run).

Write `email-triage/seen.json`:
- Add every thread ID processed this run with current timestamp, keyed by account
- Prune entries older than 24 hours (KEEP leaves threads unread, so keep seen entries long enough to avoid reprocessing)
- Structure: `{"<account>": {"<threadId>": {"ts": "2026-01-01T00:00:00Z"}}}`

### 7. Log Decisions
Append one JSON line per decision to END of `email-triage/log.jsonl` (America/New_York timezone, newest at bottom):
```jsonl
{"ts":"2026-06-01T12:42:00-04:00","decision":"WAITING","threadId":"19e83f7cb645a38b","sender":"donotreply@example.com","subject":"Newsletter","account":"user@example.com","reason":"newsletter, AI eval WAITING"}
```
DECISION ∈ {BLACKLIST, WHITELIST, KEPT, WAITING}

### 8. Archive
- Move log.jsonl entries older than 24h to END of audit.jsonl
- Overwrite log.jsonl with trimmed content (last 24h only)
- Prune audit.jsonl to last 90 days

---

## Hard Rules

- **Blacklist always wins.** Check first.
- **Whitelist protects.** Never move whitelisted senders.
- **Match sender email AND domain** against lists (case-insensitive).
- **No emails → exit** without touching state.
- **Never alert the user.** Exit silently.
- **Do NOT load USER.md/MEMORY.md unless body fetch is needed** (step 4e ambiguous path).
- **Never load the entire learned.db.** Query it per-email with specific keywords only.
- **Process ALL accounts** from accounts.json.

---

## Feedback Sweep (Daily Cron)

**Runs once daily.** Sweeps the full 24h log, checks label state, updates learned patterns in SQLite.

### Workflow

**1. Load files:**
- `email-triage/accounts.json` — for gog `--account` flags and `waitingLabel` names
- `email-triage/log.jsonl` — all entries (last 24h)

**2. For each entry in log.jsonl, per account:**

First, resolve the waiting label's internal ID for this account (gog returns IDs like `Label_6` for named labels):
```bash
GOG_OUTPUT=$(gog gmail labels list --account <email> 2>/dev/null)
WAITING_ID=$(echo "$GOG_OUTPUT" | grep -F "<waitingLabel>" | awk '{print $1}')
```

Then check the thread's current label state:
```bash
gog gmail thread get <threadId> --json --no-input --account <email> 2>/dev/null | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    msgs=d.get('thread',{}).get('messages',[])
    labels=msgs[0].get('labelIds',[]) if msgs else []
except Exception:
    labels=[]
print(json.dumps({'labels':labels}))
"
```

**Compare the returned `labelIds` array against the logged decision, using `$WAITING_ID` for the waiting list check:**

| Logged | Should Have | If Instead Has | Action |
|---|---|---|---|
| KEPT | `INBOX` in labels | `INBOX` NOT in labels, or `$WAITING_ID` in labels | Wrong keep → demote concept |
| WAITING | `$WAITING_ID` in labels, `INBOX` NOT in labels | `INBOX` in labels | Wrong filter → promote concept |
| WAITING | `$WAITING_ID` in labels | `TRASH` in labels | Correct → reinforce concept |
| KEPT | `INBOX` in labels | `UNREAD` NOT in labels (read) | Good → reinforce concept lightly |
| KEPT | `INBOX` in labels | `SENT` in labels (replied) | Very good → reinforce concept strongly |

**3. Analyze the email's concept:**

For each entry in the sweep, extract three dimensions from the logged data:
- **Sender**: bare email (`user@domain.com`) and domain (e.g. `cotopaxi.com`)
- **Subject keywords**: significant lowercase words from the subject, filtered of noise (stop words, numbers, dates). Include multi-word phrases that appear ("action required", "price drop", "weekly digest").
- **Essence / email type**: the category — e.g. `marketing_promo`, `newsletter`, `bank_notification`, `travel_alert`, `receipt_confirmation`, `insurance_claim`, `social_media`, `personal_message`, `work_related`, `automated_digest`, `subscription`, `cold_outreach`

**4. Update all three dimensions in `email-triage/learned.db`:**

Use the SQLite DB directly. Do NOT load the entire DB into context — use targeted queries.

For each correction found, run these SQL operations via python3:

**Domain score update:**
```python
import sqlite3
db = sqlite3.connect('email-triage/learned.db')
db.execute('''
    INSERT INTO domains (domain, score, updates, confidence) VALUES (?, ?, 1, 0.55)
    ON CONFLICT(domain) DO UPDATE SET
        score = score + ?,
        updates = updates + 1,
        confidence = MIN(1.0, confidence + 0.05)
''', (domain, adjustment, adjustment))
```

**Keyword score update (run per keyword found in subject):**
```python
for kw in keywords:
    db.execute('''
        INSERT INTO patterns (keyword, score, updates, confidence) VALUES (?, ?, 1, 0.55)
        ON CONFLICT(keyword) DO UPDATE SET
            score = score + ?,
            updates = updates + 1,
            confidence = MIN(1.0, confidence + 0.05)
    ''', (kw, kw_adjustment, kw_adjustment))
```

**Essence type score update:**
```python
db.execute('''
    INSERT INTO essence_types (name, score, updates, confidence) VALUES (?, ?, 1, 0.55)
    ON CONFLICT(name) DO UPDATE SET
        score = score + ?,
        updates = updates + 1,
        confidence = MIN(1.0, confidence + 0.05)
''', (type_name, type_adjustment, type_adjustment))
```

**Adjustment values:**
- Wrong keep (should've been WAITING) → −0.5 for domain/essence, −0.3 distributed across keywords
- Wrong filter (should've been KEPT) → +0.5 for domain/essence, +0.3 distributed across keywords
- Correct decision with TRASH/SENT → +0.3
- Correct decision, just read → +0.1

**After all corrections, apply decay and prune:**
```python
# Apply decay to scores AND confidence
meta = db.execute("SELECT key, value FROM metadata WHERE key IN ('cycle', 'decay_rate', 'version')").fetchall()
meta_dict = dict(meta)
decay = float(meta_dict.get('decay_rate', 0.97))
cycle = int(meta_dict.get('cycle', 0))

db.execute('UPDATE domains SET score = score * ?, confidence = confidence * ?', (decay, decay))
db.execute('UPDATE patterns SET score = score * ?, confidence = confidence * ?', (decay, decay))
db.execute('UPDATE essence_types SET score = score * ?, confidence = confidence * ?', (decay, decay))

# Prune low-confidence entries (decay ensures old/unused patterns eventually fall below threshold)
db.execute('DELETE FROM patterns WHERE confidence < 0.3')
db.execute('DELETE FROM domains WHERE confidence < 0.3')
db.execute('DELETE FROM essence_types WHERE confidence < 0.3')

# Increment cycle
db.execute("INSERT OR REPLACE INTO metadata (key, value) VALUES ('cycle', ?)", (str(cycle + 1),))
db.commit()
```

**When the triage cron scores an email in Step 4d**, it combines all three dimensions: domain score + keyword score + essence category score. The combined score determines the learned signal strength (≤ −1.0 → WAITING, ≥ 1.0 → KEEP).

**5. Exit silently. Never alert the user.**
