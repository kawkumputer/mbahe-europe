-- ============================================================
-- Marquer tous les membres existants comme ayant payé l'adhésion
-- Date de paiement : 1er janvier 2025
-- Ces adhésions étaient déjà incluses dans le montant des années précédentes
-- ============================================================

UPDATE profiles
SET 
  adhesion_paid = TRUE,
  adhesion_paid_at = '2025-01-01T00:00:00Z',
  adhesion_amount = 10.00
WHERE status = 'approved';

-- ============================================================
-- TERMINÉ
-- ============================================================
