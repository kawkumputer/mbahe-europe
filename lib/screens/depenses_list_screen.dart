import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/depense_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/depense_provider.dart';
import '../providers/cotisation_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class DepensesListScreen extends StatefulWidget {
  const DepensesListScreen({super.key});

  @override
  State<DepensesListScreen> createState() => _DepensesListScreenState();
}

class _DepensesListScreenState extends State<DepensesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DepenseProvider>().loadDepenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isAdmin = user?.role == UserRole.admin || user?.role == UserRole.sysAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.get('depenses_title')),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _showCreateDepenseDialog(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: SafeArea(
        child: Consumer<DepenseProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final depenses = provider.depenses;

            if (depenses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.money_off_rounded, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.get('depenses_empty'),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Calculer le total des dépenses validées
            final totalApproved = depenses
                .where((d) => d.isApproved)
                .fold<double>(0.0, (sum, d) => sum + d.amount);

            return RefreshIndicator(
              onRefresh: () => provider.loadDepenses(),
              child: Column(
                children: [
                  // En-tête avec total
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFEF5350)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE53935).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.get('depenses_total_approved'),
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${totalApproved.toStringAsFixed(2)}€',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMiniStat(
                              '${depenses.where((d) => d.isApproved).length}',
                              AppLocalizations.get('depenses_validated'),
                              Colors.white,
                            ),
                            const SizedBox(width: 24),
                            _buildMiniStat(
                              '${depenses.where((d) => d.isPending).length}',
                              AppLocalizations.get('depenses_pending'),
                              Colors.amber[200]!,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Total général restant (même calcul que le bilan des réunions)
                  FutureBuilder<List<double>>(
                    future: Future.wait([
                      context.read<CotisationProvider>().getPreviousYearsTotalAmount(),
                      context.read<CotisationProvider>().getTotalAllPaidAmount(),
                      context.read<AuthProvider>().getTotalAdhesionPaid(),
                    ]),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final previousYears = snapshot.data![0];
                      final allPaid = snapshot.data![1];
                      final totalAdhesion = snapshot.data![2];
                      final totalRestant = previousYears + allPaid + totalAdhesion - totalApproved;
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance_wallet_rounded,
                                size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.get('depenses_total_remaining'),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${totalRestant.toStringAsFixed(2)}€',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // Liste des dépenses
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: depenses.length,
                      itemBuilder: (context, index) {
                        return _buildDepenseCard(depenses[index], isAdmin, user);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: color.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDepenseCard(DepenseModel depense, bool isAdmin, UserModel? user) {
    Color statusColor;
    IconData statusIcon;
    switch (depense.status) {
      case DepenseStatus.approved:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case DepenseStatus.rejected:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        break;
      case DepenseStatus.pending:
        statusColor = AppColors.warning;
        statusIcon = Icons.hourglass_top_rounded;
        break;
    }

    final canValidate = isAdmin && depense.isPending && depense.createdBy != user?.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        depense.motif,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        depense.formattedDate,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '-${depense.formattedAmount}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.error,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        depense.statusLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Description
          if (depense.description != null && depense.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                depense.description!,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

          // Infos création et validation
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${AppLocalizations.get('depenses_created_by')} ${depense.createdByName}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (depense.validatedByName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        depense.isApproved ? Icons.verified_outlined : Icons.block,
                        size: 14,
                        color: depense.isApproved ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${depense.isApproved ? AppLocalizations.get('depenses_approved_by') : AppLocalizations.get('depenses_rejected_by')} ${depense.validatedByName}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: depense.isApproved ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
                if (depense.isRejected && depense.rejectionReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${AppLocalizations.get('depenses_reason')}: ${depense.rejectionReason}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Boutons de validation (pour les autres admins uniquement)
          if (canValidate)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(context, depense),
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(AppLocalizations.get('depenses_reject')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmApprove(context, depense),
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(AppLocalizations.get('depenses_approve')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Message + bouton supprimer si c'est l'admin créateur et pending
          if (isAdmin && depense.isPending && depense.createdBy == user?.id)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.get('depenses_awaiting_other_admin'),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context, depense),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(AppLocalizations.get('depenses_delete')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Bouton supprimer pour les autres admins sur dépenses pending
          if (isAdmin && depense.isPending && depense.createdBy != user?.id)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _confirmDelete(context, depense),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(AppLocalizations.get('depenses_delete')),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCreateDepenseDialog(BuildContext context) {
    final amountController = TextEditingController();
    final motifController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            AppLocalizations.get('depenses_create'),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Montant
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.get('depenses_amount'),
                    prefixText: '€ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                // Motif
                TextField(
                  controller: motifController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.get('depenses_motif'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                // Description
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.get('depenses_description'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                // Date
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2022),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.get('depenses_date'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.get('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
                final motif = motifController.text.trim();

                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.get('depenses_amount_required'))),
                  );
                  return;
                }
                if (motif.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.get('depenses_motif_required'))),
                  );
                  return;
                }

                Navigator.pop(ctx);

                final success = await context.read<DepenseProvider>().createDepense(
                  amount: amount,
                  motif: motif,
                  description: descriptionController.text.trim().isNotEmpty
                      ? descriptionController.text.trim()
                      : null,
                  depenseDate: selectedDate,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? AppLocalizations.get('depenses_created')
                          : AppLocalizations.get('depenses_create_error')),
                      backgroundColor: success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.get('depenses_submit')),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmApprove(BuildContext context, DepenseModel depense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalizations.get('depenses_confirm_approve'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppLocalizations.get('depenses_motif')}: ${depense.motif}'),
            const SizedBox(height: 8),
            Text(
              '${AppLocalizations.get('depenses_amount')}: -${depense.formattedAmount}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text('${AppLocalizations.get('depenses_created_by')} ${depense.createdByName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<DepenseProvider>().approveDepense(depense.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? AppLocalizations.get('depenses_approved')
                        : AppLocalizations.get('depenses_approve_error')),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.get('depenses_approve')),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DepenseModel depense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalizations.get('depenses_confirm_delete'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppLocalizations.get('depenses_motif')}: ${depense.motif}'),
            const SizedBox(height: 8),
            Text(
              '${AppLocalizations.get('depenses_amount')}: -${depense.formattedAmount}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<DepenseProvider>().deleteDepense(depense.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? AppLocalizations.get('depenses_deleted')
                        : AppLocalizations.get('depenses_delete_error')),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.get('delete')),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, DepenseModel depense) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalizations.get('depenses_confirm_reject'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppLocalizations.get('depenses_motif')}: ${depense.motif}'),
            Text('${AppLocalizations.get('depenses_amount')}: -${depense.formattedAmount}'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppLocalizations.get('depenses_reject_reason'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.get('depenses_reason_required'))),
                );
                return;
              }
              Navigator.pop(ctx);
              final success = await context.read<DepenseProvider>().rejectDepense(depense.id, reason);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? AppLocalizations.get('depenses_rejected')
                        : AppLocalizations.get('depenses_reject_error')),
                    backgroundColor: success ? AppColors.warning : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.get('depenses_reject')),
          ),
        ],
      ),
    );
  }
}
