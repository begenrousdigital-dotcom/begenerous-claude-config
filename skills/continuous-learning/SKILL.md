---
name: continuous-learning
description: Système d'apprentissage continu basé sur des "instincts" — patterns observés et validés au fil des sessions. Capture automatiquement les leçons apprises, les anti-patterns rencontrés, les solutions récurrentes. À la fin d'une session, suggère d'extraire les patterns vers des skills réutilisables.
---

# Continuous Learning

## Quand utiliser ce skill

- Fin d'une session de coding où tu as résolu un problème non-trivial
- Quand tu te dis "je vais retomber sur ce problème dans 2 mois"
- Quand un pattern se répète dans tes projets (Edirex, RealEstimate, BrickInvest, etc.)
- Avant de lancer `/clear` ou de fermer une session productive

## Concept : les instincts

Un **instinct** = pattern observé + confiance + contexte.

Format minimal :

```yaml
id: nextjs-supabase-rls-on-create
trigger: "Création d'une nouvelle table Supabase"
action: |
  Toujours ajouter dans la même migration :
  1. ENABLE ROW LEVEL SECURITY
  2. Au moins une policy SELECT
  3. Index sur les colonnes de filtre RLS
evidence:
  - "Edirex V2 - 2026-01-15 : table service_requests sans RLS = data leak en preview"
  - "RealEstimate - 2026-02-03 : oubli RLS sur properties = same incident"
confidence: 0.95
projects: [edirex-v2, realestimate, brickinvest]
created_at: 2026-01-15
last_validated: 2026-04-20
```

## Workflow

### 1. Pendant la session : noter les "aha moments"

Quand tu rencontres :
- Un bug subtil que tu as mis du temps à diagnostiquer
- Une solution élégante à un problème récurrent
- Un anti-pattern qui t'a fait perdre du temps
- Un comportement non-évident d'une lib (Next.js, Supabase, Stripe...)

→ Le mentionner explicitement : "À retenir : [observation]"

### 2. Fin de session : extraction

Lancer `/learn` (commande fournie). Le système :
1. Scanne la conversation pour les "À retenir" + diff git de la session
2. Génère 3-5 instincts candidats
3. Te les présente pour validation
4. Les sauvegarde dans `~/.claude/instincts/`

### 3. Application : injection au démarrage

Au démarrage d'une nouvelle session (via hook `SessionStart`) :
1. Charger les instincts du projet courant
2. Les injecter dans le contexte
3. Claude les utilise comme heuristiques

### 4. Évolution : promotion en skill

Quand un instinct atteint :
- Confiance > 0.9
- Validé sur 3+ projets différents
- Stable depuis 3+ mois

→ Lancer `/evolve` qui le transforme en skill formel.

## Structure de fichiers

```
~/.claude/instincts/
├── global/                      # Instincts cross-projects
│   ├── git-workflow.md
│   ├── supabase-rls.md
│   └── nextjs-server-actions.md
├── projects/                    # Instincts spécifiques projet
│   ├── edirex-v2/
│   │   ├── matching-algorithm.md
│   │   └── tier-2-2-stage-timing.md
│   └── realestimate/
│       └── google-indexing-api.md
└── pending/                     # Instincts non encore validés
    └── ...
```

## Format d'un instinct

```markdown
---
id: stable-slug
title: Titre court (5-10 mots)
trigger: Quand activer cet instinct
confidence: 0.85
projects: [edirex-v2, realestimate]
created: 2026-04-29
last_validated: 2026-04-29
status: active | pending | archived
---

# [Titre]

## Action
[Que faire concrètement, en 3-5 lignes]

## Pourquoi
[L'origine du pattern : quel bug ou problème a généré cet instinct]

## Exemples concrets
1. [Cas spécifique avec date/projet]
2. [Cas spécifique avec date/projet]

## Anti-pattern à éviter
[Le mauvais réflexe que cet instinct corrige]
```

## Commandes associées

- `/instinct-status` — voir tous les instincts actifs avec leur confiance
- `/instinct-import <fichier.md>` — importer un instinct partagé par un autre dev
- `/instinct-export` — exporter tes instincts pour partage
- `/evolve` — clusteriser des instincts en skill formel
- `/prune` — supprimer les instincts pending non confirmés (TTL 30j)

## Configuration

Dans `~/.claude/CLAUDE.md`, ajouter :

```markdown
## Continuous Learning
- Instincts sont chargés automatiquement au démarrage de session
- Si un instinct s'applique, le mentionner explicitement
- Format : "💡 Instinct activé : [titre] — [action]"
- Si tu observes un nouveau pattern, le suggérer en fin de session
```

## Anti-patterns

- ❌ Créer un instinct pour un bug spécifique non récurrent (c'est un fix, pas un pattern)
- ❌ Instinct trop large ("toujours bien coder") — inutilisable
- ❌ Garder des instincts contradictoires (faire ménage périodiquement avec `/prune`)
- ❌ Importer aveuglément les instincts d'autres devs sans valider sur ton projet
