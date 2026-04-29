# BeGenerous Claude Config

Configuration Claude Code minimaliste optimisée pour le stack BeGenerous Digital : Next.js 15, Supabase, Vercel, Stripe, TypeScript.

Distillation des éléments réellement utiles d'[everything-claude-code](https://github.com/affaan-m/everything-claude-code) (~5% du volume, ~80% de la valeur) + adaptations spécifiques au workflow vibe coder solo.

---

## Philosophie

- **Minimal.** Rien d'inutile. Pas de skills Java/Rust/PHP/Perl.
- **Stack-aware.** Tout est pensé Next.js + Supabase + Vercel.
- **Français first.** Interactions en français.
- **Cohabitation.** Conçu pour cohabiter avec une config Claude Code existante (CLAUDE.md custom, MCPs, hooks sécurité), pas pour l'écraser.

---

## Ce qu'il y a dedans

| Catégorie | Quantité | Détail |
|---|---|---|
| Agents | 8 | planner, architect, code-reviewer, typescript-reviewer, database-reviewer, e2e-runner, build-error-resolver, refactor-cleaner |
| Skills | 14 | continuous-learning, strategic-compact, verification-loop, iterative-retrieval, search-first, nextjs-turbopack, database-migrations, security-scan, frontend-patterns, backend-patterns, api-design, e2e-testing, mcp-server-patterns, documentation-lookup |
| Commands | 9 | /instinct-status, /instinct-import, /instinct-export, /evolve, /prune, /learn, /checkpoint, /verify, /skill-create |
| Rules | 2 packs | common (8 fichiers) + typescript (3 fichiers) |
| Hooks | 2 | memory-persistence, strategic-compact |

---

## Installation

### Option A — Tout installer (overwrite warning)

```bash
git clone https://github.com/<ton-user>/begenerous-claude-config.git
cd begenerous-claude-config
./install.sh
```

Le script demande confirmation avant chaque overwrite.

### Option B — Installation sélective

```bash
# Skills
mkdir -p ~/.claude/skills
cp -r skills/continuous-learning ~/.claude/skills/
cp -r skills/strategic-compact ~/.claude/skills/
# etc.

# Agents
mkdir -p ~/.claude/agents
cp agents/planner.md ~/.claude/agents/

# Rules
mkdir -p ~/.claude/rules
cp -r rules/common ~/.claude/rules/
cp -r rules/typescript ~/.claude/rules/

# Hooks (à merger manuellement avec hooks existants)
# Voir hooks/MERGE-GUIDE.md
```

---

## Token optimization

Ajouter à `~/.claude/settings.json` :

```json
{
  "model": "sonnet",
  "env": {
    "MAX_THINKING_TOKENS": "10000",
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "50",
    "CLAUDE_CODE_SUBAGENT_MODEL": "haiku"
  }
}
```

Switcher vers Opus uniquement quand : architecture complexe, debug profond, raisonnement multi-étapes.

```
/model opus       # Réflexion profonde
/model sonnet     # Default
/clear            # Reset entre tâches non liées
/compact          # Aux breakpoints logiques
/cost             # Monitoring tokens
```

---

## Tier 1 vs Tier 2

**Tier 1 — Must-have** : impact direct sur productivité quotidienne
- continuous-learning, strategic-compact, verification-loop, iterative-retrieval, search-first
- nextjs-turbopack, database-migrations, security-scan
- planner, architect, code-reviewer, typescript-reviewer, database-reviewer
- Hooks memory-persistence + strategic-compact

**Tier 2 — Nice-to-have** : utiles selon contexte
- frontend-patterns, backend-patterns, api-design, e2e-testing
- mcp-server-patterns, documentation-lookup
- e2e-runner, build-error-resolver, refactor-cleaner
- /learn, /checkpoint, /verify, /skill-create

---

## Conventions de nommage

Pour éviter les conflits avec slash commands existants (`/review`, `/debug`, `/deploy`, `/new-project`), tous les commands de ce repo gardent leurs noms d'origine ECC. Les renommer dans `commands/` avant install si conflit.

---

## Contribution

Repo personnel, mais PRs bienvenues si :
- Nouveau pattern Next.js/Supabase éprouvé
- Skill spécifique au stack BeGenerous
- Amélioration des rules typescript

---

## Licence

MIT — fork libre, adapte, partage.
