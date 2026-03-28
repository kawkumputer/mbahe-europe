import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cotisation_provider.dart';
import '../providers/depense_provider.dart';
import '../providers/compte_rendu_provider.dart';
import '../providers/actualite_provider.dart';
import '../theme/association_colors.dart';

/// Widget pour changer d'association si l'utilisateur appartient à plusieurs
class AssociationSwitcher extends StatelessWidget {
  const AssociationSwitcher({super.key});

  void _showAssociationDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentType = authProvider.currentAssociationType;
    final associations = authProvider.userAssociationTypes;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: AssociationColors.getPrimaryColor(currentType)),
            const SizedBox(width: 12),
            Text(
              'Changer d\'association',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: associations.map((type) {
            final isActive = type == currentType;
            return InkWell(
              onTap: () async {
                if (!isActive) {
                  // Changer l'association active
                  await authProvider.switchAssociation(type);
                  
                  // Synchroniser tous les providers
                  if (context.mounted) {
                    context.read<CotisationProvider>().setAssociationType(type);
                    context.read<DepenseProvider>().setAssociationType(type);
                    context.read<CompteRenduProvider>().setAssociationType(type);
                    context.read<ActualiteProvider>().setAssociationType(type);
                    
                    Navigator.pop(context);
                    
                    // Naviguer selon le rôle de l'association sélectionnée
                    Navigator.pushReplacementNamed(
                      context,
                      authProvider.isAdminForCurrentAssociation ? '/admin-home' : '/member-home',
                    );
                  }
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isActive 
                    ? AssociationColors.getGradient(type)
                    : null,
                  color: isActive ? null : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive 
                      ? AssociationColors.getPrimaryColor(type)
                      : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isActive 
                          ? Colors.white.withOpacity(0.3)
                          : AssociationColors.getPrimaryColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        AssociationColors.getAssociationIcon(type),
                        color: isActive ? Colors.white : AssociationColors.getPrimaryColor(type),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AssociationColors.getAssociationName(type),
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            type == 'jeunes' 
                              ? 'Association des jeunes'
                              : 'Association générale',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isActive 
                                ? Colors.white.withOpacity(0.9)
                                : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(
                color: AssociationColors.getPrimaryColor(currentType),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    // N'afficher que si l'utilisateur a plusieurs associations
    if (!authProvider.hasMultipleAssociations) {
      return const SizedBox.shrink();
    }

    final currentType = authProvider.currentAssociationType;

    return IconButton(
      icon: Stack(
        children: [
          Icon(
            AssociationColors.getAssociationIcon(currentType),
            color: Colors.white,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.swap_horiz_rounded,
                size: 10,
                color: AssociationColors.getPrimaryColor(currentType),
              ),
            ),
          ),
        ],
      ),
      tooltip: 'Changer d\'association',
      onPressed: () => _showAssociationDialog(context),
    );
  }
}
