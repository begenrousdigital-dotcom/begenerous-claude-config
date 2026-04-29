---
description: Cluster les instincts liés et les promeut en skill formel
---

Analyse les instincts actuels et propose des regroupements en skills formels.

Workflow :

1. **Lire tous les instincts actifs** (`~/.claude/instincts/`)

2. **Clusteriser** par thème/sujet :
   - Patterns Next.js → cluster Next.js
   - Patterns Supabase → cluster Supabase
   - Patterns de workflow → cluster workflow
   - etc.

3. **Évaluer chaque cluster** :
   - Critères de promotion :
     - 3+ instincts dans le cluster
     - Confiance moyenne > 0.85
     - Validés sur 2+ projets différents
     - Pas de contradictions internes

4. **Proposer la promotion** :
   ```markdown
   ## Cluster détecté : "Supabase RLS patterns"
   
   ### Instincts concernés (5)
   - rls-on-table-create (0.95, 3 projets)
   - rls-multi-tenant-isolation (0.92, 2 projets)
   - rls-policy-naming-convention (0.90, 2 projets)
   - rls-recursive-policies-avoid (0.88, 2 projets)
   - rls-test-via-different-users (0.93, 3 projets)
   
   ### Skill proposé : `supabase-rls-patterns`
   
   [Aperçu du SKILL.md généré]
   
   Promouvoir ce cluster en skill ? [Y/n]
   ```

5. **Si confirmation** :
   - Créer `~/.claude/skills/<skill-name>/SKILL.md`
   - Marquer les instincts source en `status: promoted`
   - Conserver les instincts en archive (référence pour l'origine du skill)

6. **Si rejet** :
   - Garder les instincts comme actifs
   - Noter la date de proposition pour ne pas re-proposer trop tôt

Périodicité recommandée : lancer `/evolve` mensuellement, pas plus souvent.

Important :
- Ne **jamais** auto-promouvoir sans validation
- Le skill généré doit être éditable avant sauvegarde (vibe coder validation)
- Garder les instincts source en archive pour traçabilité
