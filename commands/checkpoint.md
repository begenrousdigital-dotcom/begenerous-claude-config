---
description: Crée un checkpoint de la session courante (commit + résumé contextualisé) pour reprise propre
---

Crée un point de sauvegarde de la session pour pouvoir reprendre proprement plus tard.

Workflow :

1. **État actuel du code** :
   - `git status` : modifications non committées
   - `git diff --stat` : résumé des changements
   - Demander : "Commit avant checkpoint ? [Y/n]"

2. **Si commit accepté** :
   - Générer un message de commit cohérent avec les changements
   - Format : `<type>(<scope>): <description>`
   - Exécuter `git add -A && git commit -m "..."` après validation

3. **Générer un résumé de session** :
   ```markdown
   # Checkpoint — <date> <heure>
   
   ## Session summary
   [3-5 phrases : ce qui a été fait, où on en est]
   
   ## État du code
   - Branche : <branche>
   - Dernier commit : <hash> "<message>"
   - Tests : ✅ pass / ❌ X échecs
   - Build : ✅ ok / ❌ cassé
   
   ## En cours
   [Ce qui n'est pas fini, à reprendre]
   
   ## Prochaines étapes
   1. [étape 1]
   2. [étape 2]
   3. [étape 3]
   
   ## Décisions prises (à mémoriser)
   - [décision]
   - [décision]
   
   ## Problèmes ouverts
   - [problème non résolu]
   ```

4. **Sauvegarder** dans :
   - `~/.claude/checkpoints/<projet>/<date>-<slug>.md`
   - Et optionnellement dans `CHECKPOINTS.md` à la racine du projet (pour partage équipe)

5. **Suggérer** :
   - "Tu peux maintenant `/clear` pour partir clean ou `/compact` pour garder le contexte essentiel"
   - "À la reprise : lire le checkpoint avant de relancer claude code"

Cas d'usage :
- Fin de journée
- Avant interruption (réunion, urgence client)
- Avant changement de tâche majeur
- Avant un test risqué (DB migration, refactor large)

Le checkpoint est complémentaire au hook `memory-persistence` :
- Hook : automatique, légèr, contexte volatile
- Checkpoint : manuel, détaillé, point structuré pour reprise
