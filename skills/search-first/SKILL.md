---
name: search-first
description: Workflow research-before-coding. Avant d'implémenter, vérifier les docs officielles, les patterns établis, les CVE, les versions à jour. Évite de réinventer ce qui existe ou de copier des patterns dépréciés. Utilise Context7 quand disponible.
---

# Search First

## Principe

**Avant** d'écrire du code non-trivial sur une lib externe ou un pattern peu utilisé : chercher.

L'investissement de 2-5 minutes en recherche évite :
- Des heures de debug sur un comportement non documenté
- Des patterns dépréciés copiés de Stack Overflow 2019
- Des CVE introduites dans le code
- Des solutions "from scratch" alors qu'une lib existe

## Quand chercher

### ✅ Toujours chercher pour
- API d'une lib que tu utilises peu (ex: première fois qu'on touche aux Stripe webhooks)
- Choix d'une lib (auth, paiement, email, queue)
- Pattern de sécurité (auth flows, password reset, file upload sécurisé)
- Comportement bizarre / non documenté observé
- Debugging d'une erreur cryptique

### ❌ Pas besoin de chercher pour
- Patterns que tu maîtrises et qui sont stables (un useState basique, une route Next.js classique)
- Boilerplate trivial
- Choses purement internes au projet

## Workflow

### 1. Identifier la question précise

❌ "Comment faire de l'auth en Next.js ?"
✅ "Comment Supabase gère le refresh de session JWT en Server Components Next.js 15 ?"

### 2. Choisir la source

Ordre de fiabilité :

```
1. Documentation officielle (à jour, source de vérité)
2. GitHub repo officiel (issues, examples)
3. Changelog/release notes (pour vérifier la version)
4. Articles de l'équipe créatrice
5. Articles tiers récents (< 1 an)
6. Stack Overflow / Reddit (avec scepticisme)
```

### 3. Utiliser les outils disponibles

#### Context7 MCP (priorité)
Si Context7 est configuré (✅ tu l'as), il a un index à jour des docs des libs principales :

```
Tu as accès à Context7. Cherche-moi la doc Supabase pour la gestion des refresh tokens en Server Components.
```

#### WebSearch
Pour info large ou récente (< 2 mois).

#### WebFetch
Pour lire un article ou doc précis dont tu as l'URL.

#### `gh` CLI
Pour explorer un repo GitHub (issues, PRs).

```bash
gh repo view supabase/supabase --json description,pushedAt
gh issue list -R supabase/supabase --label bug --search "session refresh"
```

### 4. Vérifier la version

❗ Toujours vérifier la version mentionnée vs la version installée :

```bash
# Version installée
cat package.json | grep -A1 dependencies | grep [lib-name]

# Doc concerne quelle version ?
# Lire en haut de la page ou dans l'URL (souvent /v2/ ou /latest/)
```

Pour Next.js spécifiquement : la doc change beaucoup entre 13/14/15. Vérifier explicitement.

### 5. Synthétiser avant d'implémenter

```markdown
## Search Summary : [Question]

### Sources consultées
- [URL 1] — doc officielle, vXX
- [URL 2] — issue GitHub, mentionne edge case

### Ce que j'ai appris
1. [Point clé]
2. [Point clé]

### Ce qui s'applique à mon cas
- [...]

### Ce qui change vs ma version
- [...]

### Décision d'implémentation
- [...]
```

## Patterns spécifiques

### Pattern : "Avant d'utiliser une nouvelle lib"

```
1. README + Quick Start (5 min)
2. Examples officiels (5 min)
3. Issues récentes (gh issue list, filtrer "bug")
4. Bundle size (bundlephobia.com)
5. Dernière release (active maintenance ?)
6. Alternatives sérieuses (npmtrends.com vs concurrents)
```

### Pattern : "Avant de coder un flow de sécurité"

```
1. Doc officielle de la lib (Supabase, Auth0, NextAuth...)
2. OWASP Top 10 sur le sujet (auth, session, XSS, CSRF...)
3. Patterns recommandés vs anti-patterns
4. CVE récentes mentionnant cette feature
5. Implementation reference (ex: auth.js next exemples)
```

### Pattern : "Devant un bug/comportement bizarre"

```
1. Lire le message d'erreur EXACT (souvent suffit)
2. Reproduire en isolation (minimal repro)
3. Chercher l'erreur exacte sur GitHub issues du repo
4. Chercher sur Google avec guillemets exact match
5. Vérifier les release notes des dernières versions
```

## Anti-patterns

### ❌ Le "vibe code without research"
Copier-coller un pattern depuis un blog 2022 sans vérifier qu'il s'applique à ta version. Bonjour les bugs subtils.

### ❌ Le "I'll figure it out"
Tenter de comprendre par tâtonnement une lib complexe au lieu de lire 5 minutes de doc. Coût : 1h+.

### ❌ Le "Stack Overflow first"
SO a beaucoup de réponses obsolètes. Le repo officiel est plus fiable.

### ❌ Le "tout chercher"
Chercher pour du code trivial = perte de temps. Garde la recherche pour ce qui en vaut le coût.

## Configuration

Dans `~/.claude/CLAUDE.md` :

```markdown
## Search First Policy
- Avant d'implémenter avec une lib, vérifier la doc officielle (Context7 si disponible)
- Toujours vérifier la version installée vs la version de la doc lue
- Pour les flows de sécurité : OWASP + doc officielle, jamais "from memory"
- Si bug bizarre : reproduire en isolation, chercher sur GitHub issues
```

## Combinaison

- **iterative-retrieval** : la recherche externe se combine avec retrieval progressif du code interne
- **documentation-lookup** : skill jumeau, plus orienté usage Context7
- **verification-loop** : après recherche + impl, valider que le pattern marche
