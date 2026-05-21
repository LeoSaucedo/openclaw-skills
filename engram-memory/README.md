# engram-memory

Graph-based memory skill for storing facts and tracing relationships.

## Files

- `SKILL.md` — skill manifest and command reference
- `engram-memory.mjs` — CLI wrapper for memory operations

## Dependencies

- `@bottensor/engram`

## Quick Start

From repository root:

```bash
node skills/engram-memory/engram-memory.mjs add '{"content":"fact","type":"semantic","importance":0.8}'
node skills/engram-memory/engram-memory.mjs search "fact"
node skills/engram-memory/engram-memory.mjs decay
```

## Capabilities

- Store typed memories (`episodic`, `semantic`, `entity`, `goal`, `observation`)
- Search related memory nodes
- Build links between nodes (`caused_by`, `related_to`, `part_of`, etc.)
- Generate compact context for follow-up tasks
- Apply decay to LTM nodes

## Data Location

- `skills/engram-memory/.agent/memory/graph.json`
