import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cotisation_provider.dart';
import '../models/user_model.dart';
import '../models/cotisation_model.dart';
import '../theme/app_theme.dart';
import '../widgets/search_bar_widget.dart';
import '../l10n/app_localizations.dart';
import '../services/pdf_export_service.dart';
import '../services/supabase_cotisation_service.dart';

class AdminCotisationsScreen extends StatefulWidget {
  const AdminCotisationsScreen({super.key});

  @override
  State<AdminCotisationsScreen> createState() => _AdminCotisationsScreenState();
}

class _AdminCotisationsScreenState extends State<AdminCotisationsScreen> {
  UserModel? _selectedMember;
  int _selectedYear = DateTime.now().year;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<UserModel> _approvedMembers = [];
  bool _isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final authProvider = context.read<AuthProvider>();
    final allMembers = await authProvider.getAllMembers();
    if (mounted) {
      setState(() {
        _approvedMembers = allMembers
            .where((m) => m.status == AccountStatus.approved)
            .toList();
        _isLoadingMembers = false;
      });
    }
  }

  List<UserModel> _filterMembers(List<UserModel> members) {
    if (_searchQuery.isEmpty) return members;
    final query = _searchQuery.toLowerCase();
    return members.where((u) {
      return u.firstName.toLowerCase().contains(query) ||
          u.lastName.toLowerCase().contains(query) ||
          u.fullName.toLowerCase().contains(query) ||
          u.phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final members = _filterMembers(_approvedMembers);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.get('cotisations_admin_title')),
        actions: [
          if (_selectedMember != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              tooltip: AppLocalizations.get('pdf_export_member'),
              onPressed: () => _exportMemberPdf(context),
            )
          else if (_approvedMembers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              tooltip: AppLocalizations.get('pdf_export_all'),
              onPressed: () => _exportAllPdf(context),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingMembers
          ? const Center(child: CircularProgressIndicator())
          : _selectedMember == null
              ? _buildMemberList(members)
              : _buildMemberCotisations(context),
      ),
    );
  }

  Widget _buildMemberList(List<UserModel> members) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.get('cotis_admin_select'),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.get('cotis_admin_select_desc'),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Barre de recherche
          SearchBarWidget(
            controller: _searchController,
            hint: AppLocalizations.get('members_search'),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),

          const SizedBox(height: 16),
          if (members.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.people_outline_rounded,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.get('cotis_admin_no_member'),
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ...members.map((member) => _buildMemberCard(member)),
        ],
      ),
    );
  }

  Widget _buildMemberCard(UserModel member) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMember = member);
        context.read<CotisationProvider>().setYear(_selectedYear);
        context.read<CotisationProvider>().loadCotisations(member.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: member.photoUrl != null && member.photoUrl!.isNotEmpty
                  ? NetworkImage(member.photoUrl!)
                  : null,
              child: member.photoUrl == null || member.photoUrl!.isEmpty
                  ? Text(
                      '${member.firstName[0]}${member.lastName[0]}',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    member.phone,
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
      ),
    );
  }

  Widget _buildMemberCotisations(BuildContext context) {
    final provider = context.watch<CotisationProvider>();
    final member = _selectedMember!;

    return Column(
      children: [
        // En-tête membre
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withOpacity(0.05),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedMember = null),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                backgroundImage: member.photoUrl != null && member.photoUrl!.isNotEmpty
                    ? NetworkImage(member.photoUrl!)
                    : null,
                child: member.photoUrl == null || member.photoUrl!.isEmpty
                    ? Text(
                        '${member.firstName[0]}${member.lastName[0]}',
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      member.phone,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Sélecteur d'année
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildYearSelector(provider, member.id),
        ),

        // Résumé rapide
        if (!provider.isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildQuickSummary(provider),
          ),

        const SizedBox(height: 8),

        // Liste des cotisations
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ...provider.cotisations.map(
                      (c) => _buildCotisationTile(c, member.id),
                    ),
                    const SizedBox(height: 12),
                    _buildVacationInfo(),
                    const SizedBox(height: 20),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildYearSelector(CotisationProvider provider, String userId) {
    final years = [2026, 2025];

    return Row(
      children: years.map((year) {
        final isSelected = _selectedYear == year;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text('$year'),
            selected: isSelected,
            onSelected: (_) {
              setState(() => _selectedYear = year);
              provider.setYear(year);
              provider.loadCotisations(userId);
            },
            selectedColor: AppColors.primary,
            labelStyle: GoogleFonts.poppins(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickSummary(CotisationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            '${provider.totalPaid.toStringAsFixed(0)}€',
            AppLocalizations.get('cotis_admin_paid'),
            AppColors.approved,
          ),
          Container(width: 1, height: 30, color: AppColors.divider),
          _buildSummaryItem(
            '${provider.remaining.toStringAsFixed(0)}€',
            AppLocalizations.get('cotis_admin_remaining'),
            AppColors.rejected,
          ),
          Container(width: 1, height: 30, color: AppColors.divider),
          _buildSummaryItem(
            '${(provider.percentage * 100).toInt()}%',
            AppLocalizations.get('cotis_admin_progress'),
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCotisationTile(CotisationModel cotisation, String userId) {
    final isPaid = cotisation.isPaid;
    final isExempted = cotisation.isExempted;
    final Color statusColor;
    if (isExempted) {
      statusColor = const Color(0xFF1976D2);
    } else if (isPaid) {
      statusColor = AppColors.approved;
    } else {
      statusColor = AppColors.rejected;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isExempted
                  ? Icons.work_off_rounded
                  : (isPaid ? Icons.check_circle_rounded : Icons.cancel_rounded),
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cotisation.monthName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  isExempted
                      ? AppLocalizations.get('cotis_exempted_label')
                      : isPaid
                          ? '${cotisation.amount.toStringAsFixed(0)}€ — ${cotisation.statusLabel} (${cotisation.paymentMethodLabel})'
                          : '${cotisation.amount.toStringAsFixed(0)}€ — ${cotisation.statusLabel}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isExempted ? const Color(0xFF1976D2) : AppColors.textSecondary,
                  ),
                ),
                if (isPaid && cotisation.paidAt != null)
                  Text(
                    '${AppLocalizations.get('cotis_paid_on')} ${cotisation.paidAt!.day}/${cotisation.paidAt!.month}/${cotisation.paidAt!.year}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                if (cotisation.updatedByName != null)
                  Text(
                    '${AppLocalizations.get('cotis_by')} ${cotisation.updatedByName}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          // Boutons d'action
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouton chômage
              GestureDetector(
                onTap: () async {
                  final provider = context.read<CotisationProvider>();
                  if (isExempted) {
                    await provider.removeExemption(cotisation.id, userId);
                  } else {
                    await provider.markAsExempted(cotisation.id, userId);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF1976D2).withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    isExempted ? Icons.work_rounded : Icons.work_off_rounded,
                    size: 16,
                    color: const Color(0xFF1976D2),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Bouton toggle payé/impayé
              if (!isExempted)
                GestureDetector(
                  onTap: () async {
                    final provider = context.read<CotisationProvider>();
                    if (isPaid) {
                      await provider.markAsUnpaid(cotisation.id, userId);
                    } else {
                      _showPaymentMethodDialog(cotisation, userId);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppColors.rejected.withOpacity(0.1)
                          : AppColors.approved.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPaid
                            ? AppColors.rejected.withOpacity(0.3)
                            : AppColors.approved.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      isPaid ? AppLocalizations.get('cotis_admin_cancel') : AppLocalizations.get('cotis_admin_mark_paid'),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPaid ? AppColors.rejected : AppColors.approved,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodDialog(CotisationModel cotisation, String userId) {
    DateTime selectedDate = DateTime.now();
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            AppLocalizations.get('cotis_admin_payment_method'),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${cotisation.monthName} ${cotisation.year} — ${cotisation.amount.toStringAsFixed(0)}€',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    locale: const Locale('fr', 'FR'),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Date de paiement: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentOption(
                ctx,
                cotisation,
                userId,
                selectedDate,
                PaymentMethod.espece,
                Icons.money_rounded,
                AppLocalizations.get('payment_cash'),
                const Color(0xFF2E7D32),
              ),
              const SizedBox(height: 8),
              _buildPaymentOption(
                ctx,
                cotisation,
                userId,
                selectedDate,
                PaymentMethod.virement,
                Icons.account_balance_rounded,
                AppLocalizations.get('payment_transfer'),
                const Color(0xFF1565C0),
              ),
              const SizedBox(height: 8),
              _buildPaymentOption(
                ctx,
                cotisation,
                userId,
                selectedDate,
                PaymentMethod.cheque,
                Icons.receipt_long_rounded,
                AppLocalizations.get('payment_check'),
                const Color(0xFF6A1B9A),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext ctx,
    CotisationModel cotisation,
    String userId,
    DateTime paymentDate,
    PaymentMethod method,
    IconData icon,
    String label,
    Color color,
  ) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(ctx);
        await context.read<CotisationProvider>().markAsPaidWithDate(
              cotisation.id,
              userId,
              method,
              paymentDate,
            );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportMemberPdf(BuildContext context) async {
    final provider = context.read<CotisationProvider>();
    final member = _selectedMember!;

    await PdfExportService.exportMemberCotisations(
      member: member,
      cotisations: provider.cotisations,
      year: _selectedYear,
      summary: provider.summary,
    );
  }

  Future<void> _exportAllPdf(BuildContext context) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final service = SupabaseCotisationService();
      final cotisationsByUser = <String, List<CotisationModel>>{};
      final summariesByUser = <String, Map<String, dynamic>>{};

      for (final member in _approvedMembers) {
        final cotisations = await service.getCotisationsByUserAndYear(
          member.id,
          _selectedYear,
        );
        final summary = await service.getUserYearlySummary(
          member.id,
          _selectedYear,
        );
        cotisationsByUser[member.id] = cotisations;
        summariesByUser[member.id] = summary;
      }

      if (mounted) nav.pop();

      await PdfExportService.exportAllCotisations(
        members: _approvedMembers,
        cotisationsByUser: cotisationsByUser,
        summariesByUser: summariesByUser,
        year: _selectedYear,
      );
    } catch (e) {
      if (mounted) {
        nav.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.get('error_generic')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildVacationInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.beach_access_rounded,
              color: Colors.grey.shade500, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.get('cotis_admin_vacation'),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
