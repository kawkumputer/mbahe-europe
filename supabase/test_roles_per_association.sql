-- Script de test pour les rôles par association
-- Exemple: Un utilisateur peut être admin dans "jeunes" et membre dans "general"

-- 1. Trouver un utilisateur existant (Hamath Kane par exemple)
DO $$
DECLARE
  user_id UUID;
BEGIN
  -- Récupérer l'ID de Hamath Kane
  SELECT id INTO user_id
  FROM profiles
  WHERE first_name = 'Hamath' AND last_name = 'Kane'
  LIMIT 1;

  IF user_id IS NOT NULL THEN
    -- Mettre à jour ses associations
    UPDATE profiles
    SET association_types = ARRAY['general', 'jeunes']
    WHERE id = user_id;

    -- Définir ses rôles par association
    -- Admin dans "jeunes", Membre dans "general"
    UPDATE profiles
    SET association_roles = jsonb_build_object(
      'general', 'member',
      'jeunes', 'admin'
    )
    WHERE id = user_id;

    RAISE NOTICE 'Utilisateur % configuré avec rôles: admin pour jeunes, member pour general', user_id;
  ELSE
    RAISE NOTICE 'Utilisateur Hamath Kane non trouvé';
  END IF;
END $$;

-- 2. Créer un utilisateur de test avec rôles différents
INSERT INTO profiles (
  id,
  first_name,
  last_name,
  phone,
  username,
  password,
  role,
  status,
  association_types,
  association_roles
) VALUES (
  gen_random_uuid(),
  'Test',
  'MultiRole',
  '+33612345678',
  'test.multirole',
  crypt('password123', gen_salt('bf')),
  'member', -- Rôle global par défaut
  'approved',
  ARRAY['general', 'jeunes'],
  jsonb_build_object(
    'general', 'admin',
    'jeunes', 'member'
  )
) ON CONFLICT (username) DO UPDATE
SET 
  association_types = ARRAY['general', 'jeunes'],
  association_roles = jsonb_build_object(
    'general', 'admin',
    'jeunes', 'member'
  );

-- 3. Vérifier les rôles
SELECT 
  first_name,
  last_name,
  association_types,
  association_roles,
  association_roles->>'general' as role_general,
  association_roles->>'jeunes' as role_jeunes
FROM profiles
WHERE association_types && ARRAY['jeunes']
ORDER BY first_name, last_name;

-- 4. Test de la fonction get_user_role_for_association
SELECT 
  first_name,
  last_name,
  get_user_role_for_association(id, 'general') as role_general,
  get_user_role_for_association(id, 'jeunes') as role_jeunes
FROM profiles
WHERE association_types && ARRAY['jeunes']
ORDER BY first_name, last_name;
