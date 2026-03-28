-- ============================================================
-- Mise à jour du trigger de création de profil
-- Pour inclure l'association choisie lors de l'inscription
-- ============================================================

-- Supprimer l'ancien trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Recréer la fonction avec support de l'association et des rôles par association
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_phone TEXT;
  v_username TEXT;
  v_association_type TEXT;
  v_association_roles JSONB;
BEGIN
  -- Récupérer les données depuis les métadonnées
  v_phone := COALESCE(NEW.raw_user_meta_data->>'phone', NEW.phone);
  v_username := COALESCE(NEW.raw_user_meta_data->>'username', '');
  v_association_type := COALESCE(NEW.raw_user_meta_data->>'association_type', 'general');
  
  -- Vérifier si le profil existe déjà (au cas où)
  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = NEW.id) THEN
    RETURN NEW;
  END IF;
  
  -- Vérifier si le téléphone est unique
  IF EXISTS (SELECT 1 FROM public.profiles WHERE phone = v_phone) THEN
    RAISE EXCEPTION 'Ce numéro de téléphone est déjà utilisé';
  END IF;
  
  -- Vérifier si le username est unique (si fourni)
  IF v_username != '' AND EXISTS (SELECT 1 FROM public.profiles WHERE username = v_username) THEN
    RAISE EXCEPTION 'Ce nom d''utilisateur est déjà utilisé';
  END IF;
  
  -- Créer l'objet association_roles avec le rôle 'member' pour l'association choisie
  v_association_roles := jsonb_build_object(v_association_type, 'member');
  
  -- Insérer le nouveau profil avec l'association choisie
  INSERT INTO public.profiles (
    id, 
    first_name, 
    last_name, 
    phone, 
    username,
    role, 
    status,
    association_types,
    association_roles
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    v_phone,
    v_username,
    COALESCE(NEW.raw_user_meta_data->>'role', 'member'),
    'pending',
    ARRAY[v_association_type], -- Association choisie lors de l'inscription
    v_association_roles -- Rôle 'member' pour cette association
  );
  
  RETURN NEW;
EXCEPTION
  WHEN unique_violation THEN
    -- Si violation de contrainte unique, supprimer l'utilisateur auth créé
    DELETE FROM auth.users WHERE id = NEW.id;
    RAISE EXCEPTION 'Ce numéro de téléphone ou nom d''utilisateur est déjà utilisé';
  WHEN OTHERS THEN
    -- Pour toute autre erreur, supprimer l'utilisateur auth créé
    DELETE FROM auth.users WHERE id = NEW.id;
    RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recréer le trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- TERMINÉ
-- Le nouveau membre sera créé avec:
-- - association_types: [association choisie]
-- - association_roles: {"association_choisie": "member"}
-- - status: "pending" (en attente de validation)
-- ============================================================
