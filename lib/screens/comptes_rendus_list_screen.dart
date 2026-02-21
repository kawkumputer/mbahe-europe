import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/compte_rendu_provider.dart';
import '../models/compte_rendu_model.dart';
import '../theme/app_theme.dart';

class ComptesRendusListScreen extends StatefulWidget {
  const ComptesRendusListScreen({super.key});

  @override
  State<ComptesRendusListScreen> createState() =>
      _ComptesRendusListScreenState();
}

class _ComptesRendusListScreenState extends State<ComptesRendusListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompteRenduProvider>().loadComptesRendus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final provider = context.watch<CompteRenduProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comptes rendus'),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/create-compte-rendu');
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Nouveau',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: SafeArea(
        child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.comptesRendus.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: provider.comptesRendus.length,
                  itemBuilder: (context, index) {
                    return _buildCompteRenduCard(
                      context,
                      provider.comptesRendus[index],
                      isAdmin,
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun compte rendu',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les comptes rendus des réunions apparaîtront ici.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompteRenduCard(
    BuildContext context,
    CompteRenduModel cr,
    bool isAdmin,
  ) {
    Color typeColor;
    IconData typeIcon;
    switch (cr.type) {
      case ReunionType.assembleeGenerale:
        typeColor = AppColors.primary;
        typeIcon = Icons.groups_rounded;
        break;
      case ReunionType.bureau:
        typeColor = const Color(0xFF1976D2);
        typeIcon = Icons.meeting_room_rounded;
        break;
      case ReunionType.extraordinaire:
        typeColor = const Color(0xFF7B1FA2);
        typeIcon = Icons.star_rounded;
        break;
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/compte-rendu-detail',
          arguments: cr,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cr.title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cr.formattedDate,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    cr.typeLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: typeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.list_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${cr.points.length} points',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Par ${cr.authorName}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
