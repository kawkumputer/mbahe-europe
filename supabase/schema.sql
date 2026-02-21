-- ============================================================
-- MBAHE Europe - Schéma Supabase
-- À exécuter dans l'éditeur SQL de Supabase (SQL Editor)
-- ============================================================

-- 1. Table des profils utilisateurs (liée à auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  phone TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Table des cotisations
CREATE TABLE IF NOT EXISTS cotisations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
  year INTEGER NOT NULL CHECK (year >= 2020),
  amount DOUBLE PRECISION NOT NULL DEFAULT 10.0,
  status TEXT NOT NULL DEFAULT 'unpaid' CHECK (status IN ('paid', 'unpaid', 'exempted')),
  paid_at TIMESTAMPTZ,
  payment_method TEXT CHECK (payment_method IN ('espece', 'virement', 'cheque')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, month, year)
);

-- 3. Table des comptes rendus
CREATE TABLE IF NOT EXISTS comptes_rendus (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('assembleeGenerale', 'bureau', 'extraordinaire')),
  reunion_date DATE NOT NULL,
  author_id UUID NOT NULL REFERENCES profiles(id),
  author_name TEXT NOT NULL,
  points TEXT[] NOT NULL DEFAULT '{}',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Row Level Security (RLS)
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE cotisations ENABLE ROW LEVEL SECURITY;
ALTER TABLE comptes_rendus ENABLE ROW LEVEL SECURITY;

-- Profiles: tout le monde peut lire, seul l'admin peut modifier le statut
CREATE POLICY "Profiles: lecture pour tous les authentifiés"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Profiles: insertion pour soi-même"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Profiles: mise à jour par soi-même"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Profiles: mise à jour par admin"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Cotisations: membres voient les leurs, admin voit tout
CREATE POLICY "Cotisations: lecture propres cotisations"
  ON cotisations FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Cotisations: insertion par admin"
  ON cotisations FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Cotisations: mise à jour par admin"
  ON cotisations FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Comptes rendus: lecture pour tous, écriture admin
CREATE POLICY "Comptes rendus: lecture pour tous"
  ON comptes_rendus FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Comptes rendus: insertion par admin"
  ON comptes_rendus FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Comptes rendus: mise à jour par admin"
  ON comptes_rendus FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Comptes rendus: suppression par admin"
  ON comptes_rendus FOR DELETE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ============================================================
-- Fonction: créer le profil automatiquement après inscription
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, first_name, last_name, phone, role, status)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', NEW.phone),
    COALESCE(NEW.raw_user_meta_data->>'role', 'member'),
    'pending'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: après chaque inscription
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- Fonction: générer les cotisations pour un membre (année)
-- ============================================================
CREATE OR REPLACE FUNCTION public.generate_cotisations(p_user_id UUID, p_year INTEGER)
RETURNS VOID AS $$
DECLARE
  m INTEGER;
BEGIN
  FOR m IN 1..10 LOOP
    INSERT INTO cotisations (user_id, month, year, amount, status)
    VALUES (p_user_id, m, p_year, 10.0, 'unpaid')
    ON CONFLICT (user_id, month, year) DO NOTHING;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Migration: Traçabilité des actions admin
-- ============================================================

-- Ajouter les colonnes de traçabilité sur cotisations
ALTER TABLE cotisations ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES profiles(id);
ALTER TABLE cotisations ADD COLUMN IF NOT EXISTS updated_by_name TEXT;

-- Table d'audit pour tracer toutes les actions admin
CREATE TABLE IF NOT EXISTS audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES profiles(id),
  admin_name TEXT NOT NULL,
  action TEXT NOT NULL,
  target_table TEXT NOT NULL,
  target_id TEXT,
  details JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- Audit: lecture par admin uniquement
