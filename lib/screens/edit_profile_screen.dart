import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _phoneController.text = user.phone;
      _bioController.text = user.bio ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: AppColors.rejected,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: Text(AppLocalizations.get('profile_take_photo')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(AppLocalizations.get('profile_from_gallery')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final profileProvider = context.read<ProfileProvider>();

    if (_selectedImage != null) {
      final success = await profileProvider.uploadProfilePhoto(
        userId: user.id,
        imageFile: _selectedImage!,
      );

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.get('profile_update_error')),
              backgroundColor: AppColors.rejected,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
    }

    final success = await profileProvider.updateProfile(
      userId: user.id,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        await context.read<AuthProvider>().refreshCurrentUser();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.get('profile_updated')),
            backgroundColor: AppColors.approved,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.get('profile_update_error')),
            backgroundColor: AppColors.rejected,
          ),
        );
      }
    }
  }

  Future<void> _deletePhoto() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.get('profile_delete_photo')),
        content: Text('Êtes-vous sûr de vouloir supprimer votre photo de profil ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.get('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.get('delete'),
              style: const TextStyle(color: AppColors.rejected),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final success = await context.read<ProfileProvider>().deleteProfilePhoto(user.id);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        await context.read<AuthProvider>().refreshCurrentUser();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.get('profile_photo_deleted')),
            backgroundColor: AppColors.approved,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.get('profile_update_error')),
            backgroundColor: AppColors.rejected,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.get('profile_edit')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                                    ? NetworkImage(user.photoUrl!)
                                    : null) as ImageProvider?,
                            child: _selectedImage == null &&
                                    (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                                ? Text(
                                    user != null
                                        ? '${user.firstName[0]}${user.lastName[0]}'
                                        : '',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 36,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                        TextButton.icon(
                          onPressed: _deletePhoto,
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: Text(AppLocalizations.get('profile_delete_photo')),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.rejected,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  AppLocalizations.get('profile_info'),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _firstNameController,
                  label: AppLocalizations.get('register_firstname'),
                  hint: AppLocalizations.get('register_firstname_hint'),
                  prefixIcon: Icons.person_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.get('register_firstname_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _lastNameController,
                  label: AppLocalizations.get('register_lastname'),
                  hint: AppLocalizations.get('register_lastname_hint'),
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.get('register_lastname_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: AppLocalizations.get('register_phone'),
                  hint: AppLocalizations.get('register_phone_hint'),
                  prefixIcon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.get('register_phone_required');
                    }
                    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
                      return AppLocalizations.get('register_phone_invalid');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.get('profile_bio'),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  maxLength: 200,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.get('profile_bio_hint'),
                    hintStyle: GoogleFonts.poppins(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: AppLocalizations.get('save'),
                  onPressed: _isLoading ? null : _saveProfile,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
