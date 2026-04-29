# Changelog

Toutes les modifications notables de ce repo sont documentées ici.

Format basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),  
versioning [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Non publié]

### Pistes à explorer
- Skill `stripe-patterns` (idempotency, webhooks, subscriptions metered)
- Skill `realtime-supabase` (channels, presence, broadcast)
- Skill `vercel-edge-patterns` (cold starts, region pinning, ISR)
- Agent `migration-planner` (audit + plan de migration Next.js majeures)
- Command `/instinct-merge` (fusion de deux instincts proches)

---

## [0.1.0] — 2026-04-29

Première version publique. Distillation Tier 1 + Tier 2 d'[everything-claude-code](https://github.com/affaan-m/everything-claude-code) adaptée au stack BeGenerous.

### Added

#### Agents (8)
- `planner` — planification de feature en blueprint exécutable (opus)
- `architect` — décisions de design système structurantes (opus)
- `code-reviewer` — review qualité/sécurité général (sonnet)
- `typescript-reviewer` — review TS/React 19/Next.js 15 spécialisée (sonnet)
- `database-reviewer` — review schémas Supabase, RLS, migrations (sonnet)
- `e2e-runner` — génération et exécution Playwright (sonnet)
- `build-error-resolver` — résolution erreurs de build (sonnet)
- `refactor-cleaner` — détection de code mort, propositions conservatrices (sonnet)

#### Skills Tier 1 (8)
- `continuous-learning` — système d'instincts avec scoring de confiance
- `strategic-compact` — heuristiques pour `/compact` aux moments propices
- `verification-loop` — boucle typecheck/lint/test/build après chaque change
- `iterative-retrieval` — retrieval progressif en 4 couches pour subagents
- `search-first` — research-before-coding workflow (priorité Context7)
- `nextjs-turbopack` — patterns Next.js 15 (async APIs, cache opt-in, Server Actions)
- `database-migrations` — patterns Supabase migrations zéro-downtime
- `security-scan` — audit secrets/RLS/hooks/MCP/agents

#### Skills Tier 2 (6)
- `frontend-patterns` — Server vs Client, state hierarchy, formulaires, a11y
- `backend-patterns` — Route Handlers, services, Stripe webhooks, caching
- `api-design` — REST cohérent, codes HTTP, pagination, versioning, OpenAPI
- `e2e-testing` — Playwright Page Object Model, auth state, smoke tests
- `mcp-server-patterns` — construction de MCP servers TypeScript custom
- `documentation-lookup` — workflow Context7/WebFetch/GitHub pour docs

#### Commands (9)
- `/instinct-status` — état des instincts actifs avec scoring
- `/instinct-import` — import d'un instinct externe (avec reset confiance)
- `/instinct-export` — export anonymisé pour partage
- `/evolve` — promotion d'instincts en skill formel
- `/prune` — nettoyage des instincts pending expirés (TTL 30j)
- `/learn` — extraction d'instincts depuis la session courante
- `/checkpoint` — création d'un point de sauvegarde pour reprise
- `/verify` — lance la verification loop complète
- `/skill-create` — génère un skill depuis l'historique git

#### Rules
- **Common (8)** : coding-style, git-workflow, testing, security, performance, patterns, hooks, agents
- **TypeScript (3)** : style, nextjs, react

#### Hooks
- `load-context.sh` (SessionStart) — charge instincts + dernier checkpoint
- `save-context.sh` (SessionEnd) — sauvegarde résumé de session
- `suggest-compact.sh` (PostToolUse) — suggère `/compact` après un commit
- `MERGE-GUIDE.md` — procédure d'intégration avec hooks sécurité existants

#### Setup
- `install.sh` — script d'installation interactif avec backup automatique
- `settings.template.json` — template avec optimisations tokens (MAX_THINKING_TOKENS=10000, AUTOCOMPACT=50, SUBAGENT=haiku)
- `README.md` — documentation complète

### Optimisations tokens incluses
- Modèle par défaut : `sonnet`
- Subagents : `haiku` (économie 75% sur les sub-tasks)
- Auto-compact à 50% (vs 95% par défaut)
- MCPs ECC désactivés (github, context7, playwright, sequential-thinking, memory) pour éviter doublons

### Stack ciblé
- Next.js 15 (App Router, async APIs, Turbopack)
- Supabase (PostgreSQL + RLS + Realtime + Edge Functions)
- Vercel (région `fra1` pour data residency Suisse)
- Stripe (webhooks idempotency, subscription patterns)
- TypeScript strict (`noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`)
- React 19 (Server Components first, useOptimistic, useFormStatus)

### Cohabitation
Conçu pour cohabiter avec une config Claude Code existante :
- Préserve `~/.claude/CLAUDE.md` custom
- Préserve les hooks de sécurité (block `rm -rf`, `DROP TABLE`, `git push --force`)
- Préserve les MCPs configurés
- Préserve les slash commands existants (`/review`, `/debug`, `/deploy`, `/new-project`)

---

## Format des entrées

Pour les versions futures, utiliser ces sections :

- **Added** — nouvelles fonctionnalités
- **Changed** — modifications du comportement existant
- **Deprecated** — fonctionnalités vouées à disparaître
- **Removed** — fonctionnalités supprimées
- **Fixed** — corrections de bugs
- **Security** — corrections de failles

[Non publié]: https://github.com/begenrousdigital-dotcom/begenerous-claude-config/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/begenrousdigital-dotcom/begenerous-claude-config/releases/tag/v0.1.0
