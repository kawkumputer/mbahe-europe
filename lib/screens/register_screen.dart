import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/association_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _selectedAssociation = 'general'; // Association par défaut

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      associationType: _selectedAssociation,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/pending-approval');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Bouton retour
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  AppLocalizations.get('register_title'),
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 32),

                // Champs du formulaire
                CustomTextField(
                  controller: _lastNameController,
                  label: AppLocalizations.get('register_lastname'),
                  hint: AppLocalizations.get('register_lastname_hint'),
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.get('register_lastname_required');
                    }
                    return null;
                  },
                ),
                CustomTextField(
                  controller: _firstNameController,
                  label: AppLocalizations.get('register_firstname'),
                  hint: AppLocalizations.get('register_firstname_hint'),
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.get('register_firstname_required');
                    }
                    return null;
                  },
                ),
                CustomTextField(
                  controller: _phoneController,
                  label: AppLocalizations.get('register_phone'),
                  hint: AppLocalizations.get('register_phone_hint'),
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.get('register_phone_required');
                    }
                    if (value.trim().length < 10) {
                      return AppLocalizations.get('register_phone_invalid');
                    }
                    return null;
                  },
                ),
                CustomTextField(
                  controller: _usernameController,
                  label: AppLocalizations.get('register_username'),
                  hint: AppLocalizations.get('register_username_hint'),
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.get('register_username_required');
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_-]{3,20}$').hasMatch(value.trim())) {
                      return AppLocalizations.get('register_username_invalid');
                    }
                    return null;
                  },
                ),
                CustomTextField(
                  controller: _passwordController,
                  label: AppLocalizations.get('register_password'),
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.get('register_password_required');
                    }
                    if (value.length < 6) {
                      return AppLocalizations.get('register_password_min');
                    }
                    return null;
                  },
                ),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: AppLocalizations.get('register_confirm_password'),
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.get('register_confirm_required');
                    }
                    if (value != _passwordController.text) {
                      return AppLocalizations.get('register_password_mismatch');
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Sélection de l'association
                Text(
                  'Choisissez votre association',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildAssociationCard(
                        type: 'general',
                        title: 'MBAHE Europe',
                        subtitle: 'Association générale',
                        icon: Icons.groups,
                        isSelected: _selectedAssociation == 'general',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAssociationCard(
                        type: 'jeunes',
                        title: 'La jeunesse de M\'bahé',
                        subtitle: 'Association des jeunes',
                        icon: Icons.group,
                        isSelected: _selectedAssociation == 'jeunes',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Message d'erreur
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.errorMessage != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.error, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  auth.errorMessage!,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Bouton inscription
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return CustomButton(
                      text: AppLocalizations.get('register_button'),
                      isLoading: auth.isLoading,
                      onPressed: _handleRegister,
                      icon: Icons.person_add_rounded,
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Lien connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.get('register_already_member'),
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.read<AuthProvider>().clearError();
                        Navigator.pop(context);
                      },
                      child: Text(
                        AppLocalizations.get('register_login'),
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssociationCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    final color = AssociationColors.getPrimaryColor(type);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAssociation = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? AssociationColors.getGradient(type) : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                  ? Colors.white.withOpacity(0.3)
                  : color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isSelected 
                  ? Colors.white.withOpacity(0.9)
                  : AppColors.textSecondary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
