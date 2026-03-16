import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/bureau_provider.dart';
import '../models/mandat_model.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class ManageMandatsScreen extends StatefulWidget {
  const ManageMandatsScreen({super.key});

  @override
  State<ManageMandatsScreen> createState() => _ManageMandatsScreenState();
}

class _ManageMandatsScreenState extends State<ManageMandatsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BureauProvider>().loadMandats();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BureauProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.get('mandat_title')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateMandatDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: provider.isLoading && provider.mandats.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : provider.mandats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note_rounded, size: 60, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(AppLocalizations.get('mandat_no_mandat'), style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(AppLocalizations.get('mandat_no_mandat_desc'), style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.7))),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => provider.loadMandats(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.mandats.length,
                      itemBuilder: (context, index) {
                        return _buildMandatCard(provider.mandats[index], provider);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildMandatCard(MandatModel mandat, BureauProvider provider) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/manage-bureau', arguments: mandat).then((_) {
          provider.loadMandats();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: mandat.isActive
              ? Border.all(color: AppColors.approved, width: 2)
              : null,
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
                    color: const Color(0xFF0D47A1).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event_note_rounded, color: Color(0xFF0D47A1), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mandat.label,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        mandat.formattedPeriod,
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (mandat.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.approved.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizations.get('mandat_active'),
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.approved),
                    ),
                  ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMandatAction(value, mandat, provider),
                  itemBuilder: (ctx) => [
                    if (!mandat.isActive)
                      PopupMenuItem(value: 'activate', child: Text(AppLocalizations.get('mandat_activate'))),
                    PopupMenuItem(value: 'delete', child: Text(AppLocalizations.get('delete'), style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.people_rounded, size: 14, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.get('mandat_manage_composition'),
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleMandatAction(String action, MandatModel mandat, BureauProvider provider) async {
    if (action == 'activate') {
      final success = await provider.activateMandat(mandat.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? AppLocalizations.get('mandat_activated') : AppLocalizations.get('error')),
            backgroundColor: success ? AppColors.approved : AppColors.rejected,
          ),
        );
      }
    } else if (action == 'delete') {
      _confirmDeleteMandat(mandat, provider);
    }
  }

  void _confirmDeleteMandat(MandatModel mandat, BureauProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.get('delete'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        content: Text('${AppLocalizations.get('mandat_delete_confirm')} "${mandat.label}" ${AppLocalizations.get('mandat_delete_confirm_desc')}', style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.get('cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.deleteMandat(mandat.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? AppLocalizations.get('mandat_deleted') : AppLocalizations.get('error')),
                    backgroundColor: success ? AppColors.approved : AppColors.rejected,
                  ),
                );
              }
            },
            child: Text(AppLocalizations.get('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCreateMandatDialog() {
    final labelController = TextEditingController();
    DateTime startDate = DateTime(DateTime.now().year);
    DateTime endDate = DateTime(DateTime.now().year + 2);
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.get('mandat_create'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.get('mandat_name'),
                    hintText: AppLocalizations.get('mandat_name_hint'),
                    labelStyle: GoogleFonts.poppins(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2040),
                          );
                          if (picked != null) setDialogState(() => startDate = picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: AppLocalizations.get('mandat_start'),
                            labelStyle: GoogleFonts.poppins(fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          child: Text(
                            '${startDate.day}/${startDate.month}/${startDate.year}',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: endDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2040),
                          );
                          if (picked != null) setDialogState(() => endDate = picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: AppLocalizations.get('mandat_end'),
                            labelStyle: GoogleFonts.poppins(fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          child: Text(
                            '${endDate.day}/${endDate.month}/${endDate.year}',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: Text(AppLocalizations.get('mandat_active_switch'), style: GoogleFonts.poppins(fontSize: 13)),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.approved,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.get('cancel'))),
            ElevatedButton(
              onPressed: () async {
                if (labelController.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final provider = context.read<BureauProvider>();
                final success = await provider.createMandat(
                  label: labelController.text.trim(),
                  startDate: startDate,
                  endDate: endDate,
                  isActive: isActive,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? AppLocalizations.get('mandat_created') : AppLocalizations.get('error')),
                      backgroundColor: success ? AppColors.approved : AppColors.rejected,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(AppLocalizations.get('create'), style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
