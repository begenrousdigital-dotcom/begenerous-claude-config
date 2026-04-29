---
name: backend-patterns
description: Patterns backend avec Next.js Route Handlers, Server Actions, Supabase, Stripe webhooks, queues, caching. Référence rapide pour le côté serveur.
---

# Backend Patterns

## Couches d'architecture

```
┌─────────────────────────────────────┐
│ Route Handler / Server Action       │  ← entry point
├─────────────────────────────────────┤
│ Validation (Zod)                    │
├─────────────────────────────────────┤
│ Auth check (Supabase)               │
├─────────────────────────────────────┤
│ Service layer (business logic)      │  ← réutilisable
├─────────────────────────────────────┤
│ Repository (DB queries)             │  ← Supabase client
├─────────────────────────────────────┤
│ Database (Postgres + RLS)           │
└─────────────────────────────────────┘
```

## Pattern : Route Handler complet

```ts
// app/api/quotes/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { createClient } from '@/lib/supabase/server'
import { createQuote } from '@/lib/services/quotes'

export const runtime = 'nodejs'  // ou 'edge'
export const preferredRegion = 'fra1'

const Body = z.object({
  serviceRequestId: z.string().uuid(),
  amount: z.number().positive().max(100_000),
  description: z.string().min(10).max(2000)
})

export async function POST(req: NextRequest) {
  try {
    // 1. Auth
    const supabase = await createClient()
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Non authentifié' }, { status: 401 })
    }
    
    // 2. Validation
    const body = await req.json()
    const parsed = Body.safeParse(body)
    
    if (!parsed.success) {
      return NextResponse.json(
        { error: 'Validation', details: parsed.error.flatten() },
        { status: 400 }
      )
    }
    
    // 3. Business logic (service)
    const result = await createQuote(supabase, user.id, parsed.data)
    
    if (!result.success) {
      return NextResponse.json({ error: result.error }, { status: 400 })
    }
    
    // 4. Réponse
    return NextResponse.json({ data: result.data }, { status: 201 })
  } catch (error) {
    console.error('POST /api/quotes', error)
    return NextResponse.json({ error: 'Erreur serveur' }, { status: 500 })
  }
}
```

## Pattern : Service layer (réutilisable)

```ts
// lib/services/quotes.ts
import type { SupabaseClient } from '@supabase/supabase-js'

interface CreateQuoteInput {
  serviceRequestId: string
  amount: number
  description: string
}

interface CreateQuoteResult {
  success: boolean
  data?: { id: string }
  error?: string
}

export async function createQuote(
  supabase: SupabaseClient,
  userId: string,
  input: CreateQuoteInput
): Promise<CreateQuoteResult> {
  // Vérifier que user est artisan
  const { data: artisan } = await supabase
    .from('artisans')
    .select('id, status')
    .eq('user_id', userId)
    .single()
  
  if (!artisan) {
    return { success: false, error: 'Utilisateur non artisan' }
  }
  
  if (artisan.status !== 'verified') {
    return { success: false, error: 'Artisan non vérifié' }
  }
  
  // Vérifier service request existe et accepte les devis
  const { data: request } = await supabase
    .from('service_requests')
    .select('id, status, accepts_quotes_until')
    .eq('id', input.serviceRequestId)
    .single()
  
  if (!request || request.status !== 'open') {
    return { success: false, error: 'Demande non disponible' }
  }
  
  if (request.accepts_quotes_until && new Date(request.accepts_quotes_until) < new Date()) {
    return { success: false, error: 'Délai de soumission dépassé' }
  }
  
  // Créer le devis
  const { data, error } = await supabase
    .from('quotes')
    .insert({
      service_request_id: input.serviceRequestId,
      artisan_id: artisan.id,
      amount: input.amount,
      description: input.description,
      expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
    })
    .select('id')
    .single()
  
  if (error) {
    console.error('createQuote DB error', error)
    return { success: false, error: 'Erreur DB' }
  }
  
  return { success: true, data: { id: data.id } }
}
```

## Pattern : Stripe webhook

```ts
// app/api/webhooks/stripe/route.ts
import { headers } from 'next/headers'
import Stripe from 'stripe'
import { NextResponse } from 'next/server'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!)
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET!

export async function POST(req: Request) {
  const body = await req.text()
  const headerStore = await headers()
  const signature = headerStore.get('stripe-signature')!
  
  let event: Stripe.Event
  
  try {
    event = stripe.webhooks.constructEvent(body, signature, webhookSecret)
  } catch (err) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 })
  }
  
  // Idempotency : check si déjà traité
  const alreadyProcessed = await checkIdempotency(event.id)
  if (alreadyProcessed) {
    return NextResponse.json({ received: true, idempotent: true })
  }
  
  try {
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object
        await handleCheckoutCompleted(session)
        break
      }
      case 'invoice.payment_failed': {
        const invoice = event.data.object
        await handlePaymentFailed(invoice)
        break
      }
      // ... autres events
      default:
        console.log(`Stripe event non géré: ${event.type}`)
    }
    
    // Marquer comme traité
    await markEventProcessed(event.id)
    
    return NextResponse.json({ received: true })
  } catch (error) {
    console.error('Stripe webhook handler error', error)
    // Retourner 500 → Stripe retry automatique
    return NextResponse.json({ error: 'Handler failed' }, { status: 500 })
  }
}
```

