---
name: frontend-patterns
description: Patterns React 19 + Next.js 15 pour composants, state management, formulaires, data fetching, accessibility. Référence rapide quand on construit une UI.
---

# Frontend Patterns

## Composants : Server vs Client

### Décision en 3 questions

1. Le composant a-t-il besoin de **state** (`useState`) ?
2. A-t-il besoin de **handlers d'événements** (`onClick`, `onChange`) ?
3. Utilise-t-il des **APIs browser** (`window`, `localStorage`, `IntersectionObserver`) ?

→ Si oui à 1+ : **Client Component** (`'use client'`)  
→ Si non à tout : **Server Component** (default)

### Pattern : "îlots" client dans une page server

```tsx
// app/page.tsx (Server Component)
import { ProductGrid } from './ProductGrid'        // Server
import { AddToCartButton } from './AddToCart'      // Client (interactif)

export default async function Page() {
  const products = await fetchProducts()  // Direct DB access
  
  return (
    <div>
      <h1>Produits</h1>
      <ProductGrid products={products}>
        {/* Children Server, mais le bouton est Client */}
        {(product) => <AddToCartButton productId={product.id} />}
      </ProductGrid>
    </div>
  )
}
```

## State management : hiérarchie

```
1. URL state          (useSearchParams, useRouter)
2. Server state       (Server Components, fetchées au render)
3. Local state        (useState pour UI interactive)
4. Form state         (useFormState, react-hook-form)
5. Global state       (Context API, Zustand) — en dernier recours
```

❌ **Ne pas** :
- Mettre du server state en Context (juste re-fetcher côté serveur)
- Mettre des filtres/tri en local state si partageables (utiliser URL state)

✅ **Pattern URL state** :
```tsx
'use client'
import { useSearchParams, useRouter } from 'next/navigation'

export function FilterBar() {
  const params = useSearchParams()
  const router = useRouter()
  
  const updateFilter = (key: string, value: string) => {
    const next = new URLSearchParams(params)
    next.set(key, value)
    router.push(`?${next.toString()}`)
  }
  
  return <select onChange={e => updateFilter('canton', e.target.value)} />
}
```

## Formulaires

### Pattern : Server Action + react-hook-form + Zod

```tsx
// app/quotes/new/page.tsx
'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { createQuote } from './actions'

const Schema = z.object({
  amount: z.coerce.number().positive(),
  description: z.string().min(10).max(2000)
})

type FormData = z.infer<typeof Schema>

export default function QuoteForm() {
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(Schema)
  })
  
  const onSubmit = async (data: FormData) => {
    const result = await createQuote(data)
    if (result?.error) {
      // gérer erreur server (logique custom)
    }
  }
  
  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('amount')} type="number" step="0.01" />
      {errors.amount && <p>{errors.amount.message}</p>}
      
      <textarea {...register('description')} />
      {errors.description && <p>{errors.description.message}</p>}
      
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Envoi...' : 'Soumettre'}
      </button>
    </form>
  )
}
```

### Validation côté serveur (Server Action)

```ts
'use server'
const Schema = z.object({...})  // même schema que client

export async function createQuote(input: unknown) {
  const parsed = Schema.safeParse(input)
  if (!parsed.success) {
    return { error: parsed.error.flatten() }
  }
  // ...
}
```

## Data fetching

### Pattern : composant async qui fetch sa propre data

```tsx
// Bon : data fetchée au plus près
async function UserAvatar({ userId }: { userId: string }) {
  const user = await getUser(userId)
  return <img src={user.avatarUrl} alt={user.name} />
}

// Utilisation
<Suspense fallback={<AvatarSkeleton />}>
  <UserAvatar userId={id} />
</Suspense>
```

### Pattern : parallel data fetching

```tsx
// ✅ Parallèle (les 2 promesses lancées en même temps)
async function Page({ params }) {
  const [user, posts] = await Promise.all([
    getUser(params.id),
    getPosts(params.id)
  ])
  // ...
}

// ❌ Séquentiel (lent)
async function Page({ params }) {
  const user = await getUser(params.id)
  const posts = await getPosts(params.id)
}
```

### Mutation avec optimistic update

```tsx
'use client'
import { useOptimistic } from 'react'

export function LikeButton({ postId, initialLikes }: Props) {
  const [optimisticLikes, addOptimistic] = useOptimistic(
    initialLikes,
    (state, newLike: number) => state + newLike
  )
  
  const handleLike = async () => {
    addOptimistic(1)  // UI updated immediately
    const result = await toggleLike(postId)
    if (!result.success) {
      // rollback automatique au prochain render
    }
  }
  
  return <button onClick={handleLike}>{optimisticLikes} 👍</button>
}
```

