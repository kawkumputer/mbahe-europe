-- ============================================================
-- Créer la table depenses pour gérer les sorties d'argent
-- Workflow : admin crée → un AUTRE admin valide → visible par tous
-- ============================================================

-- 0. Supprimer si elle existe déjà (CASCADE supprime aussi les policies)
DROP TABLE IF EXISTS depenses CASCADE;

-- 1. Créer la table depenses
CREATE TABLE depenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  amount DECIMAL(10,2) NOT NULL,
  motif TEXT NOT NULL,
  description TEXT,
  depense_date DATE NOT NULL,
  
  -- Qui a créé la dépense
  created_by UUID NOT NULL REFERENCES profiles(id),
  created_by_name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Statut de validation
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  
  -- Qui a validé/rejeté
  validated_by UUID REFERENCES profiles(id),
  validated_by_name TEXT,
  validated_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT
);

-- 2. Activer RLS
ALTER TABLE depenses ENABLE ROW LEVEL SECURITY;

-- 3. Politique : Tous les membres authentifiés peuvent voir les dépenses validées
CREATE POLICY "Tous les membres peuvent voir les dépenses validées"
  ON depenses
  FOR SELECT
  TO authenticated
  USING (
    status = 'approved'
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'sys_admin')
    )
  );

-- 4. Politique : Les admins et sys_admin peuvent créer des dépenses
CREATE POLICY "Les admins peuvent créer des dépenses"
  ON depenses
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'sys_admin')
    )
  );

-- 5. Politique : Les admins et sys_admin peuvent mettre à jour les dépenses
CREATE POLICY "Les admins peuvent mettre à jour les dépenses"
  ON depenses
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'sys_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'sys_admin')
    )
  );

-- 6. Politique : Les admins peuvent supprimer les dépenses en attente
CREATE POLICY "Les admins peuvent supprimer les dépenses pending"
  ON depenses
  FOR DELETE
  TO authenticated
  USING (
    status = 'pending'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'sys_admin')
    )
  );

-- ============================================================
-- TERMINÉ
-- ============================================================
