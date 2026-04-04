-- ============================================================
-- Fonction pour réinitialiser le mot de passe d'un utilisateur (V2)
-- Utilise association_roles au lieu de l'ancienne colonne role
-- À exécuter dans l'éditeur SQL de Supabase
-- ============================================================

-- Activer l'extension pgcrypto dans le schéma extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- Cette fonction permet aux admins de réinitialiser le mot de passe d'un utilisateur
-- Elle utilise les association_roles pour vérifier les permissions par association

CREATE OR REPLACE FUNCTION admin_reset_user_password_v2(
  target_user_id UUID,
  new_password TEXT,
  association_type TEXT DEFAULT 'general'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  current_user_roles JSONB;
  hashed_password TEXT;
  is_admin BOOLEAN := FALSE;
BEGIN
  -- Récupérer les association_roles de l'utilisateur actuel
  SELECT association_roles INTO current_user_roles
  FROM profiles
  WHERE id = auth.uid();

  -- Vérifier que l'utilisateur actuel est admin pour l'association spécifiée
  IF current_user_roles IS NOT NULL THEN
    is_admin := (
      current_user_roles->>association_type = 'admin' OR
      current_user_roles->>'sys_admin' = 'sys_admin'
    );
  END IF;

  -- Pour compatibilité, vérifier aussi l'ancienne colonne role si association_type est NULL
  IF NOT is_admin AND association_type = 'general' THEN
    DECLARE
      current_user_role TEXT;
    BEGIN
      SELECT role INTO current_user_role
      FROM profiles
      WHERE id = auth.uid();
      
      is_admin := current_user_role IN ('admin', 'sys_admin');
    END;
  END IF;

  IF NOT is_admin THEN
    RAISE EXCEPTION 'Unauthorized: Only admins can reset passwords for association %', association_type;
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
GRANT EXECUTE ON FUNCTION admin_reset_user_password_v2(UUID, TEXT, TEXT) TO authenticated;

-- ============================================================
-- TERMINÉ
-- ============================================================
