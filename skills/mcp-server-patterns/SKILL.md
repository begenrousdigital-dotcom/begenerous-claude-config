---
name: mcp-server-patterns
description: Patterns pour construire ses propres MCP servers (Model Context Protocol) — outil pour exposer des capabilities custom à Claude Code. Utile pour internaliser des workflows BeGenerous récurrents.
---

# MCP Server Patterns

## Quand construire son propre MCP server

✅ **Bons cas d'usage**
- Outil interne qu'on utilise dans plusieurs projets (ex: helpers Edirex)
- Wrapper sur une API privée (CRM custom, dashboards internes)
- Domain-specific actions (ex: "génère un brief de projet BeGenerous")
- Index de connaissance interne (notes, decisions, instincts)

❌ **Mauvais cas d'usage**
- Réinventer ce que les MCPs publics font déjà (Context7, GitHub, Playwright)
- Wrapper trivial autour d'une CLI (utilise Bash directement)
- One-off scripts (utilise `/run` ou un slash command)

## Architecture MCP

```
┌─────────────────┐                    ┌────────────────┐
│  Claude Code    │ ←── stdio/sse ────→│  MCP Server    │
│  (client)       │     JSON-RPC        │  (tools/res.) │
└─────────────────┘                    └────────────────┘
                                              │
                                              ↓
                                       Ressources externes
                                       (API, DB, files...)
```

## Stack recommandé : TypeScript + `@modelcontextprotocol/sdk`

```bash
mkdir my-mcp-server && cd my-mcp-server
pnpm init
pnpm add @modelcontextprotocol/sdk zod
pnpm add -D typescript tsx @types/node
```

### Structure minimale

```
my-mcp-server/
├── src/
│   ├── index.ts          # entry point (stdio)
│   ├── tools/
│   │   ├── search.ts
│   │   └── create.ts
│   └── lib/
│       └── api-client.ts
├── package.json
└── tsconfig.json
```

### Server skeleton

```ts
// src/index.ts
import { Server } from '@modelcontextprotocol/sdk/server/index.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js'
import { z } from 'zod'

const server = new Server(
  {
    name: 'begenerous-internal',
    version: '0.1.0'
  },
  {
    capabilities: { tools: {} }
  }
)

// 1. List tools
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: 'search_instincts',
      description: 'Recherche dans les instincts BeGenerous (~/.claude/instincts)',
      inputSchema: {
        type: 'object',
        properties: {
          query: { type: 'string', description: 'Terme de recherche' },
          project: { type: 'string', description: 'Projet spécifique (optionnel)' }
        },
        required: ['query']
      }
    },
    {
      name: 'create_instinct',
      description: 'Crée un nouvel instinct',
      inputSchema: {
        type: 'object',
        properties: {
          title: { type: 'string' },
          trigger: { type: 'string' },
          action: { type: 'string' },
          confidence: { type: 'number' }
        },
        required: ['title', 'trigger', 'action']
      }
    }
  ]
}))

// 2. Handle calls
server.setRequestHandler(CallToolRequestSchema, async (req) => {
  const { name, arguments: args } = req.params
  
  try {
    switch (name) {
      case 'search_instincts': {
        const result = await searchInstincts(args)
        return { content: [{ type: 'text', text: JSON.stringify(result) }] }
      }
      case 'create_instinct': {
        const result = await createInstinct(args)
        return { content: [{ type: 'text', text: JSON.stringify(result) }] }
      }
      default:
        throw new Error(`Tool inconnu : ${name}`)
    }
  } catch (error) {
    return {
      isError: true,
      content: [{ type: 'text', text: `Erreur : ${error.message}` }]
    }
  }
})

// 3. Start
const transport = new StdioServerTransport()
await server.connect(transport)
```

### Validation avec Zod

```ts
const SearchInstinctsArgs = z.object({
  query: z.string().min(1),
  project: z.string().optional()
})

async function searchInstincts(args: unknown) {
  const parsed = SearchInstinctsArgs.parse(args)  // throw si invalide
  // ...
}
```

## Configuration côté Claude Code

```json
// ~/.claude/mcp.json
{
  "mcpServers": {
    "begenerous-internal": {
      "command": "node",
      "args": ["/Users/greg/Dev/my-mcp-server/dist/index.js"],
      "env": {
        "API_KEY": "..."  // pour APIs externes
      }
    }
  }
}
```

## Patterns courants

### Pattern : wrapper API REST interne

