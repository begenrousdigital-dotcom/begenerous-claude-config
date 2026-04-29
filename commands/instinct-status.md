---
description: Affiche tous les instincts actifs avec leur niveau de confiance et leur scope (global vs projet)
---

Liste tous les instincts dans `~/.claude/instincts/` (global + projets + pending).

Pour chaque instinct, afficher :
- ID
- Titre
- Confiance (0.0 → 1.0)
- Scope (global / projet)
- Date dernière validation
- Status (active / pending / archived)

Format de sortie :

```
## Instincts globaux (X)
| ID | Titre | Confiance | Validé le |
|---|---|---|---|
| ... | ... | 0.95 | 2026-04-20 |

## Instincts par projet
### edirex-v2 (X)
...

### realestimate (X)
...

## Instincts pending (X)
| ID | Titre | Créé le | TTL |
|---|---|---|---|
| ... | ... | 2026-04-15 | 14j |

## Stats
- Total : X
- Confiance moyenne : 0.XX
- À évoluer en skills (>0.9) : X
- À pruner (pending > 30j) : X
```

Si aucun instinct n'existe encore, suggérer de lancer `/learn` à la fin de la prochaine session productive.
