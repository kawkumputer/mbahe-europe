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
-- Index pour les performances
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_cotisations_user_year ON cotisations(user_id, year);
CREATE INDEX IF NOT EXISTS idx_cotisations_paid_at ON cotisations(paid_at) WHERE paid_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles(status);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_comptes_rendus_date ON comptes_rendus(reunion_date);
