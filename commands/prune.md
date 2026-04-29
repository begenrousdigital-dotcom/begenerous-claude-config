---
description: Nettoie les instincts pending non validés au-delà du TTL (30 jours par défaut)
argument-hint: [--ttl-days 30] [--dry-run]
---

Nettoie les instincts qui ne se sont pas confirmés.

Workflow :

1. **Lister les instincts pending** dans `~/.claude/instincts/pending/`

2. **Vérifier le TTL** (par défaut 30 jours) :
   - Date `created_at` du frontmatter
   - Si `created_at + TTL < today` → candidat à suppression
   - Si l'instinct a été activé/référencé depuis sa création → reset TTL

3. **Lister aussi les contradictions** :
   - Si 2 instincts actifs disent des choses opposées
   - Marquer comme "à arbitrer"

4. **Présenter pour validation** :
   ```markdown
   ## Pruning Report
   
   ### Pending expirés (X) — à supprimer
   - `instinct-foo` (créé il y a 32j, jamais activé)
   - `instinct-bar` (créé il y a 45j, jamais activé)
   
   ### Contradictions (X) — à arbitrer
   - `instinct-x` vs `instinct-y` :
     - x dit : "Toujours utiliser Server Actions"
     - y dit : "Préférer Route Handlers pour les mutations"
     → Quel garder ?
   
   ### Confiance dégradée (X) — à reset ou archiver
   - `instinct-z` : 5 dernières activations ont mené à des erreurs
     → Reset confiance à 0.3 ou archiver ?
   
   Procéder ? [Y/n]
   ```

5. **Si `--dry-run`** : juste afficher le rapport sans modifier
   **Sinon** : appliquer après confirmation

6. **Logging** :
   - Garder un log dans `~/.claude/instincts/pruning.log`
   - Format : `<date> <action> <instinct-id> <raison>`

Bonnes pratiques :
- Lancer mensuellement
- Toujours `--dry-run` d'abord
- Backup avant prune massif : `cp -r ~/.claude/instincts ~/.claude/instincts.backup-<date>`
