-- Script pour tester le multi-associations
-- Exécuter dans l'éditeur SQL de Supabase

-- 1. Voir tous les utilisateurs et leurs associations actuelles
SELECT id, first_name, last_name, phone, association_types 
FROM profiles 
ORDER BY created_at DESC;

-- 2. Ajouter un utilisateur spécifique aux deux associations
-- Remplace 'USER_ID_ICI' par l'ID de ton utilisateur (visible dans la requête ci-dessus)
UPDATE profiles 
SET association_types = '{general, jeunes}' 
WHERE id = 'dd4fd17-2df3-4212-a17d-4f9ccd1b1b3a';

-- 3. Vérifier que la mise à jour a fonctionné
SELECT id, first_name, last_name, phone, association_types 
FROM profiles 
WHERE id = 'dd4fd17-2df3-4212-a17d-4f9ccd1b1b3a';

-- 4. (Optionnel) Remettre l'utilisateur à une seule association
-- UPDATE profiles 
-- SET association_types = '{general}' 
-- WHERE id = 'dd4fd17-2df3-4212-a17d-4f9ccd1b1b3a';