## Accessibility (a11y)

### Checklist par composant

#### Boutons
- [ ] `<button>` natif (pas `<div onClick>`)
- [ ] Texte ou `aria-label` si icône seule
- [ ] `disabled` avec feedback visuel + `aria-disabled`

#### Inputs
- [ ] `<label>` associé via `htmlFor`/`id`
- [ ] `aria-describedby` pour message d'erreur
- [ ] `aria-invalid` quand erreur
- [ ] `autocomplete` approprié

#### Modales
- [ ] Focus trap dans la modale
- [ ] `Escape` ferme
- [ ] `role="dialog"` + `aria-modal="true"`
- [ ] Focus rendu au trigger après fermeture

#### Listes / Cards
- [ ] Heading hierarchy (`h1` > `h2` > `h3`, pas de saut)
- [ ] `<ul><li>` pour vraies listes (pas `<div>`)
- [ ] Liens avec texte explicite (pas "cliquez ici")

### Tester
```bash
# axe via Playwright
pnpm test:e2e -- --reporter=html
# Voir le rapport pour findings a11y

# ou avec lighthouse en CI
pnpm dlx @lhci/cli autorun
```

## Loading & error states

### Pattern : `loading.tsx` + `error.tsx`

```
app/
├── dashboard/
│   ├── page.tsx           # Composant principal
│   ├── loading.tsx        # Affiché pendant data fetch
│   └── error.tsx          # Affiché si throw
```

```tsx
// app/dashboard/loading.tsx
export default function Loading() {
  return <DashboardSkeleton />
}

// app/dashboard/error.tsx
'use client'
export default function Error({ error, reset }: { error: Error, reset: () => void }) {
  return (
    <div role="alert">
      <h2>Une erreur est survenue</h2>
      <p>{error.message}</p>
      <button onClick={reset}>Réessayer</button>
    </div>
  )
}
```

### Suspense boundaries granulaires

```tsx
// Au lieu d'une seule loading.tsx pour toute la page
export default function Dashboard() {
  return (
    <>
      <Suspense fallback={<StatsSkeleton />}>
        <Stats />  {/* fetch indépendant */}
      </Suspense>
      
      <Suspense fallback={<TableSkeleton />}>
        <RecentTransactions />  {/* fetch indépendant */}
      </Suspense>
    </>
  )
}
```

## Patterns Tailwind / shadcn-ui

### Composer les classes proprement

```tsx
// ✅ Avec cn() (class-variance-authority + clsx + tailwind-merge)
import { cn } from '@/lib/utils'

<button className={cn(
  'px-4 py-2 rounded',
  variant === 'primary' && 'bg-blue-600 text-white',
  variant === 'ghost' && 'border border-gray-300',
  disabled && 'opacity-50 cursor-not-allowed',
  className  // permet override depuis l'extérieur
)} />
```

### Variants avec CVA

```tsx
import { cva, type VariantProps } from 'class-variance-authority'

const buttonVariants = cva('rounded font-medium transition', {
  variants: {
    variant: {
      primary: 'bg-blue-600 text-white hover:bg-blue-700',
      ghost: 'border border-gray-300 hover:bg-gray-50',
      danger: 'bg-red-600 text-white'
    },
    size: {
      sm: 'px-3 py-1 text-sm',
      md: 'px-4 py-2',
      lg: 'px-6 py-3 text-lg'
    }
  },
  defaultVariants: { variant: 'primary', size: 'md' }
})

interface ButtonProps extends VariantProps<typeof buttonVariants> {
  children: React.ReactNode
}

export function Button({ variant, size, children }: ButtonProps) {
  return <button className={buttonVariants({ variant, size })}>{children}</button>
}
```

## Anti-patterns courants

### ❌ "use client" partout
```tsx
'use client'  // ⚠️ tout le subtree devient client
export default function Layout({ children }) {
  return <div>{children}</div>  // Pas besoin de 'use client'
}
```

### ❌ Re-render à chaque render
```tsx
// ❌ Nouvelle référence à chaque render → enfants re-render
<MyChild config={{ foo: 'bar' }} />

// ✅
const config = useMemo(() => ({ foo: 'bar' }), [])
<MyChild config={config} />
```

### ❌ key avec index
```tsx
// ❌ Casse le state quand l'ordre change
items.map((item, i) => <Item key={i} {...item} />)

// ✅
items.map(item => <Item key={item.id} {...item} />)
```
