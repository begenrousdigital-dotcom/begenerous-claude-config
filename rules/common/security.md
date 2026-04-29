# Security

## Principes

1. **Defense in depth** — plusieurs couches (RLS + service auth check + Zod validation)
2. **Fail closed** — par défaut refuser, pas autoriser
3. **Least privilege** — chaque acteur a le minimum nécessaire
4. **Validate at boundaries** — toute entrée externe = non confiance

## Secrets

### Jamais committés
- ✅ `.env.example` versionné, `.env.local` pas
- ✅ Tous les secrets via `process.env.X`
- ✅ Pre-commit hook qui scanne les secrets (rg patterns)

### Stockage
- **Dev local** : `.env.local`
- **Vercel** : Settings → Environment Variables (scopes : Production / Preview / Development)
- **CI/CD** : GitHub Actions secrets, jamais en clair

### Naming
```
NEXT_PUBLIC_*    # exposé au client (URLs publiques uniquement)
*                # serveur uniquement (secrets)
```

⚠️ **Ne jamais** mettre un secret en `NEXT_PUBLIC_*`.

## Auth (Supabase)

- `supabase.auth.getUser()` côté serveur (validé)
- `supabase.auth.getSession()` côté client (peut être manipulé)
- Cookies httpOnly, secure, sameSite=lax
- Email verification pour actions critiques
- 2FA pour admin

## Permissions (RLS)

Toute table publique : RLS activée + policies explicites.

```sql
ALTER TABLE x ENABLE ROW LEVEL SECURITY;
CREATE POLICY "..." ON x FOR SELECT USING (...);
```

Service role key : **uniquement côté serveur**, jamais exposée au client.

## Validation des inputs

```ts
import { z } from 'zod'

const Schema = z.object({
  email: z.string().email(),
  amount: z.number().positive().max(100_000)
})

const parsed = Schema.safeParse(input)
if (!parsed.success) return { error: parsed.error }
```

Valider tous les inputs :
- Body de Request
- Query params
- FormData (Server Actions)
- Webhooks externes (Stripe, etc.)

## XSS / Injection

### XSS
- React échappe par défaut → pas de problème sauf `dangerouslySetInnerHTML`
- Si HTML user-provided : DOMPurify obligatoire
- CSP headers configurés

### SQL injection
- Supabase client : utilise toujours les méthodes (`.eq()`, `.in()`) — jamais string concat
- Si tu utilises `.rpc()` ou requête SQL brute : paramètres bindés, jamais `${userInput}`

## CSRF

- Server Actions : protégées automatiquement par Next.js
- API Routes (POST/PUT/DELETE) : vérifier origine ou utiliser CSRF token

## Stripe

- Webhook signature verification : **obligatoire**
  ```ts
  const event = stripe.webhooks.constructEvent(body, sig, secret)
  ```
- Idempotency keys sur les charges
- Prix calculés côté serveur (jamais accepter un prix client)
- Customer portal pour self-service (pas d'UI custom de modif)

## Rate limiting

Endpoints sensibles à rate limit :
- `/api/auth/login` : 5 tentatives / 15 min par IP
- `/api/auth/signup` : 3 / heure par IP
- `/api/auth/password-reset` : 3 / heure par email
- API publiques : 60-100 req/min par token

## Logging

✅ Logger :
- Erreurs serveur (avec contexte : userId, requestId)
- Auth events (login, logout, failed attempts)
- Mutations critiques (création, suppression)

❌ Ne **jamais** logger :
- Mots de passe (même hashés en debug)
- Tokens, API keys
- Numéros de carte
- Données personnelles sensibles (santé, biométrie)

## Dépendances

```bash
pnpm audit          # vulnerabilities
pnpm outdated       # versions
```

- Dependabot/Renovate configuré
- Updates de sécurité : appliquer rapidement
- Major versions : tester avant adopter

## Headers HTTP

```ts
// next.config.ts
async headers() {
  return [{
    source: '/:path*',
    headers: [
      { key: 'X-Frame-Options', value: 'DENY' },
      { key: 'X-Content-Type-Options', value: 'nosniff' },
      { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
      { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' },
      { key: 'Content-Security-Policy', value: "..." }
    ]
  }]
}
```

## Audit checklist (pré-launch)

- [ ] Toutes tables ont RLS
- [ ] Tous les inputs validés (Zod)
- [ ] Auth check sur toute mutation
- [ ] Stripe webhook signature vérifiée
- [ ] Rate limiting sur endpoints sensibles
- [ ] Aucun secret en NEXT_PUBLIC_*
- [ ] CSP / security headers configurés
- [ ] HTTPS only en prod
- [ ] Backup DB automatique configuré
- [ ] Plan de réponse à incident écrit