## Pattern : caching avec `unstable_cache`

```ts
// lib/cache/products.ts
import { unstable_cache } from 'next/cache'
import { createClient } from '@/lib/supabase/server'

export const getCachedProducts = unstable_cache(
  async (categoryId: string) => {
    const supabase = await createClient()
    const { data } = await supabase
      .from('products')
      .select('*')
      .eq('category_id', categoryId)
    return data ?? []
  },
  ['products-by-category'],
  {
    revalidate: 3600,  // 1 heure
    tags: ['products', `category-${0}`]  // tags pour invalidation
  }
)

// Invalider après mutation
import { revalidateTag } from 'next/cache'

export async function invalidateProducts(categoryId?: string) {
  if (categoryId) {
    revalidateTag(`category-${categoryId}`)
  } else {
    revalidateTag('products')
  }
}
```

⚠️ `unstable_cache` ne doit pas contenir d'auth (cache global, pas par user).

## Pattern : pagination cursor-based

```ts
// lib/services/list-quotes.ts
export async function listQuotes(
  supabase: SupabaseClient,
  artisanId: string,
  cursor?: string,
  limit = 20
) {
  let query = supabase
    .from('quotes')
    .select('id, amount, status, created_at')
    .eq('artisan_id', artisanId)
    .order('created_at', { ascending: false })
    .order('id', { ascending: false })  // tiebreaker
    .limit(limit + 1)  // +1 pour savoir s'il y a une next page
  
  if (cursor) {
    const [createdAt, id] = cursor.split('|')
    query = query.or(`created_at.lt.${createdAt},and(created_at.eq.${createdAt},id.lt.${id})`)
  }
  
  const { data, error } = await query
  if (error) throw error
  
  const hasMore = data.length > limit
  const items = hasMore ? data.slice(0, -1) : data
  const nextCursor = hasMore && items.length > 0
    ? `${items[items.length - 1].created_at}|${items[items.length - 1].id}`
    : null
  
  return { items, nextCursor }
}
```

## Rate limiting

### Avec Upstash Redis (le plus simple)

```ts
// lib/rate-limit.ts
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

export const rateLimiter = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '60 s'),  // 10 requests / 60s
  analytics: true
})

// Utilisation
export async function POST(req: NextRequest) {
  const ip = req.headers.get('x-forwarded-for') ?? 'unknown'
  const { success } = await rateLimiter.limit(ip)
  
  if (!success) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }
  
  // ...
}
```

## Background jobs / queues

Pour Vercel + Next.js, options selon la complexité :

### Trigger.dev (recommandé pour la plupart des cas)
```ts
import { task } from '@trigger.dev/sdk/v3'

export const sendQuoteNotification = task({
  id: 'send-quote-notification',
  run: async (payload: { quoteId: string }) => {
    // Logic en background, retries automatiques
  }
})
```

### Inngest (alternative)
Workflows complexes avec étapes, fan-out, etc.

### Cron jobs Vercel (simple)
```ts
// app/api/cron/cleanup/route.ts
export async function GET(req: Request) {
  if (req.headers.get('authorization') !== `Bearer ${process.env.CRON_SECRET}`) {
    return new Response('Unauthorized', { status: 401 })
  }
  // ...
}

// vercel.json
{
  "crons": [
    { "path": "/api/cron/cleanup", "schedule": "0 2 * * *" }
  ]
}
```

## Anti-patterns

### ❌ Business logic dans les Server Actions
```ts
'use server'
export async function complexBusinessFlow(input) {
  // 200 lignes de logique métier
  // → Devrait être dans un service réutilisable
}
```

### ❌ Auth check oublié
```ts
export async function POST(req: NextRequest) {
  const body = await req.json()
  await db.delete(body.id)  // ⚠️ tout le monde peut tout supprimer
}
```

### ❌ Stripe webhook sans signature verification
```ts
export async function POST(req: Request) {
  const event = await req.json()  // ⚠️ peut être forgé
  // ...
}
```

### ❌ Pas d'idempotency sur webhooks
```ts
// Stripe peut retry → événement traité 2 fois
// Charge facturée 2 fois, email envoyé 2 fois
```

### ❌ N+1 queries en service
```ts
const orders = await getOrders()
for (const order of orders) {
  order.items = await getItems(order.id)  // N queries
}
// → Une seule query avec join
```
