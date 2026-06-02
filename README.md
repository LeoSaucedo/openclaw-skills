# openclaw-skills

Collection of OpenClaw skills for API-powered assistant capabilities.

## Skills

| Skill | Purpose | Directory |
|---|---|---|
| deepseek-balance | Check DeepSeek API balance and usage | `skills/deepseek-balance` |
| engram-memory | Graph-based long-term memory and relationship tracing | `skills/engram-memory` |
| google-maps-directions | Drive time, distance, and route lookups via Google Maps | `skills/google-maps-directions` |
| lastfm | Last.fm profile, scrobble, chart, and discovery queries | `skills/lastfm` |
| robinhood-agentic | MCP client for Robinhood Agentic Trading — portfolio, analysis, and trade execution | `robinhood-agentic/` |
| soundcloud | Search tracks, user info, and playlist operations on SoundCloud | `skills/soundcloud` |
| wolfram-alpha | Computational queries via Wolfram Alpha LLM API | `skills/wolfram-alpha` |

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
