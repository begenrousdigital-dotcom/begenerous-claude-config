---
description: Lance la verification loop complète (typecheck + lint + tests + build optionnel)
argument-hint: [--with-build] [--scope <path>]
---

Lance la verification loop pour valider l'état du code.

Workflow :

1. **Détecter le package manager** : pnpm / npm / yarn / bun (lire `package.json`, lockfile)

2. **Étape 1 : typecheck** (5-10s)
   ```bash
   pnpm tsc --noEmit
   ```
   Si échec → arrêter, afficher les erreurs, suggérer fix.

3. **Étape 2 : lint** (10-20s)
   ```bash
   pnpm lint
   ```
   Si warnings/errors → afficher, demander auto-fix possible :
   ```bash
   pnpm lint --fix
   ```

4. **Étape 3 : tests focalisés** (variable)
   - Détecter les fichiers modifiés depuis le dernier commit : `git diff --name-only HEAD`
   - Lancer uniquement les tests proches :
     ```bash
     pnpm test --run [fichiers]
     ```
   - Si pas de test pour les fichiers modifiés → noter et suggérer d'en ajouter

5. **Étape 4 : build (si `--with-build`)** (30-60s)
   ```bash
   pnpm build
   ```

6. **Rapport final** :
   ```markdown
   ## Verification Loop — <date>
   
   ### typecheck ✅ (3.2s)
   0 errors
   
   ### lint ✅ (8.1s)
   0 warnings
   
   ### tests (5 fichiers) ✅ (12.4s)
   42/42 tests pass
   
   ### build (skipped — utiliser --with-build pour inclure)
   
   ✅ Safe to commit
   ```
   
   Ou si échec :
   ```markdown
   ### typecheck ❌
   src/lib/foo.ts:42 — Type error
   
   → Fixer avant de continuer.
   ```

Options :
- `--with-build` : inclure `pnpm build` (lent, à utiliser avant push)
- `--scope <path>` : limiter aux fichiers d'un sous-dossier

Cas d'usage :
- Avant chaque commit (manuel ou via hook pre-commit)
- Après une feature
- Avant push sur main
- Pour vérifier qu'on n'a rien cassé après refactor
