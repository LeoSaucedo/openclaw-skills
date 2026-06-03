# email-triage

Gmail inbox triage automation with a self-learning SQLite pattern database. Maintains important emails in the inbox and moves noise to a configurable waiting list label.

## Quick Start

1. **Set up accounts:** Create `email-triage/accounts.json` at the workspace root with your Gmail accounts and waiting list label names (see INSTALL.md for format).
2. **Seed data files:** Copy the seed templates from [INSTALL.md](INSTALL.md) to create `state.json`, `seen.json`, `whitelist.json`, `blacklist.json` in `email-triage/` at the workspace root.
3. **Create the DB:** The `learned.db` SQLite database is auto-created on the first feedback sweep. See [INSTALL.md](INSTALL.md#step-3-create-learneddb) for the schema.
4. **Set up cron jobs:** Two OpenClaw cron jobs — triage (every 45 min) and feedback sweep (daily). See [INSTALL.md](INSTALL.md#step-4-set-up-cron-jobs) for the full JSON payloads.

## Requirements

- **gog** (Google Workspace CLI) — configured with OAuth for each Gmail account
- **Python 3.10+** with `sqlite3` module (stdlib)
- **OpenClaw** with cron job support

## How It Works

The triage pipeline runs every 45 minutes:
1. Fetches unread inbox threads for each configured account
2. Checks whitelist/blacklist (hard rules always win)
3. Scores against learned patterns (domain + keyword + essence type scores from SQLite)
4. If score is ambiguous, evaluates sender + subject with AI
5. Moves noise to the waiting list label via gog CLI

A daily feedback sweep reviews the last 24 hours of decisions, checks whether the user agreed (by checking current label state), and adjusts the SQLite pattern weights accordingly.

## Security Notes

- **PII lives outside the repo.** Account emails and waiting list labels are configured in `email-triage/accounts.json` at the workspace root — this file is NOT part of the git repository.
- **Gmail access** requires OAuth credentials configured via gog for each account. The skill does not store passwords or tokens — gog handles authentication via stored OAuth refresh tokens.
- **Thread deduplication** (`seen.json`) expires entries after 24 hours to avoid reprocessing, but never stores email content — only thread IDs and timestamps.
- **Logs** (`log.jsonl`, `audit.jsonl`) store sender addresses, subjects, and decisions for feedback sweep training. Prune audit logs to 90 days by default.

## Files

| File | In Repo? | Purpose |
|---|---|---|
| `SKILL.md` | ✅ | Skill manifest and workflow |
| `INSTALL.md` | ✅ | Setup guide with schema and seed files |
| `README.md` | ✅ | This file |
| `email-triage/accounts.json` | ❌ (workspace root) | Account config with PII |
| `email-triage/state.json` | ❌ (workspace root) | Triage state per account |
| `email-triage/seen.json` | ❌ (workspace root) | Thread dedup cache |
| `email-triage/whitelist.json` | ❌ (workspace root) | Hard keep rules |
| `email-triage/blacklist.json` | ❌ (workspace root) | Hard filter rules |
| `email-triage/log.jsonl` | ❌ (workspace root) | Decision log (24h) |
| `email-triage/audit.jsonl` | ❌ (workspace root) | Archive log (90d) |
| `email-triage/learned.db` | ❌ (workspace root) | SQLite pattern database |

## Related

- [INSTALL.md](INSTALL.md) — Full setup guide, DB schema, seed files, cron configuration
