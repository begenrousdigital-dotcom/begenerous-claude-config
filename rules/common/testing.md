# Testing

## Pyramid

```
       /\
      /E2\          10-20 tests
     /----\
    /  IT  \        50-100 tests
   /--------\
  /   UNIT   \      200+ tests
 /____________\
```

- **Unit** : fonctions pures, helpers, transformers
- **Integration** : services, API handlers, DB queries
- **E2E** : parcours critiques bout-en-bout

## Quand écrire des tests

### ✅ Toujours
- Logique métier non triviale (calculs, parsing, matching)
- Bug fix : ajouter le test qui aurait dû l'attraper
- Code touchant l'argent (paiements, calculs de prix, commissions)
- Code de sécurité (auth, permissions, validation)
- API publique (contracts à respecter)

### 🟡 Selon contexte
- Composants UI : tester comportement, pas l'apparence
- Hooks custom : si non triviaux
- Server Actions : tester validation + permissions

### ❌ Pas la peine
- Code purement de présentation (un texte affiché)
- Wrappers triviaux autour d'une lib
- Code généré (types DB, etc.)

## Stack recommandé (Next.js)

- **Vitest** : unit + integration (rapide, ESM-friendly)
- **Testing Library** : composants React
- **Playwright** : E2E
- **MSW** : mock API calls
- **Faker** : data réaliste

## Patterns

### Unit test type
```ts
// lib/matching.test.ts
import { describe, it, expect } from 'vitest'
import { matchArtisans } from './matching'

describe('matchArtisans', () => {
  it('should return up to 3 artisans matching the criteria', () => {
    const artisans = [/* fixtures */]
    const request = { canton: 'VD', service: 'plumbing' }
    
    const result = matchArtisans(artisans, request)
    
    expect(result).toHaveLength(3)
    expect(result.every(a => a.canton === 'VD')).toBe(true)
  })
  
  it('should return empty array if no match', () => {
    const result = matchArtisans([], { canton: 'VD', service: 'plumbing' })
    expect(result).toEqual([])
  })
})
```

### Integration test (avec Supabase local)
```ts
import { createClient } from '@/lib/supabase/server'
import { createQuote } from './service'

describe('createQuote', () => {
  beforeEach(async () => {
    await seedTestData()
  })
  
  afterEach(async () => {
    await cleanupTestData()
  })
  
  it('should reject if artisan not verified', async () => {
    const supabase = createClient(/* test config */)
    const result = await createQuote(supabase, 'unverified-user-id', {...})
    
    expect(result.success).toBe(false)
    expect(result.error).toMatch(/non vérifié/i)
  })
})
```

### E2E test (voir skill e2e-testing pour détails)

## Coverage

- **Cible générale** : 70-80% sur le code applicatif
- **Cible critique** (paiement, auth) : 95%+
- Coverage est un **outil**, pas un **objectif**. 100% mal couvrant ≠ bien testé.

```bash
pnpm test --coverage
```

## Anti-patterns

### ❌ Tests qui testent l'implémentation
```ts
expect(component.state.foo).toBe(true)  // fragile au refactor
expect(spy).toHaveBeenCalledWith(...)   // implementation detail
```
→ Tester le **comportement** (input → output, événements → effets visibles).

### ❌ Tests partagent l'état
```ts
let user
beforeAll(async () => { user = await createUser() })

it('test 1', () => { user.foo = 'bar' })  // mute user
it('test 2', () => { expect(user.foo).toBe(...) })  // dépend de test 1
```
→ Setup/teardown par test.

### ❌ Tests trop longs
Un test > 30 lignes : probablement teste plusieurs choses, à splitter.

### ❌ Snapshots géants
Snapshots > 50 lignes deviennent du bruit. Personne ne lit le diff. Préférer des assertions ciblées.

### ❌ Mocks trop intrusifs
Si tu dois mocker 10 modules pour tester une fonction, c'est que la fonction a trop de dépendances. Refactor avant tester.
