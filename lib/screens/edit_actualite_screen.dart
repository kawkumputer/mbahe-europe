import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/actualite_provider.dart';
import '../models/actualite_model.dart';
import '../theme/app_theme.dart';

class EditActualiteScreen extends StatefulWidget {
  const EditActualiteScreen({super.key});

  @override
  State<EditActualiteScreen> createState() => _EditActualiteScreenState();
}

class _EditActualiteScreenState extends State<EditActualiteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late ActualiteCategory _category;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final actu = ModalRoute.of(context)!.settings.arguments as ActualiteModel;
      _titleController = TextEditingController(text: actu.title);
      _contentController = TextEditingController(text: actu.content);
      _category = actu.category;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final actu = ModalRoute.of(context)!.settings.arguments as ActualiteModel;
    final provider = context.read<ActualiteProvider>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final success = await provider.updateActualite(
      actu.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      category: _category,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Actualité mise à jour'),
            backgroundColor: AppColors.approved,
          ),
        );
        nav.pop();
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour'),
            backgroundColor: AppColors.rejected,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'actualité'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check_rounded),
                  onPressed: _save,
                ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Catégorie
                Text(
                  'Catégorie',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ActualiteCategory.values.map((cat) {
                    final selected = _category == cat;
                    final color = _catColor(cat);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: Container(
                          margin: EdgeInsets.only(
                            right: cat != ActualiteCategory.annonce ? 8 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected ? color : Colors.grey.shade300,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _catIcon(cat),
                                color: selected ? color : AppColors.textSecondary,
                                size: 22,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _catLabel(cat),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                  color: selected ? color : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Titre
                TextFormField(
                  controller: _titleController,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Titre',
                    labelStyle: GoogleFonts.poppins(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Le titre est requis' : null,
                ),

                const SizedBox(height: 16),

                // Contenu
                TextFormField(
                  controller: _contentController,
                  maxLines: 10,
                  style: GoogleFonts.poppins(fontSize: 13, height: 1.6),
                  decoration: InputDecoration(
                    labelText: 'Contenu',
                    alignLabelWithHint: true,
                    labelStyle: GoogleFonts.poppins(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Le contenu est requis' : null,
                ),

                const SizedBox(height: 24),

                // Bouton sauvegarder
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: Text(
                      'Enregistrer',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _catColor(ActualiteCategory cat) {
    switch (cat) {
      case ActualiteCategory.actualite:
        return const Color(0xFF1976D2);
      case ActualiteCategory.evenement:
        return const Color(0xFF6A1B9A);
      case ActualiteCategory.annonce:
        return const Color(0xFFEF6C00);
    }
  }

  IconData _catIcon(ActualiteCategory cat) {
    switch (cat) {
      case ActualiteCategory.actualite:
        return Icons.article_rounded;
      case ActualiteCategory.evenement:
        return Icons.event_rounded;
      case ActualiteCategory.annonce:
        return Icons.campaign_rounded;
    }
  }

  String _catLabel(ActualiteCategory cat) {
    switch (cat) {
      case ActualiteCategory.actualite:
        return 'Actualité';
      case ActualiteCategory.evenement:
        return 'Événement';
      case ActualiteCategory.annonce:
        return 'Annonce';
    }
  }
}
