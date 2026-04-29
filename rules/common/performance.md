# Performance

## Principe : measure, don't guess

Avant d'optimiser, **mesurer**. La plupart des optimisations prématurées ne servent à rien et compliquent le code.

## Outils de mesure

### Frontend
- Lighthouse / PageSpeed Insights
- Vercel Speed Insights / Analytics
- Chrome DevTools : Performance, Network, Coverage
- Bundle Analyzer : `@next/bundle-analyzer`

### Backend
- Vercel Logs / Observability
- Supabase Dashboard → Database → Query Performance
- `EXPLAIN ANALYZE` sur les queries lentes

## Targets (Core Web Vitals)

| Métrique | Bon | À améliorer | Mauvais |
|---|---|---|---|
| LCP | < 2.5s | 2.5-4s | > 4s |
| INP | < 200ms | 200-500ms | > 500ms |
| CLS | < 0.1 | 0.1-0.25 | > 0.25 |

## Frontend

### Images
- ✅ `next/image` (lazy loading, sizes responsives, WebP/AVIF auto)
- ✅ `priority` sur les images above-the-fold
- ✅ `placeholder="blur"` pour LCP perçu
- ❌ `<img>` natif (pas d'optimisation)

### Fonts
- `next/font` pour auto-host + preload
- Subsets ciblés (`subsets: ['latin']`)
- `display: 'swap'` pour éviter FOIT

### Code splitting
- Server Components par défaut → bundle client minimal
- `next/dynamic` pour gros composants client (modales, charts) :
  ```tsx
  const Chart = dynamic(() => import('./Chart'), { ssr: false })
  ```

### Bundle audit
```bash
ANALYZE=true pnpm build
# Inspect what's heavy in the client bundle
```

Symptômes :
- Bundle > 200kb gzip = à investiguer
- Une lib unique > 50kb = chercher alternative

## Backend

### Cache
- `unstable_cache` pour data publique fréquemment lue
- `revalidateTag` pour invalidation ciblée
- React `cache()` pour dédupliquer dans le même render

### N+1 queries
```ts
// ❌ N+1
for (const order of orders) {
  order.items = await getItems(order.id)
}

// ✅ Single query avec join
const data = await supabase.from('orders').select('*, items(*)')
```

### Pagination
- `LIMIT` toujours présent
- Cursor-based sur grandes tables (> 10k rows)
- OFFSET coûteux : O(n) sur OFFSET élevé

### Indexes
- FK indexées (sinon DELETE/UPDATE = O(n))
- Colonnes en WHERE/ORDER BY fréquent indexées
- Indexes composites dans le bon ordre

### Réponses API
- JSON minimal : pas de `SELECT *`, lister les colonnes
- Compression auto (Vercel le fait)
- Pas de stack trace en prod

## Database (Postgres + Supabase)

### Vérifier les requêtes lentes
```sql
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;
```

### EXPLAIN
```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT ...;
-- Cherche : Seq Scan sur grande table = manque d'index
-- Cherche : Nested Loop avec beaucoup de rows = mauvaise stratégie
```

### Connection pooling
- Vercel + Supabase : utiliser le mode **transaction** pooler (port 6543)
- Edge Functions : pas de connexion persistante, utiliser le pooler

## Edge runtime (Vercel)

- Cold start ~50-200ms (vs ~500ms-1s pour Node)
- Bundle limité à 4MB
- Pas de Node APIs natives
- Idéal pour : auth checks, redirects, simple CRUD, A/B testing
- Pas adapté : ORM lourds, image processing, lib avec deps natives

```ts
// app/api/.../route.ts
export const runtime = 'edge'
export const preferredRegion = 'fra1'  // Frankfurt pour Suisse
```

## Anti-patterns

### ❌ Optimiser sans mesurer
"On va memoizer pour la perf" → souvent inutile, complique le code.

### ❌ useMemo/useCallback partout
Avec React Compiler (R19), souvent inutile. Mesurer avant d'ajouter.

### ❌ "use client" sur tout
Bundle client gonflé. Server Components par défaut.

### ❌ Cacher de la data user-spécifique
```ts
export const revalidate = 3600  // page avec auth
// → Tous les users voient la même page → leak
```

### ❌ Image sans dimensions
```tsx
<img src="..." />  // Layout shift garanti
```

### ❌ Bundle bloat par dépendance unique
Une lib qui amène 200kb pour formater une date → préférer `Intl.DateTimeFormat` natif.
