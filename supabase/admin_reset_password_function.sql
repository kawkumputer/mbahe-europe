-- ============================================================
-- Fonction pour réinitialiser le mot de passe d'un utilisateur
-- À exécuter dans l'éditeur SQL de Supabase
-- ============================================================

-- Activer l'extension pgcrypto dans le schéma extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- Cette fonction permet aux admins de réinitialiser le mot de passe d'un utilisateur
-- Elle utilise les extensions Supabase pour modifier le mot de passe de manière sécurisée

CREATE OR REPLACE FUNCTION admin_reset_user_password(
  target_user_id UUID,
  new_password TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  current_user_role TEXT;
  hashed_password TEXT;
BEGIN
  -- Vérifier que l'utilisateur actuel est un admin ou sys_admin
  SELECT role INTO current_user_role
  FROM profiles
  WHERE id = auth.uid();

  IF current_user_role NOT IN ('admin', 'sys_admin') THEN
    RAISE EXCEPTION 'Unauthorized: Only admins can reset passwords';
  END IF;

  -- Hasher le mot de passe avec pgcrypto
  hashed_password := extensions.crypt(new_password, extensions.gen_salt('bf'));

  -- Mettre à jour le mot de passe dans auth.users
  UPDATE auth.users
  SET 
    encrypted_password = hashed_password,
    updated_at = now()
  WHERE id = target_user_id;

  -- Vérifier que la mise à jour a réussi
  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error resetting password: %', SQLERRM;
END;
$$;

-- Accorder les permissions d'exécution aux utilisateurs authentifiés
GRANT EXECUTE ON FUNCTION admin_reset_user_password(UUID, TEXT) TO authenticated;

-- ============================================================
-- TERMINÉ
-- ============================================================
