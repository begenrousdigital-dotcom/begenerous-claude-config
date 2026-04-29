---
name: api-design
description: Design d'APIs REST cohérentes pour Next.js Route Handlers — naming, codes HTTP, pagination, error responses, versioning, OpenAPI. À utiliser quand on construit une API consommée par d'autres apps ou par mobile.
---

# API Design

## Principes

1. **REST quand possible**, RPC quand nécessaire
2. **Codes HTTP standards** — pas d'invention
3. **Erreurs structurées** — pas de strings
4. **Versioning explicite** dès le début
5. **Documentation = code** (OpenAPI / TypeScript types partagés)

## Naming des routes

### Resources nominales (REST)

```
GET    /api/v1/quotes              # Liste
POST   /api/v1/quotes              # Créer
GET    /api/v1/quotes/:id          # Détail
PATCH  /api/v1/quotes/:id          # Update partiel
PUT    /api/v1/quotes/:id          # Replace complet
DELETE /api/v1/quotes/:id          # Supprimer

# Sub-resources
GET    /api/v1/quotes/:id/messages
POST   /api/v1/quotes/:id/messages
```

### Actions verbales (RPC) — quand REST ne fit pas

```
POST   /api/v1/quotes/:id/accept
POST   /api/v1/quotes/:id/reject
POST   /api/v1/quotes/:id/duplicate
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
```

### Conventions

- ✅ `kebab-case` dans les paths
- ✅ Pluriel pour les collections (`/quotes`, pas `/quote`)
- ✅ Noms anglais (sauf si API spécifiquement franco-suisse)
- ❌ Verbes dans les paths REST (`/getQuotes` ❌, `/quotes` ✅)

## Codes HTTP

### Succès
| Code | Quand | Body |
|---|---|---|
| 200 | GET, PATCH, PUT réussis | Resource(s) |
| 201 | POST réussi (création) | Resource créée + `Location` header |
| 202 | Accepté pour traitement async | `{ jobId, status: 'pending' }` |
| 204 | DELETE réussi | (vide) |

### Erreurs client
| Code | Quand |
|---|---|
| 400 | Body malformé, validation échouée |
| 401 | Non authentifié |
| 403 | Authentifié mais pas autorisé |
| 404 | Resource inexistante |
| 409 | Conflit (ex: email déjà pris) |
| 422 | Validation sémantique échouée (rare, 400 souvent suffit) |
| 429 | Rate limited |

### Erreurs serveur
| Code | Quand |
|---|---|
| 500 | Erreur inattendue |
| 502 | Dépendance externe down |
| 503 | Service en maintenance |

