import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

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
        title: Text(AppLocalizations.get('app_name')),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => context.read<LocaleProvider>().toggleLocale(),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    context.watch<LocaleProvider>().isFrench ? 'Pr' : 'FR',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
            // En-tête bienvenue avec photo de profil
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            backgroundImage: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            child: user?.photoUrl == null || user!.photoUrl!.isEmpty
                                ? Text(
                                    '${user?.firstName[0] ?? ''}${user?.lastName[0] ?? ''}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.get('home_welcome'),
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.8),
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
                      color: Colors.white.withOpacity(0.2),
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
                          AppLocalizations.get('home_active_member'),
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
              AppLocalizations.get('home_quick_access'),
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
                  title: AppLocalizations.get('home_my_cotisations'),
                  subtitle: AppLocalizations.get('home_cotisations_subtitle'),
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pushNamed(context, '/member-cotisations');
                  },
                ),
                _buildFeatureCard(
                  icon: Icons.description_rounded,
                  title: AppLocalizations.get('home_comptes_rendus'),
                  subtitle: AppLocalizations.get('home_comptes_rendus_subtitle'),
                  color: AppColors.info,
                  onTap: () {
                    Navigator.pushNamed(context, '/comptes-rendus');
                  },
                ),
                _buildFeatureCard(
                  icon: Icons.people_rounded,
                  title: 'Membres',
                  subtitle: 'Liste des membres',
                  color: AppColors.accent,
                  onTap: () {
                    Navigator.pushNamed(context, '/members-list');
                  },
                ),
                _buildFeatureCard(
                  icon: Icons.bar_chart_rounded,
                  title: AppLocalizations.get('home_bilan'),
                  subtitle: AppLocalizations.get('home_bilan_subtitle'),
                  color: AppColors.accentSecondary,
                  onTap: () {
                    Navigator.pushNamed(context, '/admin-payment-dashboard');
                  },
                ),
                _buildFeatureCard(
                  icon: Icons.newspaper_rounded,
                  title: AppLocalizations.get('home_actualites'),
                  subtitle: AppLocalizations.get('home_actualites_subtitle'),
                  color: AppColors.error,
                  onTap: () => Navigator.pushNamed(context, '/actualites'),
                ),
                _buildFeatureCard(
                  icon: Icons.groups_rounded,
                  title: AppLocalizations.get('home_bureau'),
                  subtitle: AppLocalizations.get('home_bureau_subtitle'),
                  color: AppColors.primaryDark,
                  onTap: () => Navigator.pushNamed(context, '/bureau'),
                ),
                _buildFeatureCard(
                  icon: Icons.gavel_rounded,
                  title: AppLocalizations.get('home_statuts'),
                  subtitle: AppLocalizations.get('home_statuts_subtitle'),
                  color: const Color(0xFF8B5CF6),
                  onTap: () => Navigator.pushNamed(context, '/statuts'),
                ),
                _buildFeatureCard(
                  icon: Icons.menu_book_rounded,
                  title: AppLocalizations.get('home_reglement'),
                  subtitle: AppLocalizations.get('home_reglement_subtitle'),
                  color: AppColors.warning,
                  onTap: () => Navigator.pushNamed(context, '/reglement'),
                ),
                _buildFeatureCard(
                  icon: Icons.info_outline_rounded,
                  title: AppLocalizations.get('home_about'),
                  subtitle: AppLocalizations.get('home_about_subtitle'),
                  color: const Color(0xFFEC4899),
                  onTap: () => Navigator.pushNamed(context, '/about'),
                ),
              ],
            ),

            const SizedBox(height: 28),
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
              color: Colors.black.withOpacity(0.05),
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
                color: color.withOpacity(0.1),
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
