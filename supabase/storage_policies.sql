-- ============================================================
-- Script: Configuration des politiques RLS pour le stockage
-- À exécuter dans l'éditeur SQL de Supabase
-- ============================================================

-- 1. Créer le bucket 'profile-photos' s'il n'existe pas déjà
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-photos', 'profile-photos', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Supprimer les anciennes politiques si elles existent
DROP POLICY IF EXISTS "Users can upload their own profile photo" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile photo" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile photo" ON storage.objects;
DROP POLICY IF EXISTS "Public can view profile photos" ON storage.objects;

-- 3. Politique: Les utilisateurs peuvent uploader leur propre photo
CREATE POLICY "Users can upload their own profile photo"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-photos' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 4. Politique: Les utilisateurs peuvent mettre à jour leur propre photo
CREATE POLICY "Users can update their own profile photo"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-photos' 
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'profile-photos' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 5. Politique: Les utilisateurs peuvent supprimer leur propre photo
CREATE POLICY "Users can delete their own profile photo"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-photos' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 6. Politique: Tout le monde peut voir les photos de profil (bucket public)
CREATE POLICY "Public can view profile photos"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile-photos');

-- 7. Vérifier que les politiques sont bien créées
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'objects'
AND policyname LIKE '%profile photo%';

-- ============================================================
-- NOTES:
-- ============================================================
-- - Le bucket 'profile-photos' est public (les URLs sont accessibles)
-- - Les fichiers doivent être uploadés dans un dossier nommé avec l'ID de l'utilisateur
-- - Format du chemin: profile-photos/{user_id}/photo.jpg
-- - Seul le propriétaire peut uploader/modifier/supprimer sa photo
-- - Tout le monde peut voir les photos (lecture publique)
-- ============================================================
