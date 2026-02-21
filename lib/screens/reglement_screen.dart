import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ReglementScreen extends StatelessWidget {
  const ReglementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Règlement intérieur'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),

              _buildChapter('CHAPITRE I — DISPOSITIONS GÉNÉRALES'),

              _buildArticle(
                'Article 1 — Objet',
                'Le présent règlement intérieur complète et précise les statuts '
                    'de l\'association MBAHE EUROPE. Il s\'applique à tous les membres '
                    'sans exception.',
              ),
              _buildArticle(
                'Article 2 — Adhésion',
                'Toute personne souhaitant adhérer à l\'association doit :\n'
                    '• Créer un compte via l\'application officielle\n'
                    '• Fournir ses nom, prénom et numéro de téléphone\n'
                    '• Attendre la validation de son compte par le bureau\n'
                    '• S\'acquitter de sa première cotisation dans le mois suivant l\'approbation',
              ),

              _buildChapter('CHAPITRE II — COTISATIONS'),

              _buildArticle(
                'Article 3 — Montant et périodicité',
                'Le montant de la cotisation mensuelle est fixé par l\'assemblée générale. '
                    'Les cotisations sont dues chaque mois de Janvier à Octobre. '
                    'Les mois de Novembre et Décembre sont des mois de vacances '
                    'pendant lesquels aucune cotisation n\'est exigée.',
              ),
              _buildArticle(
                'Article 4 — Modes de paiement',
                'Les cotisations peuvent être réglées par :\n'
                    '• Espèces\n'
                    '• Chèque\n'
                    '• Virement bancaire\n'
                    '• Tout autre moyen validé par le bureau',
              ),
              _buildArticle(
                'Article 5 — Retard de paiement',
                'Tout membre en retard de paiement de plus de 3 mois sera relancé '
                    'par le bureau. En cas de non-régularisation après mise en demeure, '
                    'le bureau pourra prononcer la suspension du membre.',
              ),
              _buildArticle(
                'Article 6 — Exemptions',
                'Un membre en situation de chômage ou de difficulté financière avérée '
                    'peut demander une exemption temporaire de cotisation. '
                    'Cette exemption est accordée par le bureau au cas par cas.',
              ),

              _buildChapter('CHAPITRE III — DROITS ET DEVOIRS DES MEMBRES'),

              _buildArticle(
                'Article 7 — Droits des membres',
                'Tout membre actif à jour de ses cotisations a le droit de :\n'
                    '• Participer aux assemblées générales avec voix délibérative\n'
                    '• Être éligible aux fonctions du bureau\n'
                    '• Accéder aux comptes rendus des réunions\n'
                    '• Bénéficier de l\'entraide et de la solidarité de l\'association\n'
                    '• Consulter les informations de l\'association via l\'application',
              ),
              _buildArticle(
                'Article 8 — Devoirs des membres',
                'Tout membre s\'engage à :\n'
                    '• Respecter les statuts et le présent règlement intérieur\n'
                    '• S\'acquitter régulièrement de ses cotisations\n'
                    '• Participer activement à la vie de l\'association\n'
                    '• Faire preuve de respect envers les autres membres\n'
                    '• Préserver l\'image et la réputation de l\'association',
              ),

              _buildChapter('CHAPITRE IV — RÉUNIONS'),

              _buildArticle(
                'Article 9 — Réunions ordinaires',
                'Les réunions ordinaires sont convoquées par le bureau. '
                    'L\'ordre du jour est communiqué à l\'avance. '
                    'Un compte rendu est rédigé après chaque réunion et mis à disposition '
                    'des membres via l\'application.',
              ),
              _buildArticle(
                'Article 10 — Présence',
                'La participation aux réunions est vivement encouragée. '
                    'En cas d\'absence, le membre peut se faire représenter '
                    'par un autre membre muni d\'une procuration.',
              ),

              _buildChapter('CHAPITRE V — SANCTIONS'),

              _buildArticle(
                'Article 11 — Sanctions disciplinaires',
                'En cas de manquement aux obligations, le bureau peut prononcer :\n'
                    '• Un avertissement verbal ou écrit\n'
                    '• Une suspension temporaire\n'
                    '• Une exclusion définitive (après audition du membre concerné)',
              ),
              _buildArticle(
                'Article 12 — Procédure',
                'Toute sanction est précédée d\'une audition du membre concerné '
                    'qui peut présenter sa défense. La décision est prise à la majorité '
                    'des membres du bureau.',
              ),

              _buildChapter('CHAPITRE VI — DISPOSITIONS FINALES'),

              _buildArticle(
                'Article 13 — Modification',
                'Le présent règlement intérieur peut être modifié par le bureau '
                    'après consultation de l\'assemblée générale.',
              ),
              _buildArticle(
                'Article 14 — Entrée en vigueur',
                'Le présent règlement intérieur entre en vigueur à compter '
                    'de son adoption par l\'assemblée générale.',
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.menu_book_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 10),
          Text(
            'RÈGLEMENT INTÉRIEUR',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'MBAHE EUROPE',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapter(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildArticle(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
