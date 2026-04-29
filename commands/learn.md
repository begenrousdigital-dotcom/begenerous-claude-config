---
description: Extrait des instincts candidats depuis la conversation et le diff git de la session courante
---

Analyse la session pour identifier les patterns à capitaliser.

Workflow :

1. **Collecter le contexte de la session** :
   - Conversation actuelle (patterns "À retenir", problèmes résolus)
   - Diff git depuis le début de la session : `git diff HEAD~N HEAD` ou `git log --since="<heure-session>"`
   - Fichiers modifiés
   - Bugs résolus mentionnés

2. **Identifier les patterns candidats** :
   - Solutions à des problèmes non-triviaux
   - Découvertes (comportement non documenté d'une lib)
   - Refactors qui ont apporté de la valeur
   - Anti-patterns évités
   - Décisions architecturales validées

3. **Filtrer le bruit** :
   - Skip les fixes triviaux (typo, formatting)
   - Skip les patterns ultra-spécifiques au projet (un nom de variable)
   - Garder ce qui est généralisable

4. **Générer 3-5 instincts candidats** maximum :
   ```yaml
   ---
   id: <slug-stable>
   title: <titre court>
   trigger: <quand l'activer>
   confidence: 0.5  # initial, sera raffiné par usage
   projects: [<projet courant>]
   created_at: <date>
   status: pending  # 30j de validation
   ---
   
   ## Action
   [Que faire concrètement]
   
   ## Pourquoi
   [Origine / problème résolu]
   
   ## Exemple
   [Cas concret de cette session]
   ```

5. **Présenter à l'utilisateur** :
   ```markdown
   ## Instincts candidats détectés (X)
   
   ### 1. [Titre]
   [Aperçu]
   Sauvegarder ? [Y/n/edit]
   
   ### 2. ...
   ```

6. **Sauvegarder** ceux validés dans `~/.claude/instincts/pending/`

7. **Suggérer** :
   - Si 0 candidat → "Session productive mais sans pattern réutilisable détecté. Normal pour du polish ou bug fixing."
   - Si > 5 candidats → "Beaucoup de patterns. Considère sélectionner les 2-3 les plus valuables."

Période recommandée : à la fin de chaque session de 2h+ de coding productif.

Anti-patterns :
- ❌ Forcer un instinct alors qu'il n'y a rien à apprendre
- ❌ Créer des instincts trop spécifiques (un nom de variable)
- ❌ Skip cette commande systématiquement → perte d'apprentissage
