---
name: documentation-lookup
description: Workflow optimisé pour consulter la doc d'une lib via Context7 ou WebFetch. Évite les hallucinations sur les APIs et garantit qu'on suit la version actuelle. Surcouche pratique sur search-first.
---

# Documentation Lookup

## Quand utiliser

- Avant d'utiliser une nouvelle API/méthode d'une lib
- Pour vérifier la signature exacte d'une fonction
- Quand un type TS est confus / mal documenté
- Pour comparer des options (`fetch` vs `axios`, `tanstack-query` vs `swr`...)
- Avant un upgrade majeur de version

## Sources, par ordre de priorité

### 1. Context7 MCP (si installé)

```
Tu as accès à Context7. Cherche-moi : "supabase auth getUser server component nextjs 15"
```

Avantages :
- Index à jour des docs
- Filtre automatique par version
- Pas besoin de gérer les URLs

### 2. Doc officielle de la lib

URLs à connaître pour ton stack :

| Lib | URL doc |
|---|---|
| Next.js | https://nextjs.org/docs |
| Supabase | https://supabase.com/docs |
| Stripe | https://stripe.com/docs/api |
| Vercel | https://vercel.com/docs |
| Tailwind | https://tailwindcss.com/docs |
| shadcn/ui | https://ui.shadcn.com/docs |
| React | https://react.dev |
| TypeScript | https://www.typescriptlang.org/docs |
| Zod | https://zod.dev |
| Playwright | https://playwright.dev |

### 3. GitHub repo de la lib

Pour les comportements non documentés :
```bash
# Issues récentes
gh issue list -R vercel/next.js --search "in:title hydration"

# Code source (pour comprendre l'implémentation)
gh repo clone vercel/next.js /tmp/nextjs-source
```

### 4. Changelog / release notes

Pour vérifier ce qui a changé entre versions :
- `https://github.com/{org}/{repo}/releases`
- `https://github.com/{org}/{repo}/blob/main/CHANGELOG.md`

## Workflow

### Étape 1 : formuler la question

❌ Vague : "Comment marchent les cookies en Next.js ?"
✅ Précis : "Comment lire un cookie en Server Component avec Next.js 15.x ?"

Plus la question est ciblée, meilleure est la réponse.

### Étape 2 : choisir la source

```
Si Context7 disponible          → Context7 d'abord
Sinon URL officielle connue     → WebFetch direct
Sinon question large            → WebSearch puis WebFetch
Bug spécifique                  → GitHub issues du repo
```

### Étape 3 : vérifier la version

```bash
# Version installée locale
cat package.json | grep -E '"next"|"react"|"@supabase'

# Comparer avec celle de la doc
# Souvent visible dans l'URL ou en haut de la page
```

⚠️ **Drama version** : Next.js 13 → 14 → 15 ont chacun des breaking changes. Une réponse qui marche en 13 peut casser en 15.

### Étape 4 : extraire l'essentiel

Pour ne pas saturer le contexte, extraire :
- La signature exacte de la fonction/méthode
- Les paramètres requis vs optionnels
- 1 exemple représentatif
- Les pièges mentionnés (warnings, deprecation)

```markdown
## Doc lookup : Supabase getUser() en Server Components

### Source
https://supabase.com/docs/reference/javascript/auth-getuser (v2.x)

### Signature
```ts
const { data: { user }, error } = await supabase.auth.getUser()
```

### Notes critiques
- Doit être appelé via Server Component / Route Handler / Server Action
- Validation côté serveur (vs `getSession()` qui peut être manipulé client-side)
- Refresh token automatiquement via cookies

### Mon usage
[Comment je vais l'intégrer dans mon code]
```

### Étape 5 : noter pour réutilisation

Si c'est un pattern qu'on va revoir :
- Noter dans un instinct (`/learn`)
- Ou ajouter à `~/.claude/CLAUDE.md` du projet

## Patterns spécifiques

### Vérifier qu'une feature existe dans la version installée

```bash
# Quelle est la version installée ?
cat node_modules/next/package.json | grep version

# Cette version supporte X ?
# Lire le changelog de cette version + suivantes
```

### Comparer plusieurs libs

```markdown
## Comparaison : tanstack-query vs swr

| Critère | tanstack-query | swr |
|---|---|---|
| Bundle size | 13kb | 4kb |
| Maintainer | Tanner Linsley | Vercel team |
| Features | + (mutations, infinite, optimistic) | minimal |
| Best fit | App complexe | Simple data fetching |

→ Pour Edirex : tanstack-query (mutations + optimistic updates)
```

### Vérifier les CVE / security advisories

```bash
# Dans le projet
pnpm audit

# Sur GitHub
# https://github.com/{org}/{repo}/security/advisories
```

## Anti-patterns

### ❌ Faire confiance à sa mémoire

> "Je crois que `next/cache` permet de faire X..."

→ Vérifier. La syntaxe a changé entre Next.js 13/14/15.

### ❌ Copier depuis Stack Overflow sans vérifier la date

Réponse de 2020 sur Next.js → probablement Pages Router, plus App Router.

### ❌ Lire toute la doc d'une lib

Time-box : 5-10 min max sur une question précise. Au-delà, c'est qu'on cherche au mauvais endroit.

### ❌ Pas vérifier la version

```ts
// Lu dans une doc Next.js 13
import { unstable_cache } from 'next/cache'

// Marche-t-il toujours en Next.js 15.5 ?
// Probablement, mais à vérifier dans le changelog
```

## Outils utiles

### Bundlephobia (taille bundle)
https://bundlephobia.com/package/{lib}

### Npmtrends (popularité comparée)
https://npmtrends.com/lib1-vs-lib2

### Are The Types Wrong
https://arethetypeswrong.github.io
→ Vérifier qu'une lib publie ses types correctement.

### TypeScript Playground
https://www.typescriptlang.org/play
→ Tester un type sans setup local.

## Combinaison

- **search-first** : philosophie générale, ce skill = focus doc
- **continuous-learning** : noter les patterns récurrents découverts via doc
- **iterative-retrieval** : si la doc est longue, lire par couches
