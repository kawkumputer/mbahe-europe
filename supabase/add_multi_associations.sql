-- ============================================================
-- Migration: Support Multi-Associations (Général / Jeunes)
-- À exécuter dans l'éditeur SQL de Supabase (SQL Editor)
-- ============================================================

-- ============================================================
-- ÉTAPE 1: Ajouter la colonne association_types à la table profiles
-- ============================================================

-- Ajouter la colonne association_types (array pour multi-appartenance)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS association_types TEXT[] DEFAULT '{general}';

-- Mettre à jour les profils existants pour avoir 'general' par défaut
UPDATE profiles 
SET association_types = '{general}' 
WHERE association_types IS NULL OR association_types = '{}';

-- Ajouter une contrainte pour valider les valeurs
ALTER TABLE profiles
ADD CONSTRAINT check_association_types 
CHECK (
  association_types <@ ARRAY['general', 'jeunes']::TEXT[] 
  AND array_length(association_types, 1) > 0
);

-- ============================================================
-- ÉTAPE 2: Ajouter association_type aux cotisations
-- ============================================================

ALTER TABLE cotisations 
ADD COLUMN IF NOT EXISTS association_type TEXT DEFAULT 'general';

-- Mettre à jour les cotisations existantes
UPDATE cotisations 
SET association_type = 'general' 
WHERE association_type IS NULL;

-- Ajouter une contrainte
ALTER TABLE cotisations
ADD CONSTRAINT check_cotisation_association_type 
CHECK (association_type IN ('general', 'jeunes'));

-- Modifier la contrainte UNIQUE pour inclure association_type
ALTER TABLE cotisations 
DROP CONSTRAINT IF EXISTS cotisations_user_id_month_year_key;

ALTER TABLE cotisations 
ADD CONSTRAINT cotisations_user_id_month_year_association_key 
UNIQUE(user_id, month, year, association_type);

-- ============================================================
-- ÉTAPE 3: Ajouter association_type aux dépenses
-- ============================================================

ALTER TABLE depenses 
ADD COLUMN IF NOT EXISTS association_type TEXT DEFAULT 'general';

UPDATE depenses 
SET association_type = 'general' 
WHERE association_type IS NULL;

ALTER TABLE depenses
ADD CONSTRAINT check_depense_association_type 
CHECK (association_type IN ('general', 'jeunes'));

-- ============================================================
-- ÉTAPE 4: Ajouter association_type aux comptes rendus
-- ============================================================

ALTER TABLE comptes_rendus 
ADD COLUMN IF NOT EXISTS association_type TEXT DEFAULT 'general';

UPDATE comptes_rendus 
SET association_type = 'general' 
WHERE association_type IS NULL;

ALTER TABLE comptes_rendus
ADD CONSTRAINT check_compte_rendu_association_type 
CHECK (association_type IN ('general', 'jeunes'));

-- ============================================================
-- ÉTAPE 5: Ajouter association_type aux actualités
-- ============================================================

ALTER TABLE actualites 
ADD COLUMN IF NOT EXISTS association_type TEXT DEFAULT 'general';

UPDATE actualites 
SET association_type = 'general' 
WHERE association_type IS NULL;

ALTER TABLE actualites
ADD CONSTRAINT check_actualite_association_type 
CHECK (association_type IN ('general', 'jeunes'));

-- ============================================================
-- ÉTAPE 6: Ajouter association_type aux notifications
-- ============================================================

ALTER TABLE notifications 
ADD COLUMN IF NOT EXISTS association_type TEXT DEFAULT 'general';

UPDATE notifications 
SET association_type = 'general' 
WHERE association_type IS NULL;

ALTER TABLE notifications
ADD CONSTRAINT check_notification_association_type 
CHECK (association_type IN ('general', 'jeunes'));

-- ============================================================
-- ÉTAPE 7: Ajouter association_type aux documents
-- ============================================================

ALTER TABLE documents 
ADD COLUMN IF NOT EXISTS association_type TEXT DEFAULT 'general';

UPDATE documents 
SET association_type = 'general' 
WHERE association_type IS NULL;

ALTER TABLE documents
ADD CONSTRAINT check_document_association_type 
CHECK (association_type IN ('general', 'jeunes'));

-- Modifier la clé primaire pour inclure association_type
ALTER TABLE documents 
DROP CONSTRAINT IF EXISTS documents_pkey;

ALTER TABLE documents 
ADD CONSTRAINT documents_pkey 
PRIMARY KEY (id, association_type);

-- ============================================================
-- ÉTAPE 8: Ajouter association_type aux mandats
-- ============================================================

ALTER TABLE mandats 
ADD COLUMN IF NOT EXISTS association_type TEXT DEFAULT 'general';

UPDATE mandats 
SET association_type = 'general' 
WHERE association_type IS NULL;

ALTER TABLE mandats
ADD CONSTRAINT check_mandat_association_type 
CHECK (association_type IN ('general', 'jeunes'));

-- ============================================================
-- ÉTAPE 9: Ajouter association_type aux bureau_membres
-- ============================================================

ALTER TABLE bureau_membres 
ADD COLUMN IF NOT EXISTS association_type TEXT DEFAULT 'general';

UPDATE bureau_membres 
SET association_type = 'general' 
WHERE association_type IS NULL;

ALTER TABLE bureau_membres
ADD CONSTRAINT check_bureau_membre_association_type 
CHECK (association_type IN ('general', 'jeunes'));

-- ============================================================
-- ÉTAPE 10: Créer des index pour les performances
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_profiles_association_types ON profiles USING GIN(association_types);
CREATE INDEX IF NOT EXISTS idx_cotisations_association_type ON cotisations(association_type);
CREATE INDEX IF NOT EXISTS idx_depenses_association_type ON depenses(association_type);
CREATE INDEX IF NOT EXISTS idx_comptes_rendus_association_type ON comptes_rendus(association_type);
CREATE INDEX IF NOT EXISTS idx_actualites_association_type ON actualites(association_type);
CREATE INDEX IF NOT EXISTS idx_notifications_association_type ON notifications(association_type);
CREATE INDEX IF NOT EXISTS idx_mandats_association_type ON mandats(association_type);
CREATE INDEX IF NOT EXISTS idx_bureau_membres_association_type ON bureau_membres(association_type);

-- ============================================================
-- ÉTAPE 11: Modifier la fonction generate_cotisations pour supporter association_type
-- ============================================================

CREATE OR REPLACE FUNCTION public.generate_cotisations(
  p_user_id UUID, 
  p_year INTEGER,
  p_association_type TEXT DEFAULT 'general'
)
RETURNS VOID AS $$
DECLARE
  m INTEGER;
BEGIN
  FOR m IN 1..10 LOOP
    INSERT INTO cotisations (user_id, month, year, amount, status, association_type)
    VALUES (p_user_id, m, p_year, 10.0, 'unpaid', p_association_type)
    ON CONFLICT (user_id, month, year, association_type) DO NOTHING;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- ÉTAPE 12: Créer une table pour stocker l'association active de chaque utilisateur
-- ============================================================

CREATE TABLE IF NOT EXISTS user_active_association (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  active_association_type TEXT NOT NULL DEFAULT 'general' CHECK (active_association_type IN ('general', 'jeunes')),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE user_active_association ENABLE ROW LEVEL SECURITY;

-- Chaque utilisateur peut lire et modifier sa propre association active
CREATE POLICY "Users can read their own active association"
  ON user_active_association FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can update their own active association"
  ON user_active_association FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own active association"
  ON user_active_association FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- ============================================================
-- TERMINÉ
-- ============================================================
