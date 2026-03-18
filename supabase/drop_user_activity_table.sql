-- ============================================================
-- Supprimer la table user_activity (plus nécessaire)
-- ============================================================

-- Supprimer les politiques RLS
DROP POLICY IF EXISTS "Les utilisateurs peuvent voir leur propre activité" ON user_activity;
DROP POLICY IF EXISTS "Les admins peuvent voir toutes les activités" ON user_activity;

-- Supprimer la table
DROP TABLE IF EXISTS user_activity CASCADE;

-- ============================================================
-- TERMINÉ
-- ============================================================
