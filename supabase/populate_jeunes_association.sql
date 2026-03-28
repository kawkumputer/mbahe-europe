-- Script pour peupler l'association Jeunes avec des membres de test
-- Exécuter dans l'éditeur SQL de Supabase

-- 1. Voir la répartition actuelle des membres par association
SELECT 
  CASE 
    WHEN 'general' = ANY(association_types) AND 'jeunes' = ANY(association_types) THEN 'Les deux'
    WHEN 'general' = ANY(association_types) THEN 'General seulement'
    WHEN 'jeunes' = ANY(association_types) THEN 'Jeunes seulement'
    ELSE 'Aucune'
  END as association,
  COUNT(*) as nombre
FROM profiles
WHERE status = 'approved'
GROUP BY 
  CASE 
    WHEN 'general' = ANY(association_types) AND 'jeunes' = ANY(association_types) THEN 'Les deux'
    WHEN 'general' = ANY(association_types) THEN 'General seulement'
    WHEN 'jeunes' = ANY(association_types) THEN 'Jeunes seulement'
    ELSE 'Aucune'
  END;

-- 2. Ajouter 10 membres à l'association Jeunes (en plus de General)
UPDATE profiles 
SET association_types = '{general, jeunes}' 
WHERE id IN (
  SELECT id FROM profiles 
  WHERE status = 'approved' 
  AND role = 'member'
  AND NOT ('jeunes' = ANY(association_types))
  ORDER BY created_at DESC
  LIMIT 10
);

-- 3. Créer 5 membres UNIQUEMENT pour l'association Jeunes
UPDATE profiles 
SET association_types = '{jeunes}' 
WHERE id IN (
  SELECT id FROM profiles 
  WHERE status = 'approved' 
  AND role = 'member'
  AND 'general' = ANY(association_types)
  ORDER BY created_at ASC
  LIMIT 5
);

-- 4. Vérifier la nouvelle répartition
SELECT 
  CASE 
    WHEN 'general' = ANY(association_types) AND 'jeunes' = ANY(association_types) THEN 'Les deux'
    WHEN 'general' = ANY(association_types) THEN 'General seulement'
    WHEN 'jeunes' = ANY(association_types) THEN 'Jeunes seulement'
    ELSE 'Aucune'
  END as association,
  COUNT(*) as nombre
FROM profiles
WHERE status = 'approved'
GROUP BY 
  CASE 
    WHEN 'general' = ANY(association_types) AND 'jeunes' = ANY(association_types) THEN 'Les deux'
    WHEN 'general' = ANY(association_types) THEN 'General seulement'
    WHEN 'jeunes' = ANY(association_types) THEN 'Jeunes seulement'
    ELSE 'Aucune'
  END;

-- 5. Voir quelques exemples de membres par association
SELECT first_name, last_name, association_types
FROM profiles
WHERE status = 'approved'
ORDER BY association_types, first_name
LIMIT 20;
