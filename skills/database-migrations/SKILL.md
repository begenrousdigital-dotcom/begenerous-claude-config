---
name: database-migrations
description: Patterns pour gérer les migrations de schéma DB avec Supabase. Migrations réversibles, RLS systématique, rollback safety, migrations zéro-downtime. Critique pour Edirex (19 tables) et tout projet en production.
---

# Database Migrations (Supabase)

## Principe directeur

**Toute migration doit être :**
1. Réversible (script DOWN présent et testé)
2. Sûre en prod (pas de lock prolongé sur grandes tables)
3. RLS-aware (policies dans la même migration que la table)
4. Testée localement avant push

## Workflow Supabase

### Setup local

```bash
# Linker le projet (une fois)
pnpm supabase link --project-ref xxxxxx

# Pull le schéma actuel
pnpm supabase db pull

# Démarrer Supabase local
pnpm supabase start

# Appliquer les migrations en local
pnpm supabase db reset
```

### Créer une migration

```bash
# Génère un fichier timestamped dans supabase/migrations/
pnpm supabase migration new add_quotes_table
```

→ Fichier créé : `supabase/migrations/20260429120000_add_quotes_table.sql`

### Appliquer en local + tester

```bash
pnpm supabase db reset --debug
# → Recrée la DB locale avec toutes les migrations
```

### Régénérer les types TS

```bash
pnpm supabase gen types typescript --linked > types/database.ts
```

### Push vers prod

```bash
pnpm supabase db push
```

## Pattern : nouvelle table avec RLS

```sql
-- supabase/migrations/20260429120000_add_quotes_table.sql

-- =====================
-- UP
-- =====================

CREATE TABLE quotes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_request_id uuid NOT NULL REFERENCES service_requests(id) ON DELETE CASCADE,
  artisan_id uuid NOT NULL REFERENCES artisans(id) ON DELETE CASCADE,
  amount numeric(10,2) NOT NULL CHECK (amount > 0),
  description text NOT NULL CHECK (length(description) >= 10),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes (FK + colonnes de filtre fréquent)
CREATE INDEX idx_quotes_service_request_id ON quotes(service_request_id);
CREATE INDEX idx_quotes_artisan_id ON quotes(artisan_id);
CREATE INDEX idx_quotes_status_created ON quotes(status, created_at DESC);

-- Trigger updated_at automatique
CREATE TRIGGER set_quotes_updated_at
  BEFORE UPDATE ON quotes
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- =====================
-- RLS — OBLIGATOIRE
-- =====================

ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;

-- Artisans peuvent voir leurs propres devis
CREATE POLICY "artisan_select_own_quotes" ON quotes
  FOR SELECT
  USING (
    artisan_id IN (
      SELECT id FROM artisans WHERE user_id = auth.uid()
    )
  );

-- Clients peuvent voir les devis sur leurs requêtes
CREATE POLICY "client_select_quotes_for_own_requests" ON quotes
  FOR SELECT
  USING (
    service_request_id IN (
      SELECT id FROM service_requests WHERE client_user_id = auth.uid()
    )
  );

-- Artisans peuvent créer des devis (vérification cohérence artisan_id)
CREATE POLICY "artisan_insert_own_quotes" ON quotes
  FOR INSERT
  WITH CHECK (
    artisan_id IN (
      SELECT id FROM artisans WHERE user_id = auth.uid()
    )
  );

-- Artisans peuvent modifier leurs devis pending
CREATE POLICY "artisan_update_own_pending_quotes" ON quotes
  FOR UPDATE
  USING (
    artisan_id IN (SELECT id FROM artisans WHERE user_id = auth.uid())
    AND status = 'pending'
  );

-- =====================
-- DOWN (rollback)
-- =====================

-- À sauvegarder à part dans supabase/migrations/down/...
-- DROP TABLE IF EXISTS quotes CASCADE;
```

## Pattern : ajout de colonne (zéro-downtime)

### Phase 1 : ajouter en nullable

```sql
-- migration_001
ALTER TABLE artisans ADD COLUMN business_email text;
```

### Phase 2 : backfill en batch

```sql
-- migration_002 — UPDATE en batch pour éviter long lock
DO $$
DECLARE
  batch_size int := 1000;
BEGIN
  LOOP
    UPDATE artisans
    SET business_email = email
    WHERE business_email IS NULL
      AND id IN (
        SELECT id FROM artisans 
        WHERE business_email IS NULL 
        LIMIT batch_size
      );
    
    EXIT WHEN NOT FOUND;
    
    -- Pause pour laisser respirer le système
    PERFORM pg_sleep(0.1);
  END LOOP;
END $$;
```

