# React Rules (React 19)

## Composants

### Function components only

```tsx
// ✅
export function Button({ children }: Props) {
  return <button>{children}</button>
}

// ❌ class components (sauf legacy)
class Button extends Component {...}
```

### Naming
- Composants : `PascalCase`
- Fichiers : `PascalCase.tsx`
- Hooks : `useCamelCase`

### Props typing

```tsx
type ButtonProps = {
  children: React.ReactNode
  variant?: 'primary' | 'secondary'
  onClick?: () => void
}

export function Button({ children, variant = 'primary', onClick }: ButtonProps) {
  return <button>{children}</button>
}
```

### Exports
- Préférer **named exports** (meilleur pour refactor + import autocomplete)
- `default export` uniquement quand framework l'exige (Next.js pages, layouts)

## Hooks

### useState

```tsx
// ✅ Type inféré quand possible
const [count, setCount] = useState(0)

// ✅ Type explicite si nécessaire
const [user, setUser] = useState<User | null>(null)

// ❌ Initial value non sérialisable
const [date, setDate] = useState(new Date())  // re-créée à chaque render
// → useState(() => new Date()) (lazy init)
```

### useEffect

```tsx
// ✅ Cleanup quand abonnement
useEffect(() => {
  const sub = subscribe(...)
  return () => sub.unsubscribe()
}, [])

// ❌ Synchroniser state avec props
useEffect(() => {
  setLocalValue(propValue)
}, [propValue])
// → Calculer directement : const localValue = derive(propValue)
```

### Custom hooks

```tsx
// hooks/use-quote.ts
export function useQuote(quoteId: string) {
  const [data, setData] = useState<Quote | null>(null)
  const [error, setError] = useState<Error | null>(null)
  const [loading, setLoading] = useState(true)
  
  useEffect(() => {
    fetchQuote(quoteId)
      .then(setData)
      .catch(setError)
      .finally(() => setLoading(false))
  }, [quoteId])
  
  return { data, error, loading }
}
```

⚠️ Note : avec Server Components + Suspense, ce pattern devient rare. Préférer les Server Components pour data fetching.

### React 19 specifics

#### Pas besoin de forwardRef
```tsx
// React 19 : ref passe comme prop
function Button({ ref, ...props }: ButtonProps & { ref?: Ref<HTMLButtonElement> }) {
  return <button ref={ref} {...props} />
}
```

#### useOptimistic
```tsx
'use client'
import { useOptimistic } from 'react'

function LikeButton({ postId, initialLikes }: Props) {
  const [optimisticLikes, addOptimistic] = useOptimistic(
    initialLikes,
    (state, newLike: number) => state + newLike
  )
  
  return (
    <button onClick={() => {
      addOptimistic(1)
      toggleLike(postId)
    }}>
      {optimisticLikes} 👍
    </button>
  )
}
```

#### useFormStatus
```tsx
'use client'
import { useFormStatus } from 'react-dom'

function SubmitButton() {
  const { pending } = useFormStatus()
  return <button disabled={pending}>{pending ? 'Sending...' : 'Send'}</button>
}
```

## Patterns

### Composition over props explosion

```tsx
// ❌ Props explosion
<Card 
  title="..." 
  description="..." 
  showHeader={true} 
  showFooter={false} 
  customHeaderContent={<>...</>} 
/>

// ✅ Composition
<Card>
  <Card.Header>
    <h2>...</h2>
  </Card.Header>
  <Card.Body>...</Card.Body>
</Card>
```

### Render props (rare en 2026, mais utile)

```tsx
function DataLoader<T>({ url, children }: {
  url: string
  children: (data: T) => ReactNode
}) {
  const [data, setData] = useState<T>()
  // ...
  if (!data) return <Skeleton />
  return <>{children(data)}</>
}
```

### Compound components

```tsx
const Tabs = ({ children }: Props) => <div>{children}</div>
Tabs.List = ({ children }) => <div>{children}</div>
Tabs.Tab = ({ children }) => <button>{children}</button>
Tabs.Panel = ({ children }) => <div>{children}</div>

// Usage
<Tabs>
  <Tabs.List>
    <Tabs.Tab>Tab 1</Tabs.Tab>
  </Tabs.List>
  <Tabs.Panel>Content</Tabs.Panel>
</Tabs>
```

## Styling

### Tailwind avec cn() helper

```tsx
import { cn } from '@/lib/utils'

<button className={cn(
  'px-4 py-2 rounded',
  variant === 'primary' && 'bg-blue-600 text-white',
  disabled && 'opacity-50',
  className  // override depuis l'extérieur
)} />
```

### CVA pour variants

```tsx
import { cva, type VariantProps } from 'class-variance-authority'

const button = cva('rounded font-medium', {
  variants: {
    variant: {
      primary: 'bg-blue-600 text-white',
      ghost: 'border'
    },
    size: {
      sm: 'px-3 py-1 text-sm',
      md: 'px-4 py-2'
    }
  },
  defaultVariants: { variant: 'primary', size: 'md' }
})

interface Props extends VariantProps<typeof button> {
  children: ReactNode
}

export function Button({ variant, size, children }: Props) {
  return <button className={button({ variant, size })}>{children}</button>
}
```

## Anti-patterns

### ❌ key avec index
```tsx
items.map((item, i) => <Item key={i} {...item} />)
// → key={item.id}
```

### ❌ Inline objects/functions in JSX
```tsx
// ❌ Nouvel objet à chaque render
<Component config={{ foo: 'bar' }} />

// ✅
const config = useMemo(() => ({ foo: 'bar' }), [])
```

### ❌ useEffect pour calculer
```tsx
const [fullName, setFullName] = useState('')
useEffect(() => {
  setFullName(`${firstName} ${lastName}`)
}, [firstName, lastName])

// ✅ Calcul direct
const fullName = `${firstName} ${lastName}`
```

### ❌ useEffect pour sync avec parent
```tsx
useEffect(() => {
  onChange(value)
}, [value])

// ✅ Appeler dans le handler
const handleChange = (v: string) => {
  setValue(v)
  onChange(v)
}
```

### ❌ Memoization aveugle
```tsx
const handler = useCallback(() => {...}, [])
const value = useMemo(() => data, [data])
```
React Compiler (R19) optimise automatiquement. `useCallback`/`useMemo` souvent inutiles.

### ❌ Trop de `'use client'`
Tout client = bundle JS lourd. Server Components par défaut, client uniquement à la frontière interactive.

### ❌ Context pour tout
Context re-render tous les consumers. Pour state global complexe : Zustand, Jotai, ou URL state.
