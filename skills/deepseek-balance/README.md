# deepseek-balance

Check DeepSeek API credit balance and usage status.

## Files

- `SKILL.md` — skill manifest and full guidance
- `scripts/check_balance.sh` — main balance check script
- `references/` — API and error references

## Quick Start

```bash
export DEEPSEEK_API_TOKEN="sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
./scripts/check_balance.sh
```

## Output

Returns account availability and balance details (total, granted, topped-up credits).

## Required Environment Variable

- `DEEPSEEK_API_TOKEN`
