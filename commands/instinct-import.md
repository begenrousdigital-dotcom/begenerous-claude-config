---
description: Importe un instinct depuis un fichier markdown partagé (par exemple par un autre dev)
argument-hint: [path/to/instinct.md] [--scope global|<project-name>]
---

Importe un instinct depuis $ARGUMENTS.

Workflow :

1. Lire le fichier markdown fourni
2. Valider le format frontmatter YAML (id, title, trigger, confidence requis)
3. Demander la confirmation : montrer le contenu à l'utilisateur, demander :
   - "Importer cet instinct ? [Y/n]"
   - "Scope : global ou projet spécifique ?"
   - "Confiance initiale : garder celle du fichier ou reset à 0.5 (importé non validé) ?"
4. Sauvegarder dans `~/.claude/instincts/[scope]/`
5. Ajouter une note dans le frontmatter :
   ```yaml
   imported_from: <fichier source>
   imported_at: <date>
   imported_confidence: 0.5  # reset car non validé sur ton workflow
   ```
6. Confirmer l'import

Validation :
- Si `id` collision avec instinct existant : demander si remplacer ou skip
- Si format invalide : afficher erreurs et abandonner
- Si pas de TTL pending : marquer status "pending" pour 30j de validation

Bonne pratique : ne jamais importer aveuglément. Un instinct utile pour un autre dev peut être contre-productif sur ton workflow. Reset confiance à 0.5 et laisser ton expérience le valider/invalider.
