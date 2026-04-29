---
name: security-scan
description: Audit de sécurité périodique sur la config Claude Code, le code applicatif, les secrets, les permissions, les hooks, les MCPs. À lancer mensuellement ou avant un déploiement majeur. Inspiré d'AgentShield (ECC).
---

# Security Scan

## Périmètre

Ce skill couvre 5 domaines :
1. **Secrets** — clés API, tokens, mots de passe en clair
2. **Permissions** — RLS Supabase, policies Stripe, scopes OAuth
3. **Hooks injection** — hooks Claude Code qui pourraient être exploités
4. **MCP risk** — MCP servers avec accès trop large
5. **Agent configs** — agents avec tools dangereux

## Workflow

### 1. Secrets scan

```bash
# Recherche secrets hardcodés
rg -i "(api[_-]?key|secret|token|password|stripe[_-]?sk|sk_live|sk_test)\s*[:=]\s*['\"]" \
  --type ts --type tsx --type js --type jsx \
  --glob '!node_modules' \
  --glob '!.next'

# Patterns courants à chercher
rg "sk_live_[a-zA-Z0-9]{20,}" .  # Stripe live secret
rg "ghp_[a-zA-Z0-9]{36}" .        # GitHub personal token
rg "AKIA[0-9A-Z]{16}" .           # AWS access key
rg "eyJ[a-zA-Z0-9_-]{20,}\." .    # JWT (peut être OK ou pas)
```

Vérifier `.env`, `.env.local`, `.env.production` :
```bash
# Aucun secret ne doit être committé
git log --all --full-history -- .env*
```

### 2. Permissions / RLS

```sql
-- Tables sans RLS
SELECT schemaname, tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename NOT IN (
    SELECT tablename FROM pg_policies WHERE schemaname = 'public'
  );

-- Policies trop permissives (USING true)
SELECT tablename, policyname
FROM pg_policies
WHERE schemaname = 'public'
  AND qual = 'true';

-- Tables avec policies mais RLS désactivée
SELECT t.tablename
FROM pg_tables t
JOIN pg_class c ON c.relname = t.tablename
WHERE t.schemaname = 'public'
  AND NOT c.relrowsecurity
  AND EXISTS (SELECT 1 FROM pg_policies WHERE tablename = t.tablename);
```

### 3. Claude Code config security

```bash
# Hooks qui peuvent exécuter du code arbitraire
cat ~/.claude/hooks/hooks.json | jq '.hooks[] | select(.command | test("rm |curl |wget |chmod "))'

# Settings : check dangereux
cat ~/.claude/settings.json | jq '
  if .env | has("ANTHROPIC_API_KEY") then 
    "⚠️ API key in settings.json"
  else . end
'

# MCP servers avec accès large
cat ~/.claude/mcp.json | jq '.mcpServers | to_entries[] | select(.value.env | objects)'
```

### 4. Permissions Stripe (si applicable)

```bash
# Lister les API keys actives
stripe keys list

# Webhook endpoints (vérifier qu'ils ont signing secret)
stripe webhook_endpoints list

# Restricted keys recommandées vs full secret
# https://dashboard.stripe.com/apikeys/create
```

### 5. Vercel / production env vars

```bash
# Lister env vars (sans les valeurs)
vercel env ls

# Vérifier scopes
# Les ANTHROPIC_API_KEY, STRIPE_SECRET_KEY ne doivent JAMAIS être en preview
```

## Checklist sécurité Next.js + Supabase

### Auth
- [ ] `auth.uid()` utilisé partout côté serveur (jamais user-provided ID)
- [ ] Session cookies en `httpOnly`, `secure`, `sameSite=lax`
- [ ] Refresh token rotation activée
- [ ] Email verification obligatoire pour actions critiques
- [ ] Rate limiting sur endpoints d'auth (`/api/auth/login`, signup, password reset)

### API Routes
- [ ] Validation Zod sur **tous** les inputs
- [ ] Auth check au début de chaque handler
- [ ] CORS configuré si nécessaire (pas `*` en prod)
- [ ] Rate limiting (Upstash, Vercel KV, ou middleware custom)
- [ ] Pas de stack traces exposées en prod (`NODE_ENV=production`)

### Frontend
- [ ] Pas de `dangerouslySetInnerHTML` sans sanitize (DOMPurify)
- [ ] CSP headers configurés (`next.config.ts` `headers()`)
- [ ] Pas de credentials/tokens en localStorage (utiliser cookies httpOnly)
- [ ] HTTPS only en prod (`secure: true` cookies)

### Supabase
- [ ] RLS activée sur toutes les tables `public`
- [ ] Service role key uniquement utilisée côté serveur
- [ ] Storage buckets : policies cohérentes
- [ ] Edge Functions vérifient JWT valide
- [ ] Realtime channels filtrent via RLS (pas côté client)

### Stripe
- [ ] Webhook signature verification (`stripe.webhooks.constructEvent`)
- [ ] Idempotency keys sur toutes les charges
- [ ] Pas de prix calculés côté client (toujours côté serveur)
- [ ] Customer portal pour les self-service (pas de UI custom de modif facturation)

### Dépendances
- [ ] `pnpm audit` : 0 vulnerability HIGH/CRITICAL
- [ ] Dépendances à jour (deps majeures < 6 mois retard)
- [ ] Pas de deps abandonnées (last release > 1 an)

## Format de rapport

```markdown
## Security Scan — [date]

### 🔴 Critical (X findings)
1. **Secret en clair** — `src/lib/stripe.ts:5`
   Stripe secret key hardcodée. Migrer vers env var immédiatement.
   ```ts
   // ❌
   const stripe = new Stripe('sk_live_xxxxx')
   // ✅
   const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!)
   ```

2. **RLS manquante** — table `public.private_documents`
   Table accessible à tous les users authentifiés.

### 🟠 High (X findings)
- [...]

### 🟡 Medium (X findings)
- [...]

### 🔵 Info / Suggestions (X findings)
- [...]

### Résumé
- Tables sans RLS : 0/19
- Secrets hardcodés : 0
- Vulnérabilités HIGH/CRITICAL deps : 0
- Hooks dangereux : 0
- MCP servers à risque : 0

### Recommandations
1. [...]
2. [...]

### Score global : A | B | C | D | F
```

## Outils complémentaires

- **AgentShield** : `npx ecc-agentshield scan` (audit config Claude Code)
- **Snyk** : audit deps automatique (intégration GitHub)
- **Dependabot** : updates automatiques (configuré dans `.github/dependabot.yml`)
- **Stripe CLI** : `stripe webhooks list` pour vérifier les endpoints
- **Supabase CLI** : `supabase db lint` (basique mais utile)

## Fréquence recommandée

| Type | Fréquence |
|---|---|
| Secrets scan | Pre-commit hook (chaque commit) |
| RLS audit | Avant chaque push migration |
| Deps audit | Hebdomadaire (CI) |
| Full security scan | Mensuel |
| Pentest externe | Annuel ou avant lancement public |

## Configuration dans CLAUDE.md

```markdown
## Security
- Avant d'exposer une API publique : audit complet de l'endpoint
- Toute mutation de DB nécessite auth check ET validation Zod
- Aucun secret en clair dans le code (toujours env var)
- RLS Supabase activée sur toute nouvelle table dans la même migration
- Webhooks Stripe : signature verification obligatoire
```
