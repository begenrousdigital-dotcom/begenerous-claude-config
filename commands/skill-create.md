---
description: Génère un nouveau skill depuis l'historique git d'un projet (capitalise sur les patterns récurrents)
argument-hint: [--project <path>] [--since <date>] [--topic <theme>]
---

Analyse l'historique git pour générer un skill formel.

Workflow :

1. **Collecter les données** :
   - Logs git : `git log --since=<date> --all --pretty=format:'%H|%ad|%s'`
   - Fichiers les plus modifiés : `git log --since=<date> --pretty=format: --name-only | sort | uniq -c | sort -rn | head -20`
   - Messages de commit (souvent contiennent les leçons : "fix: handle case X", "refactor: avoid pattern Y")

2. **Si `--topic` fourni** : filtrer les commits/files autour de ce thème (auth, payments, forms, etc.)

3. **Identifier les patterns récurrents** :
   - Files modifiés ensemble → indique des couplages
   - Bug fixes répétés sur même zone → fragilité documentée
   - Refactors successifs → évolution de pattern qui mérite d'être figée
   - Messages avec "lesson learned", "FYI", "important" → pépites

4. **Proposer un skill candidat** :
   ```markdown
   ## Skill candidat : <nom>
   
   ### Source (X commits, Y fichiers)
   - <fichier-clé-1>
   - <fichier-clé-2>
   - ...
   
   ### Patterns détectés
   1. [Pattern récurrent observé sur N commits]
   2. ...
   
   ### Skill généré (preview)
   ---
   name: <slug>
   description: ...
   ---
   
   # <Titre>
   
   ## Quand utiliser
   ...
   
   ## Patterns
   ...
   
   ## Anti-patterns
   ...
   
   Sauvegarder ce skill ? [Y/n/edit]
   ```

5. **Si confirmation** :
   - Sauvegarder dans `~/.claude/skills/<slug>/SKILL.md`
   - Tagger comme `auto-generated` pour traçabilité
   - Suggérer une review humaine avant usage intensif

Heuristiques :
- Si < 10 commits sur le thème → pas assez de données, suggérer d'attendre
- Si > 100 commits → trop large, suggérer de décomposer en plusieurs skills
- Vérifier qu'un skill similaire n'existe pas déjà (dans `~/.claude/skills/`)

Cas d'usage :
- Après 6 mois sur un projet (Edirex), capitaliser sur les patterns spécifiques
- Avant de quitter un projet client, extraire les leçons en skills réutilisables
- Périodiquement (trimestriel) sur les projets actifs

Anti-patterns :
- ❌ Auto-générer sans review humaine
- ❌ Générer un skill depuis < 10 commits (pas de signal statistique)
- ❌ Inclure du contenu confidentiel client dans le skill
