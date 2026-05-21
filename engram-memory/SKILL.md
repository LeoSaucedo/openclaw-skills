---
name: engram-memory
description: Graph-based agent memory for tracing relationships between facts. Use when memory_search returns isolated facts and you need to see how they connect — causal chains, hierarchies, related events. LTM-only, stored as JSON graph with typed nodes and weighted edges.
metadata:
  author: github.com/LeoSaucedo
---

# Engram — Graph-Based Agent Memory

`@bottensor/engram` stores typed nodes (events, facts, people, goals, observations) with weighted edges (causal, hierarchical, temporal). Runs as local Node.js via exec. Disk: `.agent/memory/graph.json`. No API keys needed.

## Commands

Run from workspace root. Wrapper relative to this skill directory.

### Store

```bash
node skills/engram-memory/engram-memory.mjs add '{"content":"fact","type":"semantic","importance":0.8}'
```
Types: `episodic` (events), `semantic` (facts/prefs), `entity` (people), `goal` (tasks), `observation` (patterns)

### Search

```bash
node skills/engram-memory/engram-memory.mjs search "query"
```

### Decay

```bash
node skills/engram-memory/engram-memory.mjs decay
```
Applies decay to LTM nodes based on time since last access and importance score. Nodes dropping below threshold are pruned.

### Dependency

This skill requires the `@bottensor/engram` node package.

### Link

```bash
node skills/engram-memory/engram-memory.mjs link '{"fromId":"<id>","toId":"<id>","relation":"caused_by"}'
```
Relations: `caused_by`, `leads_to`, `part_of`, `related_to`, `contradicts`, `reinforces`, `precedes`, `follows`

## When to use vs memory_search

- **Fact lookup:** memory_search (broader, more accurate)
- **Tracing connections:** Engram (walks the graph)
- **Session wake-up:** Engram context (token-efficient)
- **Causal chains:** Engram

## Data

- Persistent JSON at `skills/engram-memory/.agent/memory/graph.json`
- Auto-loads on first call, explicit `save()` after mutations (wrapper handles this)
- Cron (3:30 AM) feeds nightly
- Remove skill dir to fully revert
