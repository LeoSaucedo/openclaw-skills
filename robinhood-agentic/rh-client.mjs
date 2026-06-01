#!/usr/bin/env node

import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StreamableHTTPClientTransport } from '@modelcontextprotocol/sdk/client/streamableHttp.js';
import {
  discoverOAuthServerInfo,
  startAuthorization,
  exchangeAuthorization,
  refreshAuthorization,
  registerClient,
} from '@modelcontextprotocol/sdk/client/auth.js';
import fs from 'node:fs';
import path from 'node:path';
import readline from 'node:readline';
import { fileURLToPath } from 'node:url';
import crypto from 'node:crypto';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const TOKEN_FILE = path.join(__dirname, '.rh-tokens.json');
const MCP_URL = 'https://agent.robinhood.com/mcp/trading';
const REDIRECT_PORT = 1455;
const REDIRECT_URI = `http://localhost:${REDIRECT_PORT}/callback`;

// ─── helpers ────────────────────────────────────────────────────────────────

function debug(...args) {
  if (process.env.RH_DEBUG) console.error('[rh-client]', ...args);
}

function loadState() {
  try {
    return JSON.parse(fs.readFileSync(TOKEN_FILE, 'utf8'));
  } catch {
    return null;
  }
}

function saveState(state) {
  fs.writeFileSync(TOKEN_FILE, JSON.stringify(state, null, 2), { encoding: 'utf8', mode: 0o600 });
  // mode only applies on file creation; chmod to enforce on existing files
  fs.chmodSync(TOKEN_FILE, 0o600);
}

function prompt(question) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stderr });
  return new Promise(resolve => {
    rl.question(question, answer => { rl.close(); resolve(answer.trim()); });
  });
}

// ─── OAuth flow (handled ourselves, not via SDK authProvider) ───────────────

