---
name: verification-loop
description: Boucle de vérification systématique après chaque changement de code — build, lint, typecheck, tests, sécurité. Évite de découvrir 5 erreurs accumulées en fin de session. À activer dès qu'on touche au code.
---

# Verification Loop

## Principe

Après **chaque** modification non-triviale, exécuter une boucle de vérification courte et automatique. Détecter les régressions tôt, pas en fin de session.

## La boucle (4 étapes)

```
1. typecheck    →  pnpm tsc --noEmit          (~5s)
2. lint         →  pnpm lint                  (~10s)
3. test (focus) →  pnpm test [path-modifié]   (~5-30s)
4. build        →  pnpm build                 (~30-60s, optionnel)
```

Total : 20-60s par boucle. À l'échelle d'une session de 4h, ça représente 5-10% du temps mais sauve des heures de debug.

## Quand exécuter

### ✅ Après chaque "unit of work"
- Une fonction complète écrite/modifiée
- Un composant React modifié
- Une migration ajoutée
- Une route API créée
- Un refactor fini

### ✅ Avant chaque commit
Sans exception. Si la boucle échoue, ne pas commit.

### ❌ Pas après chaque caractère tapé
Pas pendant qu'on est en flow d'écriture. À la fin du bloc cohérent.

## Workflow détaillé

### Étape 1 : typecheck (le moins cher, le plus utile)

```bash
pnpm tsc --noEmit
```

Capture :
- Types incohérents
- Imports manquants
- Refactor incomplet (changement signature non propagé)

**Si échec :** corriger avant tout. Un projet qui ne typecheck pas est cassé, point.

### Étape 2 : lint

```bash
pnpm lint
```

Capture :
- Imports inutilisés
- `any` non justifié
- Variables non utilisées
- Patterns React problématiques (clés manquantes, hooks mal utilisés)

**Si échec :** corriger ou ajouter `eslint-disable` avec justification écrite.

### Étape 3 : tests focalisés

```bash
# Tester uniquement les fichiers liés au changement
pnpm test src/lib/matching.ts
# Ou par pattern
pnpm test --run --reporter=verbose
```

**Pas** lancer toute la suite de tests à chaque boucle (trop long). Lancer seulement les tests proches du changement.

### Étape 4 : build (occasionnel)

```bash
pnpm build
```

À lancer :
- Avant un commit majeur
- Après modification de la config (next.config, tsconfig, package.json)
- Après ajout/suppression de dépendance
- Avant un push qui va déclencher Vercel

Capture les erreurs qui n'apparaissent qu'au build (Edge runtime constraints, env vars manquantes, etc.).

## Format de rapport (suite à la boucle)

```markdown
## Verification Loop — [timestamp]

### typecheck ✅
Pass — 0 errors

### lint ✅
Pass — 0 warnings

### tests (3 fichiers) ✅
Pass — 12/12 tests in 2.3s

### build (optionnel)
Skipped — dernier build OK il y a 5min

→ Safe to commit
```

Si erreur :

```markdown
## Verification Loop — FAILED

### typecheck ❌
src/lib/matching.ts:42 — Type 'string' not assignable to 'ContractorId'

### Recommandation
Corriger le type avant de continuer. Le test step ne sera pas exécuté tant que typecheck échoue.
```

## Auto-fix vs investigation

- ✅ **Auto-fix** : prettier, eslint --fix, imports auto-organisés
- ❌ **Pas auto-fix** : type errors, test failures, build errors → investiguer

## Variantes par contexte

### Sur Edirex/Next.js full-stack
```bash
pnpm tsc --noEmit && pnpm lint && pnpm test --run
```

### Sur projet avec Supabase migrations
```bash
# Ajouter avant : tester que la migration s'applique
pnpm supabase db reset --debug
pnpm tsc --noEmit && pnpm test
```

### Avant deploy Vercel
```bash
pnpm build && pnpm test && pnpm tsc --noEmit
# Tester la build complète, pas juste le typecheck
```

## Combinaison avec git hooks

Pour ne pas dépendre de la mémoire, configurer un **pre-commit hook** :

```bash
# .husky/pre-commit
#!/usr/bin/env sh
pnpm tsc --noEmit && pnpm lint --fix && pnpm test --run
```

Cela force la boucle même si on oublie. Vibe coder = on oublie.

## Anti-patterns

- ❌ "Je teste à la fin de la session" → 4h de debug pour démêler 8 bugs imbriqués
- ❌ "Je commit, je verrai en CI" → push-pull cycle de honte sur Vercel
- ❌ Skip typecheck "parce que c'est un petit changement" → c'est exactement quand ça casse
- ❌ `pnpm tsc --noEmit -- --ignoreErrors` (ça n'existe pas, mais le réflexe d'ignorer existe)

## Configuration dans CLAUDE.md

```markdown
## Verification Loop
- Après chaque feature/fix non-trivial : lancer typecheck + lint + tests focalisés
- Si la boucle échoue, fixer avant de continuer
- Avant chaque commit : boucle complète obligatoire
- Ne JAMAIS suggérer "ignoreBuildErrors: true" pour faire passer un build
```
