# Patterns généraux

Patterns architecturaux et de code applicables tous langages.

## SOLID (rappel rapide)

- **S** Single Responsibility : une classe/fonction = une raison de changer
- **O** Open/Closed : ouvert à extension, fermé à modification
- **L** Liskov : sous-types substituables
- **I** Interface Segregation : interfaces spécifiques > interfaces god
- **D** Dependency Inversion : dépendre d'abstractions

## Patterns utiles

### Repository pattern
Découple la logique métier de l'accès DB.

```ts
// repository
class QuoteRepository {
  async findById(id: string): Promise<Quote | null> {...}
  async create(input: CreateQuoteInput): Promise<Quote> {...}
}

// service (business logic)
class QuoteService {
  constructor(private repo: QuoteRepository) {}
  
  async createQuote(userId: string, input: ...) {
    // logique métier ici
    return this.repo.create(...)
  }
}
```

### Builder pattern
Pour objets complexes avec beaucoup d'options.

```ts
const query = new QueryBuilder()
  .select('id', 'name')
  .from('users')
  .where('active', true)
  .orderBy('created_at', 'desc')
  .limit(20)
  .build()
```

### Strategy pattern
Algorithmes interchangeables.

```ts
interface MatchingStrategy {
  match(request: Request, artisans: Artisan[]): Artisan[]
}

class GeoProximityStrategy implements MatchingStrategy {...}
class WeightedRotationStrategy implements MatchingStrategy {...}

// Usage
const strategy: MatchingStrategy = isNewUser ? new GeoProximityStrategy() : new WeightedRotationStrategy()
const matches = strategy.match(request, artisans)
```

### Observer / Pub-Sub
Pour découpler producteurs et consommateurs.

```ts
eventBus.on('quote.created', sendEmailNotification)
eventBus.on('quote.created', updateAnalytics)

await createQuote(...)
eventBus.emit('quote.created', { quoteId, ... })
```

### Result type (vs throwing)
Pour les erreurs prévisibles, retourner Result au lieu de throw.

```ts
type Result<T, E = string> = 
  | { success: true; data: T }
  | { success: false; error: E }

async function createQuote(...): Promise<Result<Quote, ValidationError>> {
  if (!isValid) return { success: false, error: '...' }
  return { success: true, data: quote }
}
```

## Anti-patterns

### God object / Massive class
Une classe de 1000 lignes qui gère 10 sujets → splitter par responsabilité.

### Anémique domain model
Models qui sont juste des bags of properties, toute la logique en dehors → mettre les invariants dans le model.

### Primitive obsession
```ts
// ❌
function transfer(fromId: string, toId: string, amount: number) {...}

// ✅
function transfer(fromAccount: AccountId, toAccount: AccountId, amount: Money) {...}
```

### Boolean params
```ts
// ❌
createUser(email, password, true, false, true)

// ✅
createUser({ email, password, sendWelcome: true, requireMFA: false, autoLogin: true })
```

### Premature optimization
"On va peut-être en avoir besoin" → YAGNI. Pas de feature ni d'abstraction sans usage actuel.

### Premature abstraction
Abstraire après 3 cas concrets, pas avant. La mauvaise abstraction est plus coûteuse que la duplication.

## Conventions de nommage par couche

```
src/
├── components/       # Composants React (PascalCase.tsx)
├── lib/             # Code business générique
│   ├── services/    # Business logic (XxxService)
│   ├── repos/       # DB access (XxxRepository)
│   └── utils/       # Helpers purs
├── app/             # Next.js routes (App Router)
│   ├── api/         # Route Handlers
│   └── (routes)/
├── hooks/           # React hooks custom (useXxx)
├── types/           # Types TS partagés
└── config/          # Configuration (constantes, env)
```

## Quand introduire une abstraction

### Trop tôt (anti-pattern)
- Un seul use case → garder concret
- "Au cas où" → YAGNI

### Au bon moment
- 3 use cases similaires
- Le pattern devient évident
- L'abstraction réduit la complexité totale

### Trop tard
- Tu te retrouves avec 10 versions divergées
- Il faut maintenant abstraire ET aligner les divergences

Règle empirique : extraire à la **3e duplication**.
