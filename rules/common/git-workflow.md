# Git Workflow

## Branches

```
main           # production
├── feature/edirex-auth
├── fix/quote-validation
└── chore/upgrade-nextjs
```

- `main` = toujours déployable
- Une branche par feature/fix
- Naming : `<type>/<short-description>`
- Types : `feature/`, `fix/`, `chore/`, `refactor/`, `docs/`

## Commits

### Conventional commits

```
<type>(<scope>): <description>

[body optionnel]

[footer optionnel : refs, breaking changes]
```

Exemples :
```
feat(quotes): add expiration logic
fix(auth): handle session refresh edge case
chore(deps): bump next 15.5.0 → 15.6.0
refactor(api): extract quote service
docs(readme): update setup instructions
```

### Frequency

- Commits **petits** et **fréquents**
- 1 commit = 1 unité logique de changement
- Si le diff est > 200 lignes : probablement à splitter

### Atomic commits

Chaque commit doit :
- Compiler / passer les tests (le projet ne doit jamais être cassé sur un commit isolé)
- Être réversible (revertable)
- Avoir un message qui explique le **pourquoi**

## Workflow type (vibe coder solo)

```bash
# 1. Démarrer une feature
git checkout -b feature/quote-expiration

# 2. Travailler par étapes, commit à chaque milestone
git add -p  # add interactif
git commit -m "feat(quotes): add expires_at field"

git add -p
git commit -m "feat(quotes): handle expiration in matching"

# 3. Verification loop avant push
pnpm tsc --noEmit && pnpm lint && pnpm test

# 4. Push + merge
git checkout main
git merge feature/quote-expiration --no-ff
git push origin main
```

## Avant chaque push (checklist)

- [ ] Verification loop OK (`tsc --noEmit && lint && test`)
- [ ] Build passe localement (`pnpm build`)
- [ ] Pas de secret committé (`git diff --cached | grep -i 'sk_live\|api_key\|password'`)
- [ ] Migrations DB testées localement (`supabase db reset`)
- [ ] Message de commit explicite

## Rebase vs merge

- **Solo** : merge classique, plus simple
- **Équipe** : rebase pour garder un historique linéaire

```bash
# Rebase sur main avant merge (équipe)
git checkout feature/x
git rebase main
git checkout main
git merge feature/x  # fast-forward
```

## .gitignore essentiels

```
# Build
.next/
dist/
out/

# Env
.env
.env.local
.env.production

# IDE
.vscode/settings.json
.idea/

# Supabase
supabase/.branches/
supabase/.temp/

# Tests
test-results/
playwright-report/
playwright/.auth/

# OS
.DS_Store
Thumbs.db

# Logs
*.log
```

## Recovery

### Annuler un commit non poussé
```bash
git reset --soft HEAD~1   # garde les changements en staged
git reset HEAD~1          # garde non-staged
git reset --hard HEAD~1   # ⚠️ perd les changements
```

### Annuler un commit poussé
```bash
git revert <hash>          # crée un commit inverse (préféré)
git push
```

### Récupérer un fichier d'un commit précédent
```bash
git show <hash>:<path>          # voir
git checkout <hash> -- <path>   # restaurer
```

### Cherrypicker depuis une autre branche
```bash
git cherry-pick <hash>
```

## Hooks pre-commit (recommandé)

```bash
# .husky/pre-commit
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

# Format auto
pnpm lint-staged

# Verification rapide
pnpm tsc --noEmit
```

```json
// package.json
{
  "lint-staged": {
    "*.{ts,tsx}": ["eslint --fix", "prettier --write"]
  }
}
```

## Anti-patterns

- ❌ `git commit -am "wip"` → commit sans intention claire
- ❌ Force push sur main → jamais
- ❌ Commits de 1000+ lignes → impossible à reviewer/revert
- ❌ Branches longues (> 1 semaine) → conflits garantis
- ❌ Pas de verification loop avant push → casser CI/CD/prod
