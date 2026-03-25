-- Fonction RPC pour supprimer le compte d'un utilisateur
-- Supprime toutes les données associées puis le compte auth
CREATE OR REPLACE FUNCTION delete_user_account(target_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Vérifier que l'utilisateur qui appelle est bien celui qui veut supprimer son compte
  IF auth.uid() IS NULL OR auth.uid() != target_user_id THEN
    RAISE EXCEPTION 'Non autorisé : vous ne pouvez supprimer que votre propre compte';
  END IF;

  -- Supprimer les notifications
  DELETE FROM notifications WHERE recipient_id = target_user_id;

  -- Supprimer les cotisations
  DELETE FROM cotisations WHERE user_id = target_user_id;

  -- Supprimer les dépenses créées par l'utilisateur
  DELETE FROM depenses WHERE created_by = target_user_id;

  -- Supprimer les photos de profil du storage
  DELETE FROM storage.objects 
  WHERE bucket_id = 'profile-photos' 
  AND name LIKE target_user_id::text || '/%';

  -- Supprimer le profil
  DELETE FROM profiles WHERE id = target_user_id;

  -- Supprimer le compte auth
  DELETE FROM auth.users WHERE id = target_user_id;
END;
$$;

-- Accorder l'accès à la fonction pour les utilisateurs authentifiés
GRANT EXECUTE ON FUNCTION delete_user_account(UUID) TO authenticated;
