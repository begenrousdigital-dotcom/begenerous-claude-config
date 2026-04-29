# Coding Style — Common

Conventions de code applicables à tous les projets BeGenerous, indépendamment du langage.

## Naming

- **Variables/fonctions** : `camelCase` en JS/TS, `snake_case` en SQL/Python
- **Constantes** : `SCREAMING_SNAKE_CASE`
- **Classes/Types** : `PascalCase`
- **Fichiers** : `kebab-case.ts` (sauf composants React : `PascalCase.tsx`)
- **Booléens** : préfixe `is`, `has`, `can`, `should` (`isLoading`, `hasError`, `canEdit`)
- Pas d'abréviations cryptiques (`usr`, `cfg`, `mgr`) — utiliser le nom complet

## Lisibilité avant brièveté

- Une fonction qui fait 1 chose, nommée explicitement
- < 50 lignes par fonction (signal d'alarme au-delà)
- < 4 niveaux d'indentation (sortir tôt avec early returns)
- Un fichier = un sujet (pas de "utils.ts" fourre-tout)

## Comments

- ✅ Commenter le **pourquoi** (intention, contexte, contraintes externes)
- ❌ Pas commenter le **quoi** (le code doit le dire lui-même)
- TODO/FIXME avec ticket associé : `// TODO(EDIREX-123): handle multi-tenant case`

## Magic values

- Pas de magic numbers/strings
- Extraire en constantes nommées :
  ```ts
  // ❌
  if (status === 3) { ... }
  
  // ✅
  const QUOTE_STATUS_REJECTED = 3
  if (status === QUOTE_STATUS_REJECTED) { ... }
  ```

## Errors

- **Throw early** sur les invariants violés
- **Catch tard** : seulement quand on peut faire quelque chose de utile
- Jamais `catch (e) {}` silencieux
- Toujours typer les erreurs custom :
  ```ts
  class ValidationError extends Error {
    constructor(public field: string, public reason: string) {
      super(`${field}: ${reason}`)
    }
  }
  ```

## DRY vs WET

- DRY : Don't Repeat Yourself — pour la **logique métier**
- WET : Write Everything Twice — pour le **code accidental similaire**

Règle pratique : **3 répétitions** = extraire. Avant, c'est prématuré.

## Formatting

- Auto-formatting via Prettier / Biome / `gofmt` / `black`
- Configuration committée à la racine (`.prettierrc`, `biome.json`)
- Hook pre-commit pour formatting automatique

## Imports

```ts
// 1. External libs
import { useState } from 'react'
import { z } from 'zod'

// 2. Internal absolutes (path aliases)
import { Button } from '@/components/ui/button'
import { createClient } from '@/lib/supabase/server'

// 3. Internal relatives
import { localHelper } from './helper'

// 4. Types (séparés)
import type { Quote } from '@/types'
```

Trier alphabétiquement dans chaque groupe.

## Tests

- Test = documentation exécutable
- Naming : `describe('subject', () => { it('should do X when Y', ...) })`
- Arrange / Act / Assert clairement séparés
- Un test = un comportement testé (pas de cascade de assertions sur 5 features)

## Commits

- Conventional commits : `<type>(<scope>): <description>`
- Types : `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`
- Description en français OK, mais consistant dans un projet
- Body : pourquoi du changement (pas le quoi, le diff le dit)
