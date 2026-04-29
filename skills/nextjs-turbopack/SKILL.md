---
name: nextjs-turbopack
description: Patterns spécifiques à Next.js 15+ avec Turbopack — async APIs, Server Components, caching, Server Actions. Évite les pièges de migration depuis Next.js 13/14.
---

# Next.js 15 + Turbopack

## Contexte

Next.js 15 a introduit des changements majeurs vs 14 :
- APIs runtime devenues **async** (`cookies()`, `headers()`, `params`, `searchParams`)
- Cache désactivé par défaut sur `fetch()` et Route Handlers
- React 19 par défaut
- Turbopack stable en dev, pas encore stable en build (config flag)

Cohérence avec ton stack actuel : Next.js 15.x, App Router, Server Components first.

## Async APIs (BREAKING)

### Avant (Next.js 14)
```ts
// ❌ Plus possible en Next.js 15
import { cookies } from 'next/headers'

export async function GET() {
  const session = cookies().get('session')  // ⚠️ Sync API removed
  return Response.json({ session })
}
```

### Maintenant (Next.js 15)
```ts
// ✅ APIs async
import { cookies } from 'next/headers'

export async function GET() {
  const cookieStore = await cookies()
  const session = cookieStore.get('session')
  return Response.json({ session })
}
```

### Page params/searchParams aussi async

```tsx
// app/products/[id]/page.tsx

// ❌ Avant
export default function Page({ params }: { params: { id: string } }) {
  return <div>{params.id}</div>
}

// ✅ Maintenant
export default async function Page({ 
  params 
}: { 
  params: Promise<{ id: string }> 
}) {
  const { id } = await params
  return <div>{id}</div>
}
```

### `useSearchParams` (côté client)
Reste **sync** en Client Components. Seuls les Server Components ont `searchParams` async.

## Cache : opt-in maintenant

### `fetch()` n'est plus caché par défaut

```ts
// ❌ Avant : caché par défaut
const data = await fetch('https://api.example.com/data')

// ✅ Maintenant : explicite
const data = await fetch('https://api.example.com/data', {
  cache: 'force-cache',
  next: { revalidate: 3600 }  // 1h
})
```

### Route Handlers GET non cachés par défaut

```ts
// app/api/products/route.ts

// ❌ Avant : caché statiquement
export async function GET() {
  return Response.json({ products: [...] })
}

// ✅ Maintenant : explicite
export const dynamic = 'force-static'  // ou
export const revalidate = 3600

export async function GET() {
  return Response.json({ products: [...] })
}
```

### `unstable_cache` (toujours utile)
```ts
import { unstable_cache } from 'next/cache'

const getCachedProducts = unstable_cache(
  async (categoryId: string) => {
    return await db.product.findMany({ where: { categoryId } })
  },
  ['products'],  // cache key
  {
    revalidate: 3600,
    tags: ['products', 'category']
  }
)
```

## Server Components patterns

### Data fetching au plus près de la consommation

```tsx
// ✅ Bon : fetch dans le component qui consomme
async function ProductPrice({ productId }: { productId: string }) {
  const price = await getPrice(productId)
  return <span>{price}€</span>
}

// ❌ Mauvais : prop drilling pour passer les données depuis la page
async function Page() {
  const price = await getPrice(...)
  return <ProductPrice price={price} />
}
```

### `cache()` pour dédupliquer dans le même render

```ts
import { cache } from 'react'

// Memoize pendant un seul render Server (pas entre requests)
export const getUser = cache(async (id: string) => {
  return await db.user.findUnique({ where: { id } })
})

// Appelé 5 fois dans la même page = 1 seule query DB
```

### Streaming avec Suspense

```tsx
import { Suspense } from 'react'

export default function Page() {
  return (
    <div>
      <Header />
      <Suspense fallback={<Skeleton />}>
        <SlowDataComponent />
      </Suspense>
    </div>
  )
}
```

## Server Actions

### Pattern complet avec validation