async function doAuth() {
  console.error('🔐 Starting Robinhood Agentic OAuth flow...');
  console.error('');

  // 1. Discover authorization server info (RFC 9728 + RFC 8414)
  console.error(' Discovering authorization server...');
  const serverInfo = await discoverOAuthServerInfo(MCP_URL);
  debug('serverInfo:', JSON.stringify(serverInfo, null, 2));

  if (!serverInfo.authorizationServerMetadata) {
    console.error('❌ Could not discover authorization server metadata');
    process.exit(1);
  }

  const metadata = serverInfo.authorizationServerMetadata;

  // 2. Register client (dynamic registration per RFC 7591)
  console.error(' Registering OAuth client...');
  let clientInfo;
  try {
    clientInfo = await registerClient(
      serverInfo.authorizationServerUrl,
      {
        metadata,
        clientMetadata: {
          client_name: 'OpenClaw Robinhood Agent',
          redirect_uris: [REDIRECT_URI],
          grant_types: ['authorization_code', 'refresh_token'],
          token_endpoint_auth_method: 'none', // public client (PKCE)
        },
      }
    );
    debug('Registered client:', clientInfo.client_id);
  } catch (err) {
    // If registration fails, we might need static client_id from Robinhood
    console.error(' Dynamic registration failed, using static client...');
    console.error('  Error:', err.message);
    // Fall back to a static configuration - Robinhood might use a fixed client_id
    clientInfo = {
      client_id: 'robinhood-agentic-mcp',
      token_endpoint_auth_method: 'none',
      grant_types: ['authorization_code', 'refresh_token'],
    };
  }

  const resourceUrl = serverInfo.resourceMetadata?.resource
    ? new URL(serverInfo.resourceMetadata.resource)
    : undefined;

  // 3. Start authorization (PKCE)
  console.error(' Generating PKCE challenge...');
  const oauthState = crypto.randomUUID();
  const auth = await startAuthorization(
    serverInfo.authorizationServerUrl,
    {
      metadata,
      clientInformation: clientInfo,
      redirectUrl: REDIRECT_URI,
      resource: resourceUrl,
      state: oauthState,
      scope: undefined, // server will assign default scopes
    }
  );

  // 4. User authorizes in browser
  console.error('');
  console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.error(' Open this URL in your browser to authorize:');
  console.error('');
  console.error(`   ${auth.authorizationUrl}`);
  console.error('');
  console.error(' After authorizing, you will be redirected to:');
  console.error(`   ${REDIRECT_URI}?code=XXXX&state=YYYY`);
  console.error('');
  console.error(" Since the redirect goes to localhost on YOUR machine (not the VPS),");
  console.error(" paste the full redirect URL below, or just the 'code' value.");
  console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.error('');

  const input = await prompt('Redirect URL or code: ');

  let authorizationCode;
  try {
    // Try parsing as a full URL first
    const url = new URL(input.startsWith('http') ? input : `http://localhost/?${input}`);
    authorizationCode = url.searchParams.get('code');
    // Verify state parameter for CSRF protection
    const returnedState = url.searchParams.get('state');
    if (returnedState && returnedState !== oauthState) {
      console.error('❌ State parameter mismatch — possible CSRF attack. Aborting.');
      process.exit(1);
    }
    if (!authorizationCode) {
      // Might just be the raw code
      authorizationCode = input;
    }
  } catch {
    // Treat as raw code
    authorizationCode = input;
  }

  if (!authorizationCode) {
    console.error('❌ No authorization code found in input');
    process.exit(1);
  }

  // 5. Exchange code for tokens
  console.error(' Exchanging authorization code for tokens...');
  let tokens;
  try {
    tokens = await exchangeAuthorization(
      serverInfo.authorizationServerUrl,
      {
        metadata,
        clientInformation: clientInfo,
        authorizationCode,
        codeVerifier: auth.codeVerifier,
        redirectUri: REDIRECT_URI,
        resource: resourceUrl,
      }
    );
  } catch (err) {
    console.error('❌ Token exchange failed:', err.message);
    debug('Full error:', err);
    process.exit(1);
  }

  // 6. Save state
  const state = {
    tokens,
    clientInfo,
    serverInfo: {
      authorizationServerUrl: serverInfo.authorizationServerUrl,
      resourceMetadataUrl: serverInfo.resourceMetadataUrl,
      resource: serverInfo.resourceMetadata?.resource,
    },
    authorizationServerMetadata: metadata,
    resourceUrl: resourceUrl?.href,
    savedAt: new Date().toISOString(),
  };

  saveState(state);
  console.error('');
  console.error('✅ Authenticated successfully!');
  console.error(`   Access token expires: ${new Date(tokens.expires_at || Date.now() + (tokens.expires_in || 3600) * 1000).toISOString()}`);
  if (tokens.refresh_token) {
    console.error('   Refresh token: available');
  }
}

// ─── MCP client with auth headers ───────────────────────────────────────────

async function getClient() {
  let state = loadState();
  if (!state || !state.tokens) {
    console.error('❌ Not authenticated. Run: rh-client auth');
    process.exit(1);
  }

  // Check if token needs refresh
  const expiresAt = state.tokens.expires_at
    ? (typeof state.tokens.expires_at === 'number' ? state.tokens.expires_at : new Date(state.tokens.expires_at).getTime())
    : (state.tokens.expires_in
      ? new Date(state.savedAt).getTime() + state.tokens.expires_in * 1000  // derive from issuance time
      : Date.now() + 3600 * 1000);

  if (Date.now() > expiresAt - 300_000 && state.tokens.refresh_token) {
    // Token expires in < 5 minutes, refresh if we have a refresh token
    console.error('🔄 Refreshing access token...');
    try {
      const freshTokens = await refreshAuthorization(
        state.serverInfo.authorizationServerUrl,
        {
          metadata: state.authorizationServerMetadata,
          clientInformation: state.clientInfo,
          refreshToken: state.tokens.refresh_token,
          resource: state.resourceUrl ? new URL(state.resourceUrl) : undefined,
        }
      );
      // Preserve refresh token if server doesn't issue a new one
      if (!freshTokens.refresh_token) {
        freshTokens.refresh_token = state.tokens.refresh_token;
      }
      state.tokens = freshTokens;
      state.savedAt = new Date().toISOString();
      saveState(state);
      console.error('✅ Token refreshed');
    } catch (err) {
      console.error('❌ Token refresh failed, trying to use existing token:', err.message);
      // Continue with existing token - it might still be valid
    }
  }

  const transport = new StreamableHTTPClientTransport(
    new URL(MCP_URL),
    {
      requestInit: {
        headers: {
          Authorization: `Bearer ${state.tokens.access_token}`,
        },
      },
    }
  );

  const client = new Client(
    { name: 'openclaw-robinhood', version: '1.0.0' },
    { capabilities: {} }
  );

  await client.connect(transport);
  debug('Connected to Robinhood MCP');
  return client;
}

