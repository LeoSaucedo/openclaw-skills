#!/usr/bin/env node
// engram-memory.mjs — Agentic Memory wrapper
// Usage: node --input-type=module engram-memory.mjs <cmd> [args]
// Run from /home/ada/.openclaw/workspace
// MIT-licensed test harness — remove file to revert

import { AgenticMemory } from '@bottensor/engram';
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));

// storageDir intentionally points outside this repository.
// ../../memory resolves to workspace/memory/graph.json — alongside other
// memory files, excluded from version control and Syncthing.
const memory = new AgenticMemory({ backend: 'local', storageDir: join(__dirname, '../../memory') });
const cmd = process.argv[2];

// ── Helpers ────────────────────────────────────────────

function die(reason) {
  console.error(reason);
  process.exit(1);
}

function log(msg) {
  const ts = new Date().toISOString().slice(0, 19);
  const line = `[${ts}] ${msg}`;
  console.log(line);
  try { writeFileSync('/tmp/engram.log', line + '\n', { flag: 'a' }); } catch {}
}

function bail() {
  // Safety: if ALL commands fail with same error, something is wrong
  // The cronscript will notice stderr and skip engram step gracefully
  return 1;
}

// ── Commands ────────────────────────────────────────────

async function cmdDecay() {
  try {
    await memory.load();
    const removed = await memory.ltm.decay();
    await memory.save();
    log(`DECAYED: ${removed.length} nodes removed`);
    console.log(`Removed: ${removed.length} nodes`);
  } catch (e) {
    log(`DECAY FAIL: ${e.message}`);
    bail();
  }
}

async function cmdAdd() {
  const json = process.argv.slice(3).join(' ');
  let data;
  try { data = JSON.parse(json); } catch { die('Invalid JSON'); }
  if (!data.content) die('Missing "content"');
  const type = data.type || 'semantic';
  const importance = data.importance ?? 0.7;
  try {
    const result = await memory.add(data.content, type, importance);
    await memory.save();
    // Use LTM node ID for linking, fall back to STM entry ID
    const id = result?.ltmNode?.id ?? result?.stmEntry?.id ?? 'unknown';
    log(`ADDED [${type}] ${data.content.slice(0, 80)} | id=${id}`);
    console.log(id);
  } catch (e) {
    log(`ADD FAIL: ${e.message}`);
    bail();
  }
}

async function cmdBatch() {
  let raw;
  try { raw = readFileSync('/dev/stdin', 'utf-8'); } catch { die('No stdin input'); }
  let items;
  try { items = JSON.parse(raw); } catch { die('Invalid JSON on stdin'); }
  if (!Array.isArray(items)) die('Expected JSON array');
  
  let added = 0;
  let skipped = 0;
  const ids = [];
  for (const item of items) {
    if (!item.content) { skipped++; continue; }
    try {
      const result = await memory.add(item.content, item.type || 'semantic', item.importance ?? 0.7);
      const id = result?.ltmNode?.id ?? result?.stmEntry?.id ?? 'unknown';
      ids.push(id);
      log(`BATCH [${item.type || 'semantic'}] ${item.content.slice(0, 60)} | id=${id}`);
      added++;
    } catch (e) {
      log(`BATCH FAIL: ${e.message}`);
      skipped++;
    }
  }
  await memory.save();
  log(`BATCH DONE: ${added} added, ${skipped} skipped`);
  console.log(JSON.stringify({ added, skipped, ids }));
}

async function cmdLink() {
  const json = process.argv.slice(3).join(' ');
  let data;
  try { data = JSON.parse(json); } catch { die('Invalid JSON'); }
  if (!data.fromId) die('Missing "fromId"');
  if (!data.toId) die('Missing "toId"');
  try {
    await memory.load();
    await memory.link(data.fromId, data.toId, data.relation || 'related_to');
    await memory.save();
    log(`LINKED ${data.fromId.slice(0,8)}→${data.toId.slice(0,8)} [${data.relation || 'related_to'}]`);
    console.log('linked');
  } catch (e) {
    log(`LINK FAIL: ${e.message}`);
    console.log(e.message); // non-fatal, log and continue
  }
}

async function cmdSearch() {
  const query = process.argv.slice(3).join(' ');
  if (!query) die('Missing query');
  try {
    const results = await memory.search(query);
    console.log(JSON.stringify(results.slice(0, 10)));
    log(`SEARCH "${query.slice(0, 60)}" → ${results.length} results`);
  } catch (e) {
    log(`SEARCH FAIL: ${e.message}`);
    bail();
  }
}

async function cmdContext() {
  const prompt = process.argv.slice(3).join(' ') || 'Recent context';
  try {
    const ctx = await memory.buildContext(prompt);
    console.log(ctx);
  } catch (e) {
    log(`CONTEXT FAIL: ${e.message}`);
  }
}

async function cmdGraph() {
  try {
    const graphData = memory['_graphDump'] || memory['ltm']?.['_graph'];
    // Try internal API access; if not available, search for all
    const results = await memory.search('', { topK: 1000 });
    console.log(JSON.stringify(results, null, 2));
  } catch (e) {
    log(`GRAPH FAIL: ${e.message}`);
  }
}

async function cmdStats() {
  try {
    const all = await memory.search('', { topK: 1000 });
    const types = {};
    for (const r of all) {
      const t = r.node?.type || r.type || 'unknown';
      types[t] = (types[t] || 0) + 1;
    }
    console.log(JSON.stringify({ totalNodes: all.length, types }, null, 2));
    log(`STATS: ${all.length} nodes`);
  } catch (e) {
    log(`STATS FAIL: ${e.message}`);
  }
}

// ── Dispatch ────────────────────────────────────────────

(async () => {
  try {
    switch (cmd) {
      case 'decay': await cmdDecay();   break;
      case 'add':     await cmdAdd();     break;
      case 'batch':   await cmdBatch();   break;
      case 'link':    await cmdLink();    break;
      case 'search':  await cmdSearch();  break;
      case 'context': await cmdContext(); break;
      case 'stats':   await cmdStats();   break;
      case 'graph':   await cmdGraph();   break;
      default:
        die(`Unknown command: ${cmd}\nUsage: add <json> | batch <stdin-json-array> | link <json> | search <query> | context [prompt] | stats`);
    }
  } catch (e) {
    log(`FATAL: ${e.stack || e.message}`);
    process.exit(1);
  }
})();