### Phase 3 : rendre NOT NULL (après déploiement code qui populate)

```sql
-- migration_003
ALTER TABLE artisans ALTER COLUMN business_email SET NOT NULL;
```

## Pattern : supprimer une colonne (zéro-downtime)

### Phase 1 : déprécier dans le code (ne plus écrire)

Code applicatif : ne plus écrire dans `old_column`. Toujours lire `new_column`.

### Phase 2 : copie de safety si nécessaire

```sql
-- migration_xxx
UPDATE table_x SET new_column = old_column WHERE new_column IS NULL;
```

### Phase 3 : drop après validation (1-2 sprints plus tard)

```sql
ALTER TABLE table_x DROP COLUMN old_column;
```

⚠️ Jamais en une seule migration : risque de breaking si rollback de code applicatif.

## Pattern : changement de type de colonne

```sql
-- ❌ Lock long sur grandes tables :
ALTER TABLE large_table ALTER COLUMN amount TYPE bigint;

-- ✅ Approche zéro-downtime :
-- Step 1: nouvelle colonne
ALTER TABLE large_table ADD COLUMN amount_new bigint;

-- Step 2: trigger pour sync
CREATE OR REPLACE FUNCTION sync_amount() RETURNS trigger AS $$
BEGIN
  NEW.amount_new := NEW.amount;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_amount BEFORE INSERT OR UPDATE ON large_table
  FOR EACH ROW EXECUTE FUNCTION sync_amount();

-- Step 3: backfill en batch
-- Step 4: switch code applicatif vers amount_new
-- Step 5: drop old amount + rename
```

## Helpers à avoir dès la migration 0

```sql
-- supabase/migrations/00000000000000_init_helpers.sql

-- Trigger updated_at générique
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Helper : vérifier qu'un user appartient à une org
CREATE OR REPLACE FUNCTION public.user_belongs_to_org(target_org_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM org_members 
    WHERE user_id = auth.uid() AND org_id = target_org_id
  );
$$;
```

## Vérifier avant push

```bash
# 1. Schema diff
pnpm supabase db diff

# 2. Test local complet
pnpm supabase db reset --debug
pnpm test

# 3. Vérifier les RLS policies
psql $DATABASE_URL -c "
  SELECT tablename, count(*) as policies
  FROM pg_policies
  WHERE schemaname = 'public'
  GROUP BY tablename
  ORDER BY policies;
"
# → Toute table sans policies est suspecte

# 4. Vérifier les indexes sur FK
psql $DATABASE_URL -c "
  SELECT c.conname, c.conrelid::regclass
  FROM pg_constraint c
  WHERE c.contype = 'f'
    AND NOT EXISTS (
      SELECT 1 FROM pg_index i
      WHERE i.indrelid = c.conrelid
        AND c.conkey[1] = ANY(i.indkey)
    );
"
# → FK sans index = DELETE/UPDATE lents
```

## Migrations de prod — checklist

- [ ] Migration testée localement (`db reset` complet + tests applicatifs)
- [ ] DOWN migration écrite et testée
- [ ] RLS activée + policies présentes (si nouvelle table)
- [ ] Indexes sur FK + colonnes de filtre fréquent
- [ ] Pas de lock long anticipé (analyser pour grandes tables)
- [ ] Backfill en batch si > 100k rows
- [ ] Backup de prod fait avant
- [ ] Communiquer aux autres devs si migration breaking
- [ ] Re-générer `database.types.ts` après push

## Anti-patterns

### 🚨 Migration sans DOWN
```sql
-- ❌ Comment on rollback si bug en prod ?
ALTER TABLE users DROP COLUMN email;
```

### 🚨 RLS oubliée
```sql
-- ❌ Table accessible à tous les users authentifiés
CREATE TABLE secrets (...);
```

### 🚨 Big UPDATE en prod
```sql
-- ❌ Locke la table pendant des minutes
UPDATE huge_table SET status = 'archived' WHERE created_at < now() - interval '1 year';
```

### 🚨 Migration qui dépend de code applicatif
```sql
-- ❌ Si rollback code, migration casse
ALTER TABLE x DROP COLUMN old_field;
-- Devrait être en 2 phases : déprécier code, puis drop column.
```

## Combinaison avec subscription Supabase Realtime

Si tu utilises Supabase Realtime sur la table :

```sql
-- Activer la replication pour realtime
ALTER PUBLICATION supabase_realtime ADD TABLE quotes;
```

⚠️ Vérifier que les RLS policies couvrent les events realtime (ils sont filtrés via les mêmes policies).
