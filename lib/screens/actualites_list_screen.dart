import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/actualite_provider.dart';
import '../models/user_model.dart';
import '../models/actualite_model.dart';
import '../theme/app_theme.dart';

class ActualitesListScreen extends StatefulWidget {
  const ActualitesListScreen({super.key});

  @override
  State<ActualitesListScreen> createState() => _ActualitesListScreenState();
}

class _ActualitesListScreenState extends State<ActualitesListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ActualiteProvider>().loadActualites();
  }

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
    final isAdmin = context.read<AuthProvider>().currentUser?.role == UserRole.admin;
    final provider = context.watch<ActualiteProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualités'),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/create-actualite').then((_) {
                  provider.loadActualites();
                });
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => provider.loadActualites(),
                child: provider.actualites.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 100),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.newspaper_rounded,
                                  size: 60,
                                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucune actualité',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Les actualités publiées apparaîtront ici',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.actualites.length,
                        itemBuilder: (context, index) {
                          final actu = provider.actualites[index];
                          return _buildActualiteCard(actu, isAdmin, provider);
                        },
                      ),
              ),
      ),
    );
  }

  Widget _buildActualiteCard(ActualiteModel actu, bool isAdmin, ActualiteProvider provider) {
    final color = _categoryColor(actu.category);
    final icon = _categoryIcon(actu.category);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/actualite-detail', arguments: actu);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            // Header avec catégorie
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      actu.categoryLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    actu.formattedDate,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Contenu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    actu.title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    actu.content,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.person_rounded, size: 14, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(
                        actu.authorName,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (isAdmin) ...[
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/edit-actualite', arguments: actu).then((_) {
                              provider.loadActualites();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.edit_rounded, size: 18, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _confirmDelete(actu, provider),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(ActualiteModel actu, ActualiteProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        content: Text('Supprimer "${actu.title}" ?', style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.deleteActualite(actu.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Actualité supprimée' : 'Erreur lors de la suppression'),
                    backgroundColor: success ? AppColors.approved : AppColors.rejected,
                  ),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
