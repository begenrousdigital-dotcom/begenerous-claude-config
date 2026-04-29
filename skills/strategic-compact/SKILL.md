---
name: strategic-compact
description: Suggère le moment optimal pour lancer /compact au lieu d'attendre l'auto-compaction à 95%. Préserve la qualité du contexte sur les longues sessions en compactant aux breakpoints logiques.
---

# Strategic Compact

## Pourquoi

L'auto-compaction de Claude Code se déclenche à 95% du context window. À ce stade :
- Tu es au milieu d'une tâche
- Le compactage perd des détails critiques (variable names, file paths, partial state)
- Tu redémarres avec un résumé pauvre

**Solution :** compacter **proactivement** aux breakpoints logiques, quand le contexte est consolidé et le résumé sera de qualité.

## Quand compacter (✅)

### Après recherche/exploration, avant implémentation
> Tu viens de comprendre comment Stripe gère les subscriptions metered, tu sais quel approach prendre. → `/compact` pour purger les 50 fichiers Stripe lus.

### Après un milestone, avant le suivant
> Phase 1 d'Edirex (auth + dashboards) terminée. → `/compact` avant d'attaquer Phase 2 (matching algorithm).

### Après debugging, avant de continuer la feature
> Tu as résolu le bug de hydration. → `/compact` pour repartir clean sur la feature en cours.

### Après une approche échouée, avant nouvelle tentative
> Tentative de migration via Drizzle a échoué, tu repars sur les migrations Supabase natives. → `/compact` pour ne pas porter les détails de l'échec.

### Après une longue lecture de docs externes
> Tu viens de lire 30 pages de doc Vercel pour comprendre les Edge Functions. → `/compact`, ne garde que la conclusion.

## Quand NE PAS compacter (❌)

### En milieu d'implémentation
Tu vas perdre :
- Les noms de variables que tu utilisais
- Les chemins de fichiers en cours d'édition
- L'état partiel de ton refactor
- Les decisions implicites que tu venais de prendre

→ Termine l'étape, commit, **puis** compacte.

### Pendant un debug actif
Tu vas perdre les hypothèses testées et les pistes éliminées. Risque de re-tester ce qui ne marche pas.

### Quand tu vas commit dans 2 minutes
Inutile, le commit lui-même va matérialiser l'état.

### Si la session est < 50% du context
`/compact` n'a rien à compacter de significatif. Tu perds plus que tu gagnes.

## Pattern de session idéal

```
[Démarrage session]
    ↓
[Exploration : lire fichiers, comprendre stack]
    ↓
🟡 Décision prise → /compact (purge des fichiers explorés)
    ↓
[Plan détaillé]
    ↓
[Implémentation feature A]
    ↓
[Test + commit feature A]
    ↓
🟡 Feature A done → /compact (purge des essais)
    ↓
[Implémentation feature B]
    ↓
[Test + commit feature B]
    ↓
🟡 Fin de session → /compact (préparer reprise propre)
```

## Heuristique automatique

Le hook `strategic-compact` (fourni dans `hooks/`) suggère le compact quand :

1. **Conversation > 50% du context window** ET
2. **Dernier outil utilisé est `Bash` avec succès** (souvent un commit, un test) OU
3. **Aucun fichier édité dans les 5 derniers tours** (phase de réflexion/lecture)

Le hook **suggère** seulement, ne déclenche jamais automatiquement. Tu décides.

## Configuration

Dans `~/.claude/CLAUDE.md` :

```markdown
## Strategic Compact
- À la fin d'une recherche ou d'un milestone, suggère "/compact" 
- Ne suggère JAMAIS de compacter en milieu d'implémentation
- Quand tu suggères, indique brièvement le bénéfice : "/compact maintenant économisera ~30k tokens et gardera l'essentiel"
```

## Combinaison avec d'autres outils

- **`/clear`** (gratuit, instantané) : entre tâches **non liées**. Pas le même usage que `/compact`.
- **`/cost`** : surveiller la consommation. Si tu approches des limites, compacter plus tôt.
- **Hook `memory-persistence`** : sauvegarde le contexte critique entre sessions, complète `/compact`.

## Mesure

Observer la qualité d'une session :
- Combien de tours avant que Claude commence à oublier des décisions prises tôt ?
- Combien de fois tu dois re-fournir du contexte ?

Bon ratio : 1 `/compact` toutes les 30-50 turns dans une session productive.
