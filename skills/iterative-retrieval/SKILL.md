---
name: iterative-retrieval
description: Pattern de récupération progressive du contexte pour éviter de surcharger les subagents. Au lieu de tout lire d'un coup, lire par couches successives selon les besoins. Critique pour les délégations à des subagents avec context window limité.
---

# Iterative Retrieval

## Le problème

Quand tu délègues à un subagent (planner, code-reviewer, etc.), la tentation est de lui donner tout le contexte d'un coup :

```
"Voilà tous les fichiers du projet, fais le code review"
```

Résultat :
- Context window saturé avant même de commencer
- Subagent perdu dans les détails non-pertinents
- Output de mauvaise qualité

## Le pattern

**Récupération en couches**, du plus large au plus précis :

```
Couche 1 : Structure projet (tree, README) — 1k tokens
    ↓
Couche 2 : Index ciblé (grep par mot-clé) — 2k tokens
    ↓
Couche 3 : Fichiers candidats (5-10 fichiers max) — 5-10k tokens
    ↓
Couche 4 : Détails approfondis (relire avec contexte sémantique) — 5k tokens
```

Total : ~15k tokens vs 100k+ en lecture brutale.

## Workflow type

### Exemple : "Trouve où le système d'auth gère la 2FA"

#### Couche 1 — Structure
```bash
tree -L 2 src/ -I 'node_modules|.next'
cat README.md | head -50
```
→ Identification : `src/lib/auth/`, `src/app/api/auth/`

#### Couche 2 — Index
```bash
grep -rln "2fa\|two.factor\|TOTP\|otp" src/ --include="*.ts" --include="*.tsx"
```
→ Liste : 5 fichiers candidats

#### Couche 3 — Lecture ciblée
```bash
# Lire seulement les 5 fichiers
cat src/lib/auth/2fa.ts
cat src/app/api/auth/verify/route.ts
# ...
```
→ Compréhension du flow

#### Couche 4 — Détails si besoin
```bash
# Si question pointue émerge, drill down sur fonction précise
grep -n "verifyTOTP" src/lib/auth/2fa.ts
```

## Application aux subagents

### ❌ Anti-pattern : feed brutal

```typescript
// Mauvais : on dump tout
await taskAgent({
  files: await readAllFiles('src/'),  // 80k tokens
  task: "Review the auth system"
})
```

### ✅ Pattern correct : retrieval progressif

```typescript
// Étape 1 : laisser l'agent demander ce dont il a besoin
const initial = await taskAgent({
  context: "Project structure and README only",
  files: ['README.md', 'src/lib/auth/index.ts'],  // 2k tokens
  task: "List the files you need to review the auth system, by relevance order"
})

// Étape 2 : fournir les fichiers identifiés
const review = await taskAgent({
  context: initial.fileList.slice(0, 5),  // 8k tokens
  task: "Now review the auth system"
})
```

## Quand utiliser

### ✅ À utiliser pour
- Code review d'une partie du projet (pas tout)
- Recherche d'un bug dans une zone large
- Documentation d'une feature existante
- Onboarding d'un nouveau pattern

### ❌ Inutile pour
- Tâches très ciblées (un seul fichier connu)
- Modifications triviales
- Génération de boilerplate

## Heuristiques

### Combien de fichiers en couche 3 ?

```
< 5 fichiers   → lecture directe, pas besoin du pattern
5-15 fichiers  → cas idéal pour iterative retrieval
> 30 fichiers  → re-restreindre la requête (couche 2 pas assez sélective)
```

### Comment écrire un grep efficace en couche 2

```bash
# ❌ Trop large
grep -r "auth" src/

# ✅ Spécifique
grep -rln "verifyMagicLink\|sendOTP\|validateSession" src/
```

Mots-clés candidats :
- Noms de fonctions précis
- Identifiants de tables DB
- Noms de hooks React custom
- Chemins d'URL d'API

### Quand passer en couche 4

Quand tu te dis : "OK, j'ai compris la structure mais pas le pourquoi de cette ligne précise."

## Implémentation pratique

Pour les subagents Claude Code, la pattern se traduit en :

```markdown
## Subagent prompt template

Étape 1 (toi, agent principal) :
"Avant de répondre, liste les fichiers dont tu auras besoin pour cette tâche, classés par pertinence. Format JSON : { files: string[], rationale: string }"

Étape 2 (toi, agent principal) :
Lire les fichiers listés (max 10), puis donner le vrai prompt.
```

## Combinaison avec autres skills

- **search-first** : utilise iterative-retrieval pour explorer le résultat de recherche
- **continuous-learning** : les instincts indiquent souvent où chercher en priorité
- **strategic-compact** : compacter entre les couches si on dépasse 50% du context

## Mesure

Avant : combien de tokens consommés en moyenne pour un code review ? (typiquement 50-100k)

Après iterative retrieval : 15-30k tokens, qualité égale ou meilleure (subagent plus focalisé).
