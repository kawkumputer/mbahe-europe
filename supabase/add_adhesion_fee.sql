-- ============================================================
-- Ajouter les champs frais d'adhésion dans la table profiles
-- Chaque membre doit payer 10€ de frais d'adhésion
-- ============================================================

-- Ajouter les colonnes
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS adhesion_paid BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS adhesion_paid_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS adhesion_amount DECIMAL(10,2) DEFAULT 10.00;

-- ============================================================
-- TERMINÉ
-- ============================================================
