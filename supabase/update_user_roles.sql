-- Script pour modifier les rôles d'un utilisateur existant par association
-- Remplacer les valeurs selon vos besoins

-- ============================================================
-- OPTION 1: Modifier par nom d'utilisateur (username)
-- ============================================================

-- Exemple: Hamath Kane - Admin dans "jeunes", Membre dans "general"
UPDATE profiles
SET 
  association_types = ARRAY['general', 'jeunes'],
  association_roles = jsonb_build_object(
    'general', 'member',
    'jeunes', 'admin'
  )
WHERE username = 'hamath.kane';  -- Remplacer par le username

-- ============================================================
-- OPTION 2: Modifier par téléphone
-- ============================================================

-- Exemple: Admin dans "general", Membre dans "jeunes"
UPDATE profiles
SET 
  association_types = ARRAY['general', 'jeunes'],
  association_roles = jsonb_build_object(
    'general', 'admin',
    'jeunes', 'member'
  )
WHERE phone = '+221771234567';  -- Remplacer par le numéro de téléphone

-- ============================================================
-- OPTION 3: Modifier par nom et prénom
-- ============================================================

UPDATE profiles
SET 
  association_types = ARRAY['general', 'jeunes'],
  association_roles = jsonb_build_object(
    'general', 'member',
    'jeunes', 'admin'
  )
WHERE first_name = 'Saidou' AND last_name = 'Ba';  -- Remplacer par le nom

-- ============================================================
-- OPTION 4: Modifier uniquement le rôle d'une association spécifique
-- (sans toucher aux autres associations)
-- ============================================================

-- Définir comme admin pour l'association "jeunes"
UPDATE profiles
SET association_roles = jsonb_set(
  COALESCE(association_roles, '{}'::jsonb),
  ARRAY['jeunes'],
  '"admin"'::jsonb
)
WHERE username = 'hamath.kane';

-- Définir comme membre pour l'association "general"
UPDATE profiles
SET association_roles = jsonb_set(
  COALESCE(association_roles, '{}'::jsonb),
  ARRAY['general'],
  '"member"'::jsonb
)
WHERE username = 'hamath.kane';

-- ============================================================
-- OPTION 5: Ajouter une nouvelle association avec un rôle
-- ============================================================

UPDATE profiles
SET 
  -- Ajouter "jeunes" aux associations existantes
  association_types = array_append(association_types, 'jeunes'),
  -- Définir le rôle pour cette nouvelle association
  association_roles = jsonb_set(
    COALESCE(association_roles, '{}'::jsonb),
    ARRAY['jeunes'],
    '"admin"'::jsonb
  )
WHERE username = 'hamath.kane'
  AND NOT ('jeunes' = ANY(association_types));  -- Éviter les doublons

-- ============================================================
-- EXEMPLES DE RÔLES POSSIBLES
-- ============================================================
-- 'member'    -> Membre simple
-- 'admin'     -> Administrateur
-- 'sys_admin' -> Super administrateur

-- ============================================================
-- VÉRIFIER LES MODIFICATIONS
-- ============================================================

-- Voir tous les utilisateurs avec leurs rôles par association
SELECT 
  first_name,
  last_name,
  username,
  phone,
  association_types,
  association_roles,
  association_roles->>'general' as role_general,
  association_roles->>'jeunes' as role_jeunes
FROM profiles
WHERE association_types && ARRAY['jeunes']  -- Utilisateurs ayant au moins "jeunes"
ORDER BY first_name, last_name;

-- Voir un utilisateur spécifique
SELECT 
  first_name,
  last_name,
  username,
  association_types,
  association_roles
FROM profiles
WHERE username = 'hamath.kane';  -- Remplacer par le username recherché
