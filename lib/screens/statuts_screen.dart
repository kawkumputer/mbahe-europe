import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class StatutsScreen extends StatelessWidget {
  const StatutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statuts'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildArticle(
                'Article 1 — Dénomination',
                'Il est fondé entre les adhérents aux présents statuts une association '
                    'régie par la loi du 1er juillet 1901, ayant pour dénomination : '
                    'MBAHE EUROPE.',
              ),
              _buildArticle(
                'Article 2 — Objet',
                'L\'association a pour objet :\n'
                    '• Regrouper les ressortissants de MBAHE vivant en Europe\n'
                    '• Renforcer les liens de solidarité entre les membres\n'
                    '• Contribuer au développement socio-économique du village de MBAHE\n'
                    '• Organiser des activités culturelles, sociales et éducatives\n'
                    '• Promouvoir l\'entraide et la cohésion communautaire',
              ),
              _buildArticle(
                'Article 3 — Siège social',
                'Le siège social est fixé en Europe. Il pourra être transféré '
                    'par simple décision du bureau.',
              ),
              _buildArticle(
                'Article 4 — Durée',
                'La durée de l\'association est illimitée.',
              ),
              _buildArticle(
                'Article 5 — Composition',
                'L\'association se compose de :\n'
                    '• Membres actifs : toute personne originaire de MBAHE ou ayant un lien '
                    'avec le village, résidant en Europe, à jour de ses cotisations\n'
                    '• Membres d\'honneur : personnes ayant rendu des services éminents à l\'association',
              ),
              _buildArticle(
                'Article 6 — Admission',
                'Pour faire partie de l\'association, il faut :\n'
                    '• Remplir une demande d\'adhésion via l\'application\n'
                    '• Être approuvé par le bureau de l\'association\n'
                    '• S\'acquitter de la cotisation annuelle',
              ),
              _buildArticle(
                'Article 7 — Cotisations',
                'Les membres s\'acquittent d\'une cotisation mensuelle dont le montant '
                    'est fixé par l\'assemblée générale. Les cotisations sont dues de '
                    'Janvier à Octobre. Les mois de Novembre et Décembre sont des mois '
                    'de vacances.',
              ),
              _buildArticle(
                'Article 8 — Perte de qualité de membre',
                'La qualité de membre se perd par :\n'
                    '• La démission adressée par écrit au bureau\n'
                    '• Le non-paiement des cotisations après mise en demeure\n'
                    '• L\'exclusion prononcée par le bureau pour motif grave',
              ),
              _buildArticle(
                'Article 9 — Administration',
                'L\'association est dirigée par un bureau composé de :\n'
                    '• Un(e) Président(e)\n'
                    '• Un(e) Vice-Président(e)\n'
                    '• Un(e) Secrétaire Général(e)\n'
                    '• Un(e) Trésorier(ère)\n'
                    '• Des membres du bureau\n\n'
                    'Le bureau est élu par l\'assemblée générale pour un mandat '
                    'défini par le règlement intérieur.',
              ),
              _buildArticle(
                'Article 10 — Assemblée générale',
                'L\'assemblée générale comprend tous les membres actifs de l\'association. '
                    'Elle se réunit au moins une fois par an sur convocation du bureau. '
                    'Les décisions sont prises à la majorité des membres présents.',
              ),
              _buildArticle(
                'Article 11 — Ressources',
                'Les ressources de l\'association comprennent :\n'
                    '• Les cotisations des membres\n'
                    '• Les dons et subventions\n'
                    '• Les recettes des activités organisées\n'
                    '• Toute autre ressource autorisée par la loi',
              ),
              _buildArticle(
                'Article 12 — Modification des statuts',
                'Les statuts peuvent être modifiés par l\'assemblée générale '
                    'extraordinaire, sur proposition du bureau ou d\'au moins '
                    'un tiers des membres actifs.',
              ),
              _buildArticle(
                'Article 13 — Dissolution',
                'La dissolution de l\'association ne peut être prononcée que par '
                    'l\'assemblée générale extraordinaire. En cas de dissolution, '
                    'l\'actif net sera attribué à une association ayant des buts similaires.',
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
          const Icon(Icons.gavel_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 10),
          Text(
            'STATUTS DE L\'ASSOCIATION',
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
              color: AppColors.primary,
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
