# Copilot Code Review Instructions

This file tells Copilot about repo-wide conventions so reviews surface real issues, not style churn.

## SKILL.md Front Matter

Every SKILL.md must have YAML front matter with these fields:

```yaml
---
name: <kebab-case-skill-name>
description: <one-sentence description of what the skill does and when to use it>
metadata:
  author: github.com/LeoSaucedo
---
```

- `author` is ALWAYS `github.com/LeoSaucedo` (NOT a full https:// URL, NOT any other user)
- `description` should describe what the skill does and when OpenClaw should invoke it
- `name` must match the skill directory name exactly

## README.md

Every skill directory must have a README.md covering:
- Brief description
- Install instructions (if applicable)
- Usage examples
- Requirements/prerequisites
- Security notes (if handling credentials)

The README should refer to the assistant as "OpenClaw" or "the AI agent", not specific assistant names.

## Directory Structure

Skills live at the repo root (NOT inside a `skills/` directory):

```
<skill-name>/
  SKILL.md        # Front matter + usage instructions for OpenClaw
  README.md       # Human-readable documentation
  .gitignore      # If the skill uses node_modules or token files
  package.json    # If the skill is a Node.js package
```

The root README.md references skills by their directory name (e.g., `robinhood-agentic/`), not with a `skills/` prefix.

## Package Skills (Node.js)

For skills that are npm packages:
- Use `"type": "module"` in package.json for ESM
- `.gitignore` must include `node_modules/` and any credential/token files
- Token files must be written with `0o600` permissions using atomic writes (temp file + rename)
- Use `__dirname` + `.gitignore` for token file defaults, with an env var override
- Shell-out scripts should default token storage to a gitignored path

## Code Quality

- No unused imports or dead variables
- Defensive guards on optional state (e.g., `state.savedAt` before `new Date(state.savedAt)`)
- Fail fast with clear actionable messages (not cryptic transport errors)
- Atomic file writes for any persisted state
- OAuth state parameters must be generated, stored, and validated for CSRF protection
- Expiry calculations should derive from stored issuance timestamps, not `Date.now()` at read time

## Review Focus

Do NOT re-flag issues already addressed in this instructions file. Focus on:
- Security vulnerabilities (credential leaks, CSRF, injection)
- Logic errors (wrong variable, missing guards, incorrect derivations)
- Real bugs (not style preferences already covered here)
