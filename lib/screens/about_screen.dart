import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('À propos'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'MBAHE EUROPE',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'Ensemble, construisons l\'avenir',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 28),

              // Présentation
              _buildSection(
                icon: Icons.people_rounded,
                title: 'Qui sommes-nous ?',
                content:
                    'MBAHE Europe est une association qui regroupe les ressortissants '
                    'de MBAHE vivant en Europe. Notre mission est de renforcer les liens '
                    'entre les membres de notre communauté, de promouvoir l\'entraide '
                    'et de contribuer au développement de notre village d\'origine.',
              ),

              _buildSection(
                icon: Icons.flag_rounded,
                title: 'Nos objectifs',
                content: null,
                bullets: [
                  'Renforcer la solidarité entre les membres',
                  'Contribuer au développement de MBAHE',
                  'Organiser des événements culturels et sociaux',
                  'Soutenir les membres en difficulté',
                  'Préserver et promouvoir notre culture',
                ],
              ),

              _buildSection(
                icon: Icons.payments_rounded,
                title: 'Les cotisations',
                content:
                    'Chaque membre cotise mensuellement de Janvier à Octobre. '
                    'Les mois de Novembre et Décembre sont des mois de vacances. '
                    'Les cotisations permettent de financer les projets de l\'association '
                    'et d\'assurer l\'entraide entre les membres.',
              ),

              _buildSection(
                icon: Icons.calendar_month_rounded,
                title: 'Les réunions',
                content:
                    'L\'association organise des réunions régulières pour discuter '
                    'des projets en cours, prendre des décisions collectives et '
                    'maintenir le lien entre les membres. Les comptes rendus sont '
                    'disponibles dans l\'application.',
              ),

              _buildSection(
                icon: Icons.phone_rounded,
                title: 'Contact',
                content:
                    'Pour toute question ou suggestion, n\'hésitez pas à contacter '
                    'les administrateurs de l\'association via l\'application.',
              ),

              const SizedBox(height: 20),

              // Version
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Version 1.0.0',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '© ${DateTime.now().year} MBAHE Europe',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    String? content,
    List<String>? bullets,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (content != null)
            Text(
              content,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          if (bullets != null)
            ...bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 7),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          b,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
