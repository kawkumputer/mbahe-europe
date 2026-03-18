-- ============================================================
-- Créer la table documents pour stocker les statuts et règlement
-- ============================================================

-- 0. Supprimer l'ancienne table et ses politiques si elle existe
DROP POLICY IF EXISTS "Tout le monde peut lire les documents" ON documents;
DROP POLICY IF EXISTS "Les admins peuvent gérer les documents" ON documents;
DROP TABLE IF EXISTS documents CASCADE;

-- 1. Créer la table documents
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_type TEXT NOT NULL UNIQUE, -- 'statuts' ou 'reglement'
  content TEXT NOT NULL,
  updated_by_name TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Activer RLS
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- 3. Politique : Tout le monde peut lire
CREATE POLICY "Tout le monde peut lire les documents"
  ON documents
  FOR SELECT
  TO authenticated
  USING (true);

-- 4. Politique : Les admins et sys_admin peuvent créer, modifier et supprimer
CREATE POLICY "Les admins peuvent gérer les documents"
  ON documents
  FOR ALL
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

-- 5. Insérer les statuts par défaut
INSERT INTO documents (document_type, content, updated_by_name) VALUES (
  'statuts',
  '[
    {"title": "Article 1 — Dénomination", "content": "Il est fondé entre les adhérents aux présents statuts une association régie par la loi du 1er juillet 1901, ayant pour dénomination : MBAHE EUROPE."},
    {"title": "Article 2 — Objet", "content": "L''association a pour objet :\\n• Regrouper les ressortissants de MBAHE vivant en Europe\\n• Renforcer les liens de solidarité entre les membres\\n• Contribuer au développement socio-économique du village de MBAHE\\n• Organiser des activités culturelles, sociales et éducatives\\n• Promouvoir l''entraide et la cohésion communautaire"},
    {"title": "Article 3 — Siège social", "content": "Le siège social est fixé en Europe. Il pourra être transféré par simple décision du bureau."},
    {"title": "Article 4 — Durée", "content": "La durée de l''association est illimitée."},
    {"title": "Article 5 — Composition", "content": "L''association se compose de :\\n• Membres actifs : toute personne originaire de MBAHE ou ayant un lien avec le village, résidant en Europe, à jour de ses cotisations\\n• Membres d''honneur : personnes ayant rendu des services éminents à l''association"},
    {"title": "Article 6 — Admission", "content": "Pour faire partie de l''association, il faut :\\n• Remplir une demande d''adhésion via l''application\\n• Être approuvé par le bureau de l''association\\n• S''acquitter de la cotisation annuelle"},
    {"title": "Article 7 — Cotisations", "content": "Les membres s''acquittent d''une cotisation mensuelle dont le montant est fixé par l''assemblée générale. Les cotisations sont dues de Janvier à Octobre. Les mois de Novembre et Décembre sont des mois de vacances."},
    {"title": "Article 8 — Perte de qualité de membre", "content": "La qualité de membre se perd par :\\n• La démission adressée par écrit au bureau\\n• Le non-paiement des cotisations après mise en demeure\\n• L''exclusion prononcée par le bureau pour motif grave"},
    {"title": "Article 9 — Administration", "content": "L''association est dirigée par un bureau composé de :\\n• Un(e) Président(e)\\n• Un(e) Vice-Président(e)\\n• Un(e) Secrétaire Général(e)\\n• Un(e) Trésorier(ère)\\n• Des membres du bureau\\n\\nLe bureau est élu par l''assemblée générale pour un mandat défini par le règlement intérieur."},
    {"title": "Article 10 — Assemblée générale", "content": "L''assemblée générale comprend tous les membres actifs de l''association. Elle se réunit au moins une fois par an sur convocation du bureau. Les décisions sont prises à la majorité des membres présents."},
    {"title": "Article 11 — Ressources", "content": "Les ressources de l''association comprennent :\\n• Les cotisations des membres\\n• Les dons et subventions\\n• Les recettes des activités organisées\\n• Toute autre ressource autorisée par la loi"},
    {"title": "Article 12 — Modification des statuts", "content": "Les statuts peuvent être modifiés par l''assemblée générale extraordinaire, sur proposition du bureau ou d''au moins un tiers des membres actifs."},
    {"title": "Article 13 — Dissolution", "content": "La dissolution de l''association ne peut être prononcée que par l''assemblée générale extraordinaire. En cas de dissolution, l''actif net sera attribué à une association ayant des buts similaires."}
  ]',
  'Système'
) ON CONFLICT (document_type) DO NOTHING;

