---
description: Exporte un ou plusieurs instincts vers un fichier markdown partageable
argument-hint: [--scope global|<project>] [--min-confidence 0.8] [--output ./shared/]
---

Exporte les instincts selon $ARGUMENTS.

Workflow :

1. Filtrer les instincts selon les critères :
   - Scope : `global`, projet spécifique, ou `all`
   - Confiance minimale (default 0.8 pour ne partager que les solides)
   - Status : `active` uniquement (pas pending/archived)

2. Pour chaque instinct sélectionné, anonymiser si nécessaire :
   - Retirer les références à des projets clients spécifiques (Edirex, RealEstimate, BrickInvest)
   - Retirer les chemins absolus locaux
   - Retirer les noms propres (collègues, clients)
   - Garder uniquement la valeur générique du pattern

3. Générer un fichier markdown unique :
   ```
   begenerous-instincts-export-<date>.md
   ```
   
   Avec en tête :
   ```yaml
   ---
   exported_from: BeGenerous Digital
   exported_at: <date>
   instincts_count: <N>
   min_confidence: 0.8
   ---
   ```

4. Confirmer l'export et donner le chemin du fichier généré.

Le fichier exporté peut être :
- Partagé en privé avec d'autres devs
- Versionné dans un repo public d'instincts génériques
- Utilisé en input de `/instinct-import` sur une autre machine

Toujours demander confirmation avant export. Anonymiser par défaut.
