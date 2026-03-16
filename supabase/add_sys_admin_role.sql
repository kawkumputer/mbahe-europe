-- ============================================================
-- Script pour ajouter le rôle sys_admin
-- À exécuter dans l'éditeur SQL de Supabase
-- ============================================================

-- 1. Modifier la contrainte CHECK pour ajouter sys_admin
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check 
  CHECK (role IN ('admin', 'member', 'sys_admin'));

-- 2. Supprimer les anciennes politiques RLS
DROP POLICY IF EXISTS "Profiles: mise à jour par admin" ON profiles;
DROP POLICY IF EXISTS "Cotisations: insertion par admin" ON cotisations;
DROP POLICY IF EXISTS "Cotisations: mise à jour par admin" ON cotisations;
DROP POLICY IF EXISTS "Comptes rendus: insertion par admin" ON comptes_rendus;
DROP POLICY IF EXISTS "Comptes rendus: mise à jour par admin" ON comptes_rendus;
DROP POLICY IF EXISTS "Comptes rendus: suppression par admin" ON comptes_rendus;

-- 3. Créer les nouvelles politiques RLS avec support sys_admin
CREATE POLICY "Profiles: mise à jour par admin"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND (role = 'admin' OR role = 'sys_admin'))
  );

CREATE POLICY "Cotisations: insertion par admin"
  ON cotisations FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND (role = 'admin' OR role = 'sys_admin'))
  );

CREATE POLICY "Cotisations: mise à jour par admin"
  ON cotisations FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND (role = 'admin' OR role = 'sys_admin'))
  );

CREATE POLICY "Comptes rendus: insertion par admin"
  ON comptes_rendus FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND (role = 'admin' OR role = 'sys_admin'))
  );

CREATE POLICY "Comptes rendus: mise à jour par admin"
  ON comptes_rendus FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND (role = 'admin' OR role = 'sys_admin'))
  );

CREATE POLICY "Comptes rendus: suppression par admin"
  ON comptes_rendus FOR DELETE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND (role = 'admin' OR role = 'sys_admin'))
  );

-- 4. Créer un compte sys_admin (exemple)
-- IMPORTANT: Remplacez les valeurs ci-dessous par vos propres informations
-- Vous devez d'abord créer le compte dans Supabase Auth, puis mettre à jour le profil

-- Exemple de mise à jour d'un profil existant en sys_admin:
-- UPDATE profiles 
-- SET role = 'sys_admin', status = 'approved'
-- WHERE phone = '+33600000000';  -- Remplacez par le téléphone du sys_admin

-- ============================================================
-- TERMINÉ
-- ============================================================