-- 6. Insérer le règlement intérieur par défaut
INSERT INTO documents (document_type, content, updated_by_name) VALUES (
  'reglement',
  '[
    {"title": "Article 1 — Objet", "content": "Le présent règlement intérieur complète et précise les statuts de l''association MBAHE EUROPE. Il s''applique à tous les membres sans exception."},
    {"title": "Article 2 — Adhésion", "content": "Toute personne souhaitant adhérer à l''association doit :\\n• Créer un compte via l''application officielle\\n• Fournir ses nom, prénom et numéro de téléphone\\n• Attendre la validation de son compte par le bureau\\n• S''acquitter de sa première cotisation dans le mois suivant l''approbation"},
    {"title": "Article 3 — Montant et périodicité", "content": "Le montant de la cotisation mensuelle est fixé par l''assemblée générale. Les cotisations sont dues chaque mois de Janvier à Octobre. Les mois de Novembre et Décembre sont des mois de vacances."},
    {"title": "Article 4 — Modes de paiement", "content": "Les cotisations peuvent être réglées par :\\n• Espèces\\n• Chèque\\n• Virement bancaire\\n• Tout autre moyen validé par le bureau"},
    {"title": "Article 5 — Retard de paiement", "content": "Tout membre en retard de paiement de plus de 3 mois sera relancé par le bureau. En cas de non-régularisation après mise en demeure, le bureau pourra prononcer la suspension du membre."},
    {"title": "Article 6 — Exemptions", "content": "Un membre en situation de chômage ou de difficulté financière avérée peut demander une exemption temporaire de cotisation. Cette exemption est accordée par le bureau au cas par cas."},
    {"title": "Article 7 — Droits des membres", "content": "Tout membre actif à jour de ses cotisations a le droit de :\\n• Participer aux assemblées générales avec voix délibérative\\n• Être éligible aux fonctions du bureau\\n• Accéder aux comptes rendus des réunions\\n• Bénéficier de l''entraide et de la solidarité de l''association\\n• Consulter les informations de l''association via l''application"},
    {"title": "Article 8 — Devoirs des membres", "content": "Tout membre s''engage à :\\n• Respecter les statuts et le présent règlement intérieur\\n• S''acquitter régulièrement de ses cotisations\\n• Participer activement à la vie de l''association\\n• Faire preuve de respect envers les autres membres\\n• Préserver l''image et la réputation de l''association"},
    {"title": "Article 9 — Réunions ordinaires", "content": "Les réunions ordinaires sont convoquées par le bureau. L''ordre du jour est communiqué à l''avance. Un compte rendu est rédigé après chaque réunion et mis à disposition des membres via l''application."},
    {"title": "Article 10 — Présence", "content": "La participation aux réunions est vivement encouragée. En cas d''absence, le membre peut se faire représenter par un autre membre muni d''une procuration."},
    {"title": "Article 11 — Sanctions disciplinaires", "content": "En cas de manquement aux obligations, le bureau peut prononcer :\\n• Un avertissement verbal ou écrit\\n• Une suspension temporaire\\n• Une exclusion définitive (après audition du membre concerné)"},
    {"title": "Article 12 — Procédure", "content": "Toute sanction est précédée d''une audition du membre concerné qui peut présenter sa défense. La décision est prise à la majorité des membres du bureau."},
    {"title": "Article 13 — Modification", "content": "Le présent règlement intérieur peut être modifié par le bureau après consultation de l''assemblée générale."},
    {"title": "Article 14 — Entrée en vigueur", "content": "Le présent règlement intérieur entre en vigueur à compter de son adoption par l''assemblée générale."}
  ]',
  'Système'
) ON CONFLICT (document_type) DO NOTHING;

-- ============================================================
-- TERMINÉ
-- ============================================================
