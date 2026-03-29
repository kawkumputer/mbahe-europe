-- ============================================================
-- Script de diagnostic pour comprendre le problème RLS
-- ============================================================

-- 1. Vérifier les politiques RLS actuelles sur profiles
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;

-- 2. Vérifier les données de l'admin (Abda Ly)
SELECT 
  id,
  first_name,
  last_name,
  role,
  association_types,
  association_roles
FROM profiles
WHERE first_name = 'Abda' AND last_name = 'Ly';

-- 3. Vérifier les données du membre (Khadijetou Diallo)
SELECT 
  id,
  first_name,
  last_name,
  role,
  status,
  association_types,
  association_roles
FROM profiles
WHERE first_name = 'Khadijetou' AND last_name = 'Diallo';

-- 4. Tester si les associations se chevauchent
SELECT 
  admin.first_name as admin_name,
  admin.association_types as admin_assoc,
  member.first_name as member_name,
  member.association_types as member_assoc,
  admin.association_types && member.association_types as has_overlap,
  admin.association_types @> member.association_types as admin_contains_all,
  member.association_types <@ admin.association_types as member_subset_of_admin
FROM profiles admin, profiles member
WHERE admin.first_name = 'Abda' AND admin.last_name = 'Ly'
AND member.first_name = 'Khadijetou' AND member.last_name = 'Diallo';

-- 5. Vérifier si RLS est activé sur la table profiles
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'profiles';

-- 6. Test : essayer de mettre à jour directement (en tant que service_role)
-- ATTENTION : Cette requête va réussir car elle bypass RLS
-- UPDATE profiles 
-- SET status = 'approved'
-- WHERE first_name = 'Khadijetou' AND last_name = 'Diallo';

-- 7. Afficher toutes les politiques pour voir s'il y a des conflits
SELECT 
  policyname,
  cmd,
  permissive,
  qual IS NOT NULL as has_using,
  with_check IS NOT NULL as has_with_check
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY cmd, policyname;
