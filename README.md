# openclaw-skills

[![🦞 ClawHub](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2FLeoSaucedo%2Fopenclaw-skills%2Fmaster%2Fbadges%2Ftotal-downloads.json&style=flat)](https://clawhub.ai/user/leosaucedo)

Collection of OpenClaw skills for API-powered assistant capabilities.

## Skills

| Skill | Purpose | Directory | Downloads |
|---|---|---|---|
| deepseek-balance | Check DeepSeek API balance and usage | `skills/deepseek-balance` | — |
| email-triage | Gmail inbox triage with self-learning SQLite pattern database | `skills/email-triage` | — |
| engram-memory | Graph-based long-term memory and relationship tracing | `skills/engram-memory` | — |
| google-maps-directions | Drive time, distance, and route lookups via Google Maps | `skills/google-maps-directions` | — |
| lastfm | Last.fm profile, scrobble, chart, and discovery queries | `skills/lastfm` | — |
| robinhood-agentic | MCP client for Robinhood Agentic Trading — portfolio, analysis, and trade execution | `skills/robinhood-agentic` | [![downloads](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fclawhub.ai%2Fapi%2Fv1%2Fskills%2Frobinhood-agentic&query=%24.skill.stats.downloads&label=%20&color=blue&style=flat-square)](https://clawhub.ai/leosaucedo/robinhood-agentic) |
| soundcloud | Search tracks, user info, and playlist operations on SoundCloud | `skills/soundcloud` | [![downloads](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fclawhub.ai%2Fapi%2Fv1%2Fskills%2Fsoundcloud&query=%24.skill.stats.downloads&label=%20&color=blue&style=flat-square)](https://clawhub.ai/leosaucedo/soundcloud) |
| wanikani | WaniKani Japanese study — kanji, vocabulary, review and SRS progress | `skills/wanikani` | — |
| wolfram-alpha | Computational queries via Wolfram Alpha LLM API | `skills/wolfram-alpha` | — |

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