```ts
// app/actions/create-quote.ts
'use server'

import { z } from 'zod'
import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'

const QuoteSchema = z.object({
  serviceRequestId: z.string().uuid(),
  amount: z.number().positive(),
  description: z.string().min(10).max(2000)
})

export async function createQuote(formData: FormData) {
  const supabase = await createClient()
  
  // 1. Auth check
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('Non authentifié')
  
  // 2. Validation
  const parsed = QuoteSchema.safeParse({
    serviceRequestId: formData.get('serviceRequestId'),
    amount: Number(formData.get('amount')),
    description: formData.get('description')
  })
  
  if (!parsed.success) {
    return { error: parsed.error.flatten() }
  }
  
  // 3. Permission check (RLS gère, mais explicit aussi côté code)
  const { data: artisan } = await supabase
    .from('artisans')
    .select('id')
    .eq('user_id', user.id)
    .single()
  
  if (!artisan) throw new Error('Artisan non trouvé')
  
  // 4. Mutation
  const { data, error } = await supabase
    .from('quotes')
    .insert({
      service_request_id: parsed.data.serviceRequestId,
      artisan_id: artisan.id,
      amount: parsed.data.amount,
      description: parsed.data.description
    })
    .select()
    .single()
  
  if (error) return { error: { _form: ['Erreur DB'] } }
  
  // 5. Revalidate
  revalidatePath('/dashboard/quotes')
  revalidatePath(`/service-requests/${parsed.data.serviceRequestId}`)
  
  // 6. Redirect (HORS try/catch !)
  redirect(`/quotes/${data.id}`)
}
```

### Anti-patterns Server Actions

```ts
// ❌ redirect dans try/catch
export async function action() {
  try {
    await doStuff()
    redirect('/success')  // ❌ NEXT_REDIRECT throw caught
  } catch (e) {
    // catch va attraper le redirect
  }
}

// ❌ Pas de validation
export async function action(formData: FormData) {
  const id = formData.get('id') as string  // ⚠️ aucune garantie
  await db.delete(id)  // ⚠️ injection
}

// ❌ Pas de revalidation
export async function action() {
  await db.create({...})
  // UI ne va pas se mettre à jour
}
```

## Turbopack en build (expérimental)

```ts
// next.config.ts
export default {
  experimental: {
    turbo: {
      // Configuration custom
    }
  }
}
```

⚠️ Build Turbopack pas encore 100% stable en avril 2026. Vérifier l'état avant production :
- https://nextjs.org/docs/app/api-reference/turbopack
- Tester `next build --turbo` sur staging avant prod

## Cohabitation Vercel

### Region pour data residency Suisse
```ts
// app/api/.../route.ts
export const runtime = 'edge'  // ou 'nodejs'
export const preferredRegion = 'fra1'  // Frankfurt
```

### Edge Runtime limites
- Pas de Node.js APIs natives (`fs`, `crypto.randomBytes`...)
- Pas de packages avec deps Node natives
- Limite 4MB code, 128MB RAM
- **OK pour** : auth checks, simple CRUD, redirections, A/B testing
- **Pas OK pour** : ORM lourd, image processing, PDF generation

## Migration depuis Next.js 14 — checklist

- [ ] `await` toutes les APIs runtime (`cookies`, `headers`, `params`, `searchParams`)
- [ ] Audit des `fetch()` : ajouter `cache:` ou `revalidate:` explicites
- [ ] Audit des Route Handlers : ajouter `dynamic` ou `revalidate`
- [ ] Test que React 19 ne casse rien (rare, mais quelques edge cases)
- [ ] Vérifier `forwardRef` : refactor pour passer ref comme prop
- [ ] Tester en build : `pnpm build && pnpm start`

## Anti-patterns courants

```tsx
// ❌ Server Component qui devrait être Client (et vice-versa)
'use client'
export function StaticHero() {  // Aucune interactivité
  return <h1>Title</h1>
}

// ❌ Data fetch dans Client Component pour data publique
'use client'
function Products() {
  const [products, setProducts] = useState([])
  useEffect(() => {
    fetch('/api/products').then(r => r.json()).then(setProducts)
  }, [])
  // → Server Component avec await direct
}

// ❌ Cacher de la data utilisateur-spécifique
export const revalidate = 3600  // sur une page avec auth
// La même page sera servie à tous les users → leak de data
```
