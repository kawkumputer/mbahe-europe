-- ============================================================
-- Créer et marquer comme payées toutes les cotisations 2025
-- pour tous les membres approuvés
-- Paiement: Espèce, par Hamath Kane
-- Note: Novembre et décembre sont des mois de vacances (pas de cotisations)
-- ============================================================

-- 1. Générer les cotisations pour tous les membres approuvés pour 2025
DO $$
DECLARE
    member_record RECORD;
    month_num INT;
BEGIN
    -- Pour chaque membre approuvé
    FOR member_record IN 
        SELECT id FROM profiles WHERE status = 'approved'
    LOOP
        -- Pour chaque mois (1 à 10 - janvier à octobre, novembre et décembre = vacances)
        FOR month_num IN 1..10 LOOP
            -- Vérifier si la cotisation existe déjà
            IF NOT EXISTS (
                SELECT 1 FROM cotisations 
                WHERE user_id = member_record.id 
                AND year = 2025 
                AND month = month_num
            ) THEN
                -- Créer la cotisation
                INSERT INTO cotisations (user_id, year, month, amount, status)
                VALUES (member_record.id, 2025, month_num, 10.0, 'unpaid');
            END IF;
        END LOOP;
    END LOOP;
END $$;

-- 2. Marquer toutes les cotisations 2025 comme payées (espèce)
-- Date de paiement: 20 décembre 2025
UPDATE cotisations
SET 
    status = 'paid',
    payment_method = 'espece',
    paid_at = '2025-12-20'::timestamp,
    updated_by_name = 'Hamath Kane'
WHERE 
    year = 2025 
    AND status = 'unpaid';

-- 3. Afficher un résumé
DO $$
DECLARE
    total_members INT;
    total_cotisations INT;
    total_amount DECIMAL(10,2);
BEGIN
    SELECT COUNT(DISTINCT user_id) INTO total_members
    FROM cotisations WHERE year = 2025;
    
    SELECT COUNT(*) INTO total_cotisations
    FROM cotisations WHERE year = 2025 AND status = 'paid';
    
    SELECT SUM(amount) INTO total_amount
    FROM cotisations WHERE year = 2025 AND status = 'paid';
    
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Cotisations 2025 créées et marquées comme payées';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Nombre de membres: %', total_members;
    RAISE NOTICE 'Nombre de cotisations payées: %', total_cotisations;
    RAISE NOTICE 'Montant total: % €', total_amount;
    RAISE NOTICE '==============================================';
END $$;

-- ============================================================
-- TERMINÉ
-- ============================================================
