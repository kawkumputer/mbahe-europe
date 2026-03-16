import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/compte_rendu_provider.dart';
import '../models/compte_rendu_model.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../l10n/app_localizations.dart';

class CreateCompteRenduScreen extends StatefulWidget {
  const CreateCompteRenduScreen({super.key});

  @override
  State<CreateCompteRenduScreen> createState() =>
      _CreateCompteRenduScreenState();
}

class _CreateCompteRenduScreenState extends State<CreateCompteRenduScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _pointController = TextEditingController();

  ReunionType _selectedType = ReunionType.assembleeGenerale;
  DateTime _selectedDate = DateTime.now();
  final List<String> _points = [];

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _pointController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _addPoint() {
    final text = _pointController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _points.add(text);
        _pointController.clear();
      });
    }
  }

  void _removePoint(int index) {
    setState(() => _points.removeAt(index));
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.get('cr_min_point'),
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final user = context.read<AuthProvider>().currentUser!;
    final success = await context.read<CompteRenduProvider>().createCompteRendu(
          title: _titleController.text.trim(),
          type: _selectedType,
          reunionDate: _selectedDate,
          authorId: user.id,
          authorName: user.fullName,
          points: List.from(_points),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.get('cr_created_success'),
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.approved,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CompteRenduProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.get('cr_new_title')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              CustomTextField(
                controller: _titleController,
                label: AppLocalizations.get('cr_field_title'),
                hint: AppLocalizations.get('cr_field_title_hint'),
                prefixIcon: Icons.title_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.get('cr_field_title_required');
                  }
                  return null;
                },
              ),

              // Type de réunion
              Text(
                AppLocalizations.get('cr_reunion_type'),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ReunionType.values.map((type) {
                  final isSelected = _selectedType == type;
                  String label;
                  switch (type) {
                    case ReunionType.assembleeGenerale:
                      label = AppLocalizations.get('cr_type_ag');
                      break;
                    case ReunionType.bureau:
                      label = AppLocalizations.get('cr_type_bureau');
                      break;
                    case ReunionType.extraordinaire:
                      label = AppLocalizations.get('cr_type_extra');
                      break;
                  }
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedType = type);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: GoogleFonts.poppins(
                      color:
                          isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Date de la réunion
              Text(
                AppLocalizations.get('cr_reunion_date_label'),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_calendar_rounded,
                          color: AppColors.textSecondary, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Points discutés
              Row(
                children: [
                  Text(
                    AppLocalizations.get('cr_points'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_points.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_points.length}',
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Champ ajout de point
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pointController,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.get('cr_add_point'),
                        hintStyle: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _addPoint(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _addPoint,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Liste des points ajoutés
              ...(_points.asMap().entries.map((entry) {
                final index = entry.key;
                final point = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.poppins(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          point,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removePoint(index),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.rejected,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                );
              })),

              const SizedBox(height: 20),

              // Notes
              Text(
                AppLocalizations.get('cr_notes_optional'),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                      AppLocalizations.get('cr_notes_hint'),
                  hintStyle: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Bouton créer
              CustomButton(
                text: AppLocalizations.get('cr_create_button'),
                isLoading: provider.isLoading,
                onPressed: _handleSubmit,
                icon: Icons.save_rounded,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
