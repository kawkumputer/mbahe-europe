import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';

class MemberHomeScreen extends StatelessWidget {
  const MemberHomeScreen({super.key});

  Widget _buildNotificationIcon(BuildContext context) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_rounded),
          onPressed: () {
            final notifProvider = context.read<NotificationProvider>();
            Navigator.pushNamed(context, '/notifications').then((_) {
              notifProvider.refreshUnreadCount();
            });
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.rejected,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MBAHE Europe'),
        actions: [
          _buildNotificationIcon(context),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              context.read<NotificationProvider>().stopListening();
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête bienvenue
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          '${user?.firstName[0] ?? ''}${user?.lastName[0] ?? ''}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bienvenue,',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              user?.fullName ?? '',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Membre actif',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Accès rapide',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Grille de fonctionnalités
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildFeatureCard(
                  icon: Icons.payments_rounded,
                  title: 'Mes cotisations',
                  subtitle: 'Consulter',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pushNamed(context, '/member-cotisations');
                  },
                ),
                _buildFeatureCard(
                  icon: Icons.description_rounded,
                  title: 'Comptes rendus',
                  subtitle: 'Réunions',
                  color: const Color(0xFF1976D2),
                  onTap: () {
                    Navigator.pushNamed(context, '/comptes-rendus');
                  },
                ),
                _buildFeatureCard(
                  icon: Icons.bar_chart_rounded,
                  title: 'Bilan réunions',
                  subtitle: 'Cotisations collectées',
                  color: const Color(0xFF1565C0),
                  onTap: () {
                    Navigator.pushNamed(context, '/admin-payment-dashboard');
                  },
                ),
                _buildFeatureCard(
                  icon: Icons.newspaper_rounded,
                  title: 'Actualités',
                  subtitle: 'Infos & événements',
                  color: const Color(0xFFD32F2F),
                  onTap: () => Navigator.pushNamed(context, '/actualites'),
                ),
                _buildFeatureCard(
                  icon: Icons.groups_rounded,
                  title: 'Bureau',
                  subtitle: 'Composition',
                  color: const Color(0xFF0D47A1),
                  onTap: () => Navigator.pushNamed(context, '/bureau'),
                ),
                _buildFeatureCard(
                  icon: Icons.gavel_rounded,
                  title: 'Statuts',
                  subtitle: 'De l\'association',
                  color: const Color(0xFF6A1B9A),
                  onTap: () => Navigator.pushNamed(context, '/statuts'),
                ),
                _buildFeatureCard(
                  icon: Icons.menu_book_rounded,
                  title: 'Règlement',
                  subtitle: 'Intérieur',
                  color: const Color(0xFFEF6C00),
                  onTap: () => Navigator.pushNamed(context, '/reglement'),
                ),
                _buildFeatureCard(
                  icon: Icons.info_outline_rounded,
                  title: 'À propos',
                  subtitle: 'L\'association',
                  color: const Color(0xFFE64A19),
                  onTap: () => Navigator.pushNamed(context, '/about'),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Section placeholder
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.construction_rounded,
                    size: 40,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Fonctionnalités à venir',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Les modules de cotisations, événements et actualités seront disponibles prochainement.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
