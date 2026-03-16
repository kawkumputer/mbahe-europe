-- ============================================================
-- Migration: Ajout des fonctionnalités de profil utilisateur
-- À exécuter dans l'éditeur SQL de Supabase
-- ============================================================

-- 1. Ajouter les colonnes de profil à la table profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS photo_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

-- 2. Créer le bucket de stockage pour les photos de profil
-- (À faire manuellement dans l'interface Supabase Storage)
-- Nom du bucket: profile-photos
-- Public: true

-- 3. Table d'historique d'activité utilisateur
CREATE TABLE IF NOT EXISTS user_activity (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL CHECK (action_type IN ('login', 'profile_update', 'cotisation_paid', 'role_changed', 'status_changed', 'account_created')),
  description TEXT NOT NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE user_activity ENABLE ROW LEVEL SECURITY;

-- Chaque utilisateur peut voir son propre historique, les admins voient tout
CREATE POLICY "Activity: lecture propre historique"
  ON user_activity FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Insertion par le système (admin ou utilisateur concerné)
CREATE POLICY "Activity: insertion par système"
  ON user_activity FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE INDEX IF NOT EXISTS idx_user_activity_user ON user_activity(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_activity_type ON user_activity(action_type);

-- 4. Fonction pour enregistrer une activité
CREATE OR REPLACE FUNCTION log_user_activity(
  p_user_id UUID,
  p_action_type TEXT,
  p_description TEXT,
  p_metadata JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  activity_id UUID;
BEGIN
  INSERT INTO user_activity (user_id, action_type, description, metadata)
  VALUES (p_user_id, p_action_type, p_description, p_metadata)
  RETURNING id INTO activity_id;
  
  RETURN activity_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Trigger pour mettre à jour updated_at sur profiles
CREATE OR REPLACE FUNCTION update_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS profiles_updated_at ON profiles;
CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_profiles_updated_at();

-- 6. Enregistrer l'activité de création de compte pour les utilisateurs existants
INSERT INTO user_activity (user_id, action_type, description, created_at)
SELECT id, 'account_created', 'Compte créé', created_at
FROM profiles
WHERE NOT EXISTS (
  SELECT 1 FROM user_activity 
  WHERE user_activity.user_id = profiles.id 
  AND action_type = 'account_created'
);