⚠️ **Ne jamais utiliser** :
- 200 avec `{ error: ... }` dans le body (sauf si l'API doit imiter une autre)
- 500 pour des erreurs prévisibles (validation, auth)

## Format des erreurs

### Format unifié

```json
{
  "error": {
    "code": "QUOTE_NOT_FOUND",
    "message": "Devis introuvable",
    "details": {
      "quote_id": "abc-123"
    }
  }
}
```

### Validation errors (multi-champs)

```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Validation échouée",
    "fields": {
      "amount": ["doit être positif"],
      "description": ["minimum 10 caractères"]
    }
  }
}
```

### Code interne stable

Le `code` doit être :
- ✅ Stable (les clients construisent du code dessus)
- ✅ SCREAMING_SNAKE_CASE
- ✅ Spécifique (`USER_EMAIL_TAKEN`, pas `CONFLICT`)
- ❌ Pas un message localisé

Le `message` est pour les humains et peut être localisé ; le `code` ne change jamais.

## Pagination

### Cursor-based (recommandé)

```http
GET /api/v1/quotes?limit=20&cursor=eyJjcmVhdGVkX2F0IjoiMjAyNi0wNC0yOSJ9

Response:
{
  "data": [...],
  "pagination": {
    "next_cursor": "eyJjcmVhdGVkX2F0IjoiMjAyNi0wNC0yOCJ9",
    "has_more": true
  }
}
```

### Offset-based (à éviter sur grandes tables)

```http
GET /api/v1/quotes?page=2&per_page=20

Response:
{
  "data": [...],
  "pagination": {
    "page": 2,
    "per_page": 20,
    "total": 1234
  }
}
```

⚠️ Coût `OFFSET` augmente linéairement → cursor pour > 10k rows.

## Filtering, sorting

```http
GET /api/v1/quotes?status=pending&min_amount=1000&sort=-created_at
```

Conventions :
- `?status=value` pour égalité
- `?min_amount=`, `?max_amount=` pour ranges
- `?sort=field` ascendant, `?sort=-field` descendant
- `?fields=id,amount,status` pour sparse fieldsets (optionnel)
- `?include=client,artisan` pour expanded relations (optionnel)

## Versioning

### URL versioning (le plus simple)

```
/api/v1/quotes
/api/v2/quotes
```

✅ Avantages : trivial à debug, cacheable, clair
❌ Désavantage : duplication potentielle entre versions

### Quand bumper la version

- Breaking change : suppression de champ, changement de type, sémantique modifiée
- ❌ Pas pour : ajout de champ optionnel, nouveau endpoint

### Strategy de migration

```
v1 actif (current)
    ↓
v2 lancée (en parallèle)
    ↓
v1 marquée deprecated dans headers
    ↓
v1 supprimée 6-12 mois après deprecation
```

## Headers utiles

### Request
```http
Authorization: Bearer xxx
X-Request-Id: uuid           # tracking
Idempotency-Key: uuid        # POST critiques
Accept-Language: fr-CH       # pour messages localisés
```

### Response
```http
X-Request-Id: uuid           # même que request
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1635000000
Cache-Control: no-store      # ou public, max-age=3600
```

### Deprecation
```http
Deprecation: true
Sunset: Wed, 1 Jan 2027 00:00:00 GMT
Link: </api/v2/quotes>; rel="successor-version"
```

## Idempotency

Pour POST critiques (paiement, création de ressource unique) :

```http
POST /api/v1/quotes
Idempotency-Key: 7c8a4f2e-...
```

Côté serveur :
1. Hasher le body + key
2. Vérifier en cache : si identique, retourner réponse précédente
3. Sinon traiter et stocker {key → response} pour 24h

→ Évite les doubles créations si le client retry.

## OpenAPI / TypeScript types partagés

### Approche : Zod → OpenAPI → types

```ts
// lib/api/schemas.ts
import { z } from 'zod'
import { extendZodWithOpenApi, OpenAPIRegistry } from '@asteasolutions/zod-to-openapi'

extendZodWithOpenApi(z)

export const QuoteSchema = z.object({
  id: z.string().uuid().openapi({ description: 'Identifiant unique' }),
  amount: z.number().positive().openapi({ example: 1500 }),
  status: z.enum(['pending', 'accepted', 'rejected'])
}).openapi('Quote')

// Génère le type TS automatiquement
export type Quote = z.infer<typeof QuoteSchema>
```

Génération du spec OpenAPI :
```ts
const generator = new OpenApiGeneratorV3(registry.definitions)
const spec = generator.generateDocument({
  openapi: '3.0.0',
  info: { title: 'Edirex API', version: '1.0.0' }
})
```

## Documentation minimale

Pour chaque endpoint, documenter :
- Description (1-2 phrases)
- Auth requise (oui/non + scope)
- Body schema (Zod / TypeScript)
- Response schema (par code HTTP)
- Erreurs possibles avec codes
- Exemple curl

```markdown
## POST /api/v1/quotes

Créer un nouveau devis.

**Auth** : requise (artisan vérifié)

**Body** :
```json
{
  "service_request_id": "uuid",
  "amount": 1500,
  "description": "Pose de carrelage 30m²"
}
```

**Response 201** :
```json
{
  "data": {
    "id": "uuid",
    "status": "pending",
    "created_at": "2026-04-29T10:00:00Z"
  }
}
```

**Erreurs** :
- 401 `UNAUTHORIZED` — non authentifié
- 403 `ARTISAN_NOT_VERIFIED` — artisan en attente de vérification
- 400 `VALIDATION_FAILED` — body invalide
- 404 `SERVICE_REQUEST_NOT_FOUND` — demande inexistante
- 409 `QUOTE_LIMIT_REACHED` — déjà 3 devis sur cette demande
```

## Anti-patterns

### ❌ Mélanger REST et RPC sans cohérence
```
GET    /api/users           # REST
POST   /api/getUserById     # RPC, et 2x la même chose
```

### ❌ Tout en POST
```
POST /api/getQuotes     ❌
POST /api/deleteQuote   ❌
POST /api/updateQuote   ❌
```

### ❌ Body dans GET
```
GET /api/quotes
Body: { filters: {...} }  ❌ (pas standard, beaucoup de proxies l'ignorent)
```
→ Utiliser query params ou passer en POST.

### ❌ Erreurs en string
```json
{ "error": "Quote not found" }
```
→ Toujours structuré : `{ error: { code, message, ... } }`.

### ❌ Pas de version
```
/api/quotes  # pas de v1 = casse-tête au moment du breaking change
```