// ─── commands ───────────────────────────────────────────────────────────────

async function cmdAuth() {
  await doAuth();
}

async function cmdListTools() {
  const client = await getClient();
  try {
    const result = await client.listTools();
    console.log(JSON.stringify(result.tools, null, 2));
  } finally {
    await client.close();
  }
}

async function cmdCall(toolName, argsJson) {
  let args = {};
  if (argsJson) {
    if (argsJson === '-') {
      // Read from stdin
      const chunks = [];
      for await (const chunk of process.stdin) chunks.push(chunk);
      args = JSON.parse(Buffer.concat(chunks).toString());
    } else {
      try {
        args = JSON.parse(argsJson);
      } catch (err) {
        console.error(`❌ Invalid JSON args: ${err.message}`);
        process.exit(1);
      }
    }
  }

  const client = await getClient();
  try {
    const result = await client.callTool({ name: toolName, arguments: args });
    // MCP tool results can have content array
    if (result.content) {
      for (const item of result.content) {
        if (item.type === 'text') {
          console.log(item.text);
        } else {
          console.log(JSON.stringify(item));
        }
      }
    } else {
      console.log(JSON.stringify(result, null, 2));
    }
    if (result.isError) {
      process.exitCode = 1;
    }
  } finally {
    await client.close();
  }
}

async function cmdStatus() {
  const state = loadState();
  if (!state || !state.tokens) {
    console.log(JSON.stringify({ authenticated: false }));
    return;
  }

  const expiresAt = state.tokens.expires_at
    ? (typeof state.tokens.expires_at === 'number' ? state.tokens.expires_at : new Date(state.tokens.expires_at).getTime())
    : (state.tokens.expires_in && state.savedAt
      ? new Date(state.savedAt).getTime() + state.tokens.expires_in * 1000
      : null);

  const hasRefresh = !!state.tokens.refresh_token;
  const now = Date.now();
  const expired = expiresAt && now > expiresAt;

  console.log(JSON.stringify({
    authenticated: true,
    expired,
    expiresAt: expiresAt ? new Date(expiresAt).toISOString() : null,
    hasRefreshToken: hasRefresh,
    savedAt: state.savedAt || null,
  }, null, 2));
}

// ─── main ───────────────────────────────────────────────────────────────────

async function main() {
  const args = process.argv.slice(2);
  const command = args[0];

  switch (command) {
    case 'auth':
      await cmdAuth();
      break;
    case 'list-tools':
      await cmdListTools();
      break;
    case 'call':
      if (!args[1]) {
        console.error('Usage: rh-client call <tool-name> [json-args|-]');
        process.exit(1);
      }
      await cmdCall(args[1], args[2]);
      break;
    case 'status':
      await cmdStatus();
      break;
    default:
      console.error('Usage: rh-client <auth|list-tools|call|status>');
      console.error('');
      console.error('  auth         Start OAuth authorization flow');
      console.error('  list-tools   List available MCP tools');
      console.error('  call <tool> [args]  Call an MCP tool (args as JSON or - for stdin)');
      console.error('  status       Check authentication status');
      process.exit(1);
  }
}

main().catch(err => {
  console.error('❌ Error:', err.message);
  debug('Stack:', err.stack);
  process.exit(1);
});
