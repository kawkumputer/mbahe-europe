-- ============================================================
-- Migration: Ajout du système d'authentification par username
-- À exécuter dans l'éditeur SQL de Supabase
-- ============================================================

-- 1. Ajouter la colonne username à la table profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS username TEXT UNIQUE;

-- 2. Créer un index sur username pour optimiser les recherches
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);

-- 3. Ajouter une contrainte pour valider le format du username
-- (lettres, chiffres, underscore, tiret, 3-20 caractères)
ALTER TABLE profiles ADD CONSTRAINT username_format 
  CHECK (username ~ '^[a-zA-Z0-9_-]{3,20}$');

-- 4. Modifier le trigger handle_new_user pour inclure le username
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, first_name, last_name, phone, username, role, status)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'username', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'member'),
    'pending'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Fonction pour vérifier si un username existe déjà
CREATE OR REPLACE FUNCTION check_username_exists(p_username TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM profiles WHERE username = p_username);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Politique RLS pour permettre la lecture publique des usernames (pour vérification)
-- (Les autres politiques RLS existantes restent inchangées)

-- 7. Générer des usernames pour les utilisateurs existants (optionnel)
-- Format: prenom_numero (ex: kane_92, baba_45)
-- Cette partie peut être exécutée manuellement si nécessaire
/*
UPDATE profiles 
SET username = LOWER(first_name) || '_' || FLOOR(RANDOM() * 100)::TEXT
WHERE username IS NULL OR username = '';
*/
