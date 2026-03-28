-- Migration pour ajouter les rôles par association
-- Un utilisateur peut avoir des rôles différents selon l'association

-- 1. Ajouter une colonne pour stocker les rôles par association (JSONB)
-- Format: {"general": "admin", "jeunes": "member"}
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS association_roles JSONB DEFAULT '{"general": "member"}'::jsonb;

-- 2. Migrer les rôles existants vers le nouveau format
-- Pour chaque utilisateur, copier son rôle actuel vers toutes ses associations
UPDATE profiles
SET association_roles = (
  SELECT jsonb_object_agg(assoc_type, role)
  FROM unnest(association_types) AS assoc_type
)
WHERE association_roles IS NULL OR association_roles = '{}'::jsonb;

-- 3. Créer une fonction pour obtenir le rôle d'un utilisateur pour une association donnée
CREATE OR REPLACE FUNCTION get_user_role_for_association(
  user_id UUID,
  assoc_type TEXT
) RETURNS TEXT AS $$
DECLARE
  user_role TEXT;
BEGIN
  SELECT association_roles->>assoc_type INTO user_role
  FROM profiles
  WHERE id = user_id;
  
  -- Si le rôle n'existe pas pour cette association, retourner 'member' par défaut
  RETURN COALESCE(user_role, 'member');
END;
$$ LANGUAGE plpgsql;

-- 4. Créer une fonction pour mettre à jour le rôle d'un utilisateur pour une association
CREATE OR REPLACE FUNCTION set_user_role_for_association(
  user_id UUID,
  assoc_type TEXT,
  new_role TEXT
) RETURNS VOID AS $$
BEGIN
  UPDATE profiles
  SET association_roles = jsonb_set(
    COALESCE(association_roles, '{}'::jsonb),
    ARRAY[assoc_type],
    to_jsonb(new_role)
  )
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- 5. Exemples d'utilisation:
-- Définir un utilisateur comme admin de l'association "jeunes" et membre de "general"
-- SELECT set_user_role_for_association('user-uuid-here', 'jeunes', 'admin');
-- SELECT set_user_role_for_association('user-uuid-here', 'general', 'member');

-- Obtenir le rôle d'un utilisateur pour une association
-- SELECT get_user_role_for_association('user-uuid-here', 'jeunes');

-- 6. Créer un index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_profiles_association_roles 
ON profiles USING gin(association_roles);

-- 7. Commentaires pour documentation
COMMENT ON COLUMN profiles.association_roles IS 
'Rôles de l''utilisateur par association. Format JSONB: {"general": "admin", "jeunes": "member"}';

COMMENT ON FUNCTION get_user_role_for_association IS 
'Obtient le rôle d''un utilisateur pour une association donnée';

COMMENT ON FUNCTION set_user_role_for_association IS 
'Définit le rôle d''un utilisateur pour une association donnée';