CREATE POLICY "Audit: lecture par admin"
  ON audit_log FOR SELECT
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Audit: insertion par admin
CREATE POLICY "Audit: insertion par admin"
  ON audit_log FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE INDEX IF NOT EXISTS idx_audit_log_admin ON audit_log(admin_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created ON audit_log(created_at);
CREATE INDEX IF NOT EXISTS idx_audit_log_target ON audit_log(target_table, target_id);

-- ============================================================
-- Table des notifications in-app
-- ============================================================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'info' CHECK (type IN ('info', 'cotisation', 'member', 'compte_rendu', 'role', 'actualite')),
  is_read BOOLEAN NOT NULL DEFAULT false,
  data JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications REPLICA IDENTITY FULL;

-- Chaque utilisateur ne voit que ses propres notifications
CREATE POLICY "Notifications: lecture propres notifications"
  ON notifications FOR SELECT
  TO authenticated
  USING (recipient_id = auth.uid());

-- Insertion par admin ou système
CREATE POLICY "Notifications: insertion par admin"
  ON notifications FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Mise à jour (marquer comme lue) par le destinataire
CREATE POLICY "Notifications: mise à jour par destinataire"
  ON notifications FOR UPDATE
  TO authenticated
  USING (recipient_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(recipient_id, is_read) WHERE is_read = false;

-- ============================================================
-- Table des documents officiels (statuts, règlement)
-- ============================================================
CREATE TABLE IF NOT EXISTS documents (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_by UUID REFERENCES profiles(id),
  updated_by_name TEXT
);

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Lecture par tous les utilisateurs authentifiés
CREATE POLICY "Documents: lecture par tous"
  ON documents FOR SELECT
  TO authenticated
  USING (true);

-- Modification par admin uniquement
CREATE POLICY "Documents: modification par admin"
  ON documents FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Insertion par admin uniquement
CREATE POLICY "Documents: insertion par admin"
  ON documents FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Insérer les documents par défaut
INSERT INTO documents (id, title, content) VALUES
('statuts', 'Statuts de l''association', ''),
('reglement', 'Règlement intérieur', '')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- Table des actualités
-- ============================================================
CREATE TABLE IF NOT EXISTS actualites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'actualite',
  author_id UUID NOT NULL REFERENCES profiles(id),
  author_name TEXT NOT NULL,
  published_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE actualites ENABLE ROW LEVEL SECURITY;

-- Lecture par tous les utilisateurs authentifiés
CREATE POLICY "Actualites: lecture par tous"
  ON actualites FOR SELECT
  TO authenticated
  USING (true);

-- Insertion par admin uniquement
CREATE POLICY "Actualites: insertion par admin"
  ON actualites FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Modification par admin uniquement
CREATE POLICY "Actualites: modification par admin"
  ON actualites FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Suppression par admin uniquement
CREATE POLICY "Actualites: suppression par admin"
  ON actualites FOR DELETE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE INDEX IF NOT EXISTS idx_actualites_published ON actualites(published_at DESC);

-- ============================================================
-- Table des mandats du bureau
-- ============================================================
CREATE TABLE IF NOT EXISTS mandats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  label TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE mandats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Mandats: lecture par tous"
  ON mandats FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Mandats: insertion par admin"
  ON mandats FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Mandats: modification par admin"
  ON mandats FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Mandats: suppression par admin"
  ON mandats FOR DELETE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ============================================================
-- Table des membres du bureau
-- ============================================================
CREATE TABLE IF NOT EXISTS bureau_membres (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mandat_id UUID NOT NULL REFERENCES mandats(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id),
  user_name TEXT NOT NULL,
  poste TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(mandat_id, poste)
);

ALTER TABLE bureau_membres ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Bureau: lecture par tous"
  ON bureau_membres FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Bureau: insertion par admin"
  ON bureau_membres FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Bureau: modification par admin"
  ON bureau_membres FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Bureau: suppression par admin"
  ON bureau_membres FOR DELETE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE INDEX IF NOT EXISTS idx_bureau_membres_mandat ON bureau_membres(mandat_id);
CREATE INDEX IF NOT EXISTS idx_mandats_active ON mandats(is_active) WHERE is_active = true;

-- ============================================================
-- Index pour les performances
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_cotisations_user_year ON cotisations(user_id, year);
CREATE INDEX IF NOT EXISTS idx_cotisations_paid_at ON cotisations(paid_at) WHERE paid_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles(status);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_comptes_rendus_date ON comptes_rendus(reunion_date);
