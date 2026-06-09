# openclaw-skills

[![ClawHub](https://img.shields.io/badge/%F0%9F%A6%9E_ClawHub-Publisher-6366f1?style=flat)](https://clawhub.ai/user/leosaucedo)

Collection of OpenClaw skills for API-powered assistant capabilities.

## Skills

| Skill | Purpose |
|---|---|
| deepseek-balance | Check DeepSeek API balance and usage |
| email-triage | Gmail inbox triage with self-learning SQLite pattern database |
| engram-memory | Graph-based long-term memory and relationship tracing |
| google-maps-directions | Drive time, distance, and route lookups via Google Maps |
| lastfm | Last.fm profile, scrobble, chart, and discovery queries |
| robinhood-agentic | MCP client for Robinhood Agentic Trading — portfolio, analysis, and trade execution |
| soundcloud | Search tracks, user info, and playlist operations on SoundCloud |
| wanikani | WaniKani Japanese study — kanji, vocabulary, review and SRS progress |
| wolfram-alpha | Computational queries via Wolfram Alpha LLM API |

## Repository Structure

```text
skills/
  <skill-name>/
    SKILL.md        # Skill manifest + usage instructions
    README.md       # Skill-specific quick documentation
    scripts/        # Executable helper scripts
    references/     # API references and troubleshooting docs
```

## Skill Usage Pattern

1. Open the skill directory.
2. Read `SKILL.md` for capability and routing context.
3. Follow the setup steps in the skill `README.md`.
4. Run scripts in `scripts/` with required environment variables.

## Environment Variables

Each skill documents its required variables in its `SKILL.md`/`README.md` (for example API keys and tokens).

## Notes

- This repository is focused on skill definitions and helper scripts.
- Validate API credentials in your shell before running scripts.
