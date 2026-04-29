# TypeScript Style

## Configuration recommandée

`tsconfig.json` strict :

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,
    "exactOptionalPropertyTypes": true,
    "verbatimModuleSyntax": true
  }
}
```

## Types

### Préférer types > interfaces (sauf besoin spécifique)

```ts
// ✅ Default
type User = {
  id: string
  email: string
}

// ✅ Interfaces uniquement quand besoin de declaration merging ou extends
interface ApiResponse<T> {
  data: T
}
interface ApiResponse<T> {
  meta?: Meta  // merge avec la précédente
}
```

### Pas de `any`

```ts
// ❌
function parse(input: any) {...}

// ✅ unknown + narrowing
function parse(input: unknown) {
  if (typeof input === 'string') {
    // ...
  }
}

// ✅ Generic
function parse<T>(input: T): T {...}
```

### Discriminated unions

```ts
type Result<T> =
  | { status: 'success'; data: T }
  | { status: 'error'; error: string }
  | { status: 'loading' }

function handle(r: Result<User>) {
  switch (r.status) {
    case 'success': return r.data
    case 'error': return r.error
    case 'loading': return null
    default: const _: never = r  // exhaustiveness check
  }
}
```

### Branded types pour IDs

```ts
type UserId = string & { __brand: 'UserId' }
type QuoteId = string & { __brand: 'QuoteId' }

// Empêche de mélanger les IDs
function getUser(id: UserId) {...}
const quoteId: QuoteId = '...'
getUser(quoteId)  // ❌ Type error
```

## Functions

### Signatures explicites sur exports

```ts
// ❌ Inférence implicite (export public)
export function calculate(x, y) {
  return x + y
}

// ✅ Signature explicite
export function calculate(x: number, y: number): number {
  return x + y
}
```

### Object args pour 3+ params

```ts
// ❌
function createQuote(serviceId: string, artisanId: string, amount: number, description: string, expiresAt: Date) {...}

// ✅
function createQuote(input: {
  serviceId: string
  artisanId: string
  amount: number
  description: string
  expiresAt: Date
}) {...}
```

### Async = return Promise

```ts
// Toujours mark async functions, même si elles ne font qu'await dans le body
async function fetchUser(id: string): Promise<User> {
  const response = await fetch(...)
  return response.json()
}
```

## Imports

### Type vs value

```ts
// ✅
import { useState } from 'react'
import type { ChangeEvent } from 'react'

// ✅ Inline
import { useState, type ChangeEvent } from 'react'
```

### Path aliases

```json
// tsconfig.json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@/components/*": ["./src/components/*"]
    }
  }
}
```

```ts
// ✅
import { Button } from '@/components/ui/button'

// ❌ relatives profondes
import { Button } from '../../../../components/ui/button'
```

## Generics

### Constraints quand possible

```ts
// ❌
function getProperty<T>(obj: T, key: string) {
  return obj[key]  // Type error: implicit any
}

// ✅
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key]
}
```

### Avoid abstract over the actual

Si tu n'as qu'un seul use case, n'utilise pas de generic.

```ts
// ❌ Abstract trop tôt
function process<T>(input: T): T {...}

// ✅ Concret
function processUser(input: User): User {...}
```

## Errors

### Custom error classes

```ts
class ValidationError extends Error {
  constructor(public field: string, public reason: string) {
    super(`Validation failed: ${field} - ${reason}`)
    this.name = 'ValidationError'
  }
}

// Usage
throw new ValidationError('email', 'invalid format')
```

### Type narrowing dans catch

```ts
try {
  // ...
} catch (error) {
  // error is unknown
  if (error instanceof ValidationError) {
    // narrowed to ValidationError
  } else if (error instanceof Error) {
    // narrowed to Error
  }
}
```

## Result type (alternative à throw)

```ts
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E }

async function parse(input: unknown): Promise<Result<User>> {
  const validation = UserSchema.safeParse(input)
  if (!validation.success) {
    return { ok: false, error: new ValidationError(...) }
  }
  return { ok: true, value: validation.data }
}
```

## Anti-patterns

### ❌ as casts
```ts
const user = data as User  // ⚠️ pas de runtime check
```
→ Préférer Zod parse, type guards.

### ❌ // @ts-ignore sans justification
```ts
// @ts-ignore
brokenCode()
```
→ Si vraiment nécessaire, expliquer :
```ts
// @ts-expect-error: lib X has incorrect types pre-v2.0, see issue #123
brokenCode()
```

### ❌ Object types trop larges
```ts
// ❌
const config: object = {...}
const fn: Function = () => {...}

// ✅
const config: Record<string, unknown> = {...}
const fn: () => void = () => {...}
```

### ❌ Enums TS (utiliser unions de literals)
```ts
// ❌
enum Status { Active = 'active', Inactive = 'inactive' }

// ✅
type Status = 'active' | 'inactive'
const STATUSES = ['active', 'inactive'] as const
```

Les unions de literals sont :
- Mieux pour le tree-shaking
- Sérialisables en JSON
- Plus simples à manipuler
