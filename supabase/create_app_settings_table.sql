-- ============================================================
-- Table pour les paramètres de l'application
-- Accessible uniquement aux sys_admin
-- ============================================================

-- Créer la table app_settings
CREATE TABLE IF NOT EXISTS app_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_key TEXT UNIQUE NOT NULL,
  setting_value TEXT NOT NULL,
  description TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_by UUID REFERENCES profiles(id)
);

-- Insérer le paramètre pour le montant des années précédentes
INSERT INTO app_settings (setting_key, setting_value, description)
VALUES (
  'previous_years_total_amount',
  '0',
  'Montant total des cotisations des années précédentes (avant 2025) - cotisations papier'
)
ON CONFLICT (setting_key) DO NOTHING;

-- Activer RLS
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

-- Politique : Lecture pour tous les utilisateurs authentifiés
CREATE POLICY "Tous peuvent lire les paramètres"
  ON app_settings
  FOR SELECT
  TO authenticated
  USING (true);

-- Politique : Modification uniquement pour sys_admin
CREATE POLICY "Seuls les sys_admin peuvent modifier les paramètres"
  ON app_settings
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'sys_admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'sys_admin'
    )
  );

-- ============================================================
-- TERMINÉ
-- ============================================================
