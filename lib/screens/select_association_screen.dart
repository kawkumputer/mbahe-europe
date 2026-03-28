import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class SelectAssociationScreen extends StatelessWidget {
  const SelectAssociationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final associations = authProvider.userAssociationTypes;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'logo.jpeg',
                    height: 120,
                    width: 120,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Sélectionnez votre association',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Vous appartenez à plusieurs associations.\nChoisissez celle que vous souhaitez consulter.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  ...associations.map((associationType) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _AssociationCard(
                        associationType: associationType,
                        onTap: () async {
                          await authProvider.setActiveAssociation(associationType);
                          if (context.mounted) {
                            _navigateToHome(context, authProvider);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToHome(BuildContext context, AuthProvider authProvider) {
    if (authProvider.isApproved) {
      // Utiliser le rôle de l'association active au lieu du rôle global
      if (authProvider.isAdminForCurrentAssociation) {
        Navigator.pushReplacementNamed(context, '/admin-home');
      } else {
        Navigator.pushReplacementNamed(context, '/member-home');
      }
    } else if (authProvider.currentUser?.status == AccountStatus.pending) {
      Navigator.pushReplacementNamed(context, '/pending-approval');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}

class _AssociationCard extends StatelessWidget {
  final String associationType;
  final VoidCallback onTap;

  const _AssociationCard({
    required this.associationType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isGeneral = associationType == 'general';
    final title = isGeneral ? 'MBAHE Europe' : 'MBAHE Jeunes';
    final subtitle = isGeneral 
        ? 'Association générale des ressortissants de M\'bahe en Europe'
        : 'Association des jeunes de M\'bahe en Europe';
    final icon = isGeneral ? Icons.groups : Icons.group;
    final color = isGeneral ? const Color(0xFF1B5E20) : const Color(0xFFFF6F00);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.8),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
