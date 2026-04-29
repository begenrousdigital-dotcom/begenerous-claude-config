# Next.js Rules

Conventions pour Next.js 15+ avec App Router.

## Architecture

### Server Components par défaut

```tsx
// app/page.tsx — Server Component (default)
export default async function Page() {
  const data = await fetchData()  // direct DB / API access
  return <div>{data.title}</div>
}
```

### Client Components seulement si nécessaire

`'use client'` requis si :
- `useState`, `useReducer`, `useContext`
- Event handlers (`onClick`, `onChange`)
- Browser APIs (`window`, `localStorage`)
- Hooks tiers qui en utilisent

## Routing

### File conventions

```
app/
├── layout.tsx              # layout racine
├── page.tsx                # /
├── loading.tsx             # loading UI
├── error.tsx               # error boundary
├── not-found.tsx           # 404
├── (marketing)/            # group sans impact URL
│   └── about/page.tsx      # /about
├── dashboard/
│   ├── layout.tsx          # nested layout
│   └── page.tsx            # /dashboard
└── [slug]/
    └── page.tsx            # /xxx
```

### Async params (Next.js 15)

```tsx
// ❌ Avant Next.js 15
export default function Page({ params }: { params: { slug: string } }) {
  return <div>{params.slug}</div>
}

// ✅ Next.js 15
export default async function Page({
  params,
}: {
  params: Promise<{ slug: string }>
}) {
  const { slug } = await params
  return <div>{slug}</div>
}
```

### Async cookies/headers

```ts
import { cookies, headers } from 'next/headers'

export async function GET() {
  const cookieStore = await cookies()  // ← await
  const session = cookieStore.get('session')
  
  const headersList = await headers()  // ← await
  const userAgent = headersList.get('user-agent')
}
```

## Data fetching

### Direct dans Server Components

```tsx
async function ProductPage({ params }: Props) {
  const { id } = await params
  const product = await getProduct(id)  // direct DB call
  return <ProductDetails product={product} />
}
```

### Cache opt-in

```ts
// ❌ Pas de cache par défaut en Next.js 15
const data = await fetch('https://api.example.com')

// ✅ Cache explicite
const data = await fetch('https://api.example.com', {
  cache: 'force-cache',
  next: { revalidate: 3600, tags: ['products'] }
})
```

### Parallel quand possible

```tsx
// ✅ Parallèle
const [user, posts] = await Promise.all([
  getUser(id),
  getPosts(id)
])

// ❌ Séquentiel
const user = await getUser(id)
const posts = await getPosts(id)
```

## Server Actions

```ts
// app/actions/quote.ts
'use server'

import { z } from 'zod'
import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'

const Schema = z.object({
  amount: z.number().positive()
})

export async function createQuote(input: unknown) {
  // 1. Auth
  const user = await getUser()
  if (!user) throw new Error('Unauthorized')
  
  // 2. Validation
  const parsed = Schema.safeParse(input)
  if (!parsed.success) return { error: parsed.error.flatten() }
  
  // 3. Mutation
  const result = await createInDb(parsed.data)
  
  // 4. Revalidate
  revalidatePath('/dashboard')
  
  // 5. Redirect (HORS try/catch)
  redirect(`/quotes/${result.id}`)
}
```

⚠️ `redirect()` doit être hors try/catch (utilise une exception interne).

## Route Handlers

```ts
// app/api/quotes/route.ts
import { NextRequest, NextResponse } from 'next/server'

export const runtime = 'nodejs'         // ou 'edge'
export const preferredRegion = 'fra1'   // Frankfurt
export const dynamic = 'force-dynamic'  // pas de cache

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url)
  // ...
  return NextResponse.json({ data })
}

export async function POST(req: NextRequest) {
  const body = await req.json()
  // ...
  return NextResponse.json({ data }, { status: 201 })
}
```

## Metadata

### Statique
```tsx
export const metadata: Metadata = {
  title: 'Edirex — Artisans en Suisse Romande',
  description: '...'
}
```

### Dynamique
```tsx
export async function generateMetadata({ params }): Promise<Metadata> {
  const { slug } = await params
  const post = await getPost(slug)
  return {
    title: post.title,
    description: post.excerpt
  }
}
```

## Loading & Error

### loading.tsx
```tsx
export default function Loading() {
  return <Skeleton />
}
```

### error.tsx (Client Component obligatoire)
```tsx
'use client'

export default function Error({ error, reset }) {
  return (
    <div role="alert">
      <h2>Une erreur est survenue</h2>
      <button onClick={reset}>Réessayer</button>
    </div>
  )
}
```

### Suspense granulaire
```tsx
import { Suspense } from 'react'

export default function Dashboard() {
  return (
    <>
      <Suspense fallback={<StatsSkeleton />}>
        <Stats />
      </Suspense>
      <Suspense fallback={<TableSkeleton />}>
        <Transactions />
      </Suspense>
    </>
  )
}
```

## Images

```tsx
import Image from 'next/image'

<Image
  src="/hero.png"
  alt="Hero"
  width={1200}
  height={600}
  priority  // pour above-the-fold
  placeholder="blur"
  blurDataURL="..."
/>
```

## Fonts

```ts
// app/layout.tsx
import { Geist, Instrument_Serif } from 'next/font/google'

const geist = Geist({ subsets: ['latin'], display: 'swap' })
const instrument = Instrument_Serif({ subsets: ['latin'], weight: '400' })
```

## Anti-patterns

### ❌ 'use client' sur layout sans raison
```tsx
'use client'  // ⚠️ tout le subtree devient client
export default function Layout({ children }) {
  return <div>{children}</div>
}
```

### ❌ Fetch côté client pour data publique
```tsx
'use client'
function Products() {
  const [data, setData] = useState([])
  useEffect(() => { fetch(...).then(setData) }, [])
  // → Server Component avec await direct
}
```

### ❌ Missing async/await sur params
```tsx
export default function Page({ params }) {
  return <div>{params.slug}</div>  // ⚠️ params is Promise en NJS 15
}
```

### ❌ Cache sur page user-spécifique
```tsx
export const revalidate = 3600  // page avec auth
// → Tous les users voient la même page
```

### ❌ Redirect dans try/catch
```ts
try {
  redirect('/x')  // ⚠️ caught by try/catch
} catch (e) {
  // ...
}
```
