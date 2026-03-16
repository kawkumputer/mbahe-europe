import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/actualite_model.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class ActualiteDetailScreen extends StatelessWidget {
  const ActualiteDetailScreen({super.key});

  Color _categoryColor(ActualiteCategory cat) {
    switch (cat) {
      case ActualiteCategory.actualite:
        return const Color(0xFF1976D2);
      case ActualiteCategory.evenement:
        return const Color(0xFF6A1B9A);
      case ActualiteCategory.annonce:
        return const Color(0xFFEF6C00);
    }
  }

  IconData _categoryIcon(ActualiteCategory cat) {
    switch (cat) {
      case ActualiteCategory.actualite:
        return Icons.article_rounded;
      case ActualiteCategory.evenement:
        return Icons.event_rounded;
      case ActualiteCategory.annonce:
        return Icons.campaign_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actu = ModalRoute.of(context)!.settings.arguments as ActualiteModel;
    final color = _categoryColor(actu.category);
    final icon = _categoryIcon(actu.category);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.get('actu_detail_title')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            actu.categoryLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      actu.title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          actu.authorName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          actu.formattedDate,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Contenu
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                child: Text(
                  actu.content,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.7,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