```ts
async function callInternalAPI(endpoint: string, options?: RequestInit) {
  const response = await fetch(`${process.env.API_URL}${endpoint}`, {
    ...options,
    headers: {
      'Authorization': `Bearer ${process.env.API_TOKEN}`,
      'Content-Type': 'application/json',
      ...options?.headers
    }
  })
  
  if (!response.ok) {
    throw new Error(`API ${response.status}: ${await response.text()}`)
  }
  
  return response.json()
}
```

### Pattern : accès filesystem local

```ts
import { readdir, readFile } from 'fs/promises'
import { join } from 'path'
import { homedir } from 'os'

async function searchInstincts({ query, project }: SearchArgs) {
  const baseDir = project
    ? join(homedir(), '.claude/instincts/projects', project)
    : join(homedir(), '.claude/instincts/global')
  
  const files = await readdir(baseDir, { recursive: true })
  const results = []
  
  for (const file of files) {
    if (!file.endsWith('.md')) continue
    const content = await readFile(join(baseDir, file), 'utf-8')
    if (content.toLowerCase().includes(query.toLowerCase())) {
      results.push({ file, snippet: extractSnippet(content, query) })
    }
  }
  
  return results
}
```

### Pattern : ressources (en plus des tools)

```ts
// Exposer des ressources lisibles (vs tools = actions)
server.setRequestHandler(ListResourcesRequestSchema, async () => ({
  resources: [
    {
      uri: 'begenerous://instincts/global',
      name: 'Instincts globaux BeGenerous',
      mimeType: 'text/markdown'
    }
  ]
}))

server.setRequestHandler(ReadResourceRequestSchema, async (req) => {
  if (req.params.uri === 'begenerous://instincts/global') {
    const content = await readGlobalInstincts()
    return {
      contents: [{ uri: req.params.uri, mimeType: 'text/markdown', text: content }]
    }
  }
})
```

## Sécurité

### Risques
- MCP server peut faire **n'importe quoi** sur ta machine (filesystem, réseau, exec)
- Pas de sandboxing par défaut

### Bonnes pratiques

```ts
// ✅ Valider TOUS les inputs avec Zod
const args = Schema.parse(rawArgs)

// ✅ Whitelisting des chemins
const allowedPaths = [join(homedir(), '.claude/instincts')]
if (!allowedPaths.some(p => requestedPath.startsWith(p))) {
  throw new Error('Path interdit')
}

// ✅ Pas de shell exec avec input user
// ❌ exec(`grep ${userQuery} ...`)
// ✅ readFile + filter en JS

// ✅ Rate limiting si appel API tier
// ✅ Logs (mais sans secrets)
```

### MCPs partagés en équipe

Si tu publies un MCP server pour partage :
- Repo public → pas de secret embedded
- Documenter quels env vars sont nécessaires
- Versionner sémantiquement
- Code review obligatoire avant merge

## Debug

```bash
# Lancer en mode debug local
DEBUG=mcp:* node dist/index.js

# Tester avec stdio direct
echo '{"jsonrpc":"2.0","method":"tools/list","id":1}' | node dist/index.js

# Inspector officiel
npx @modelcontextprotocol/inspector node dist/index.js
```

## Idées de MCPs custom pour BeGenerous

1. **`begenerous-knowledge`** : index searchable des decisions/instincts/lessons cross-projects
2. **`myappix-projects`** : status des projets clients (Edirex, RealEstimate, BrickInvest) avec deploy state
3. **`brand-assets`** : générer/lister assets visuels (Ignition gradient, logos, mockups)
4. **`commercial-templates`** : templates de propositions commerciales avec calcul automatique
5. **`design-references`** : index des refs de design (Stripe, Linear, Cal.com, Vast)

## Anti-patterns

### ❌ MCP qui dupliquer un MCP public
Pourquoi un MCP "github" custom quand le officiel marche ? → Contribuer au public.

### ❌ MCP "kitchen sink"
Un MCP avec 50 tools devient impossible à débugger. Préférer plusieurs petits MCPs ciblés.

### ❌ Pas de versioning
```json
{ "name": "my-mcp", "version": "0.1.0" }
```
Bumper à chaque breaking change. Sinon impossible à maintenir entre devs.

### ❌ Output non structuré
```ts
return { content: [{ type: 'text', text: 'OK' }] }  // ❌ inutilisable
return { content: [{ type: 'text', text: JSON.stringify({status: 'ok', id: '...'}) }] }  // ✅
```
