import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cotisation_provider.dart';
import '../models/user_model.dart';
import '../models/cotisation_model.dart';
import '../theme/app_theme.dart';
import '../widgets/search_bar_widget.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final authProvider = context.watch<AuthProvider>();
    final members = _filterMembers(
      authProvider.getAllMembers().where(
        (m) => m.status == AccountStatus.approved,
      ).toList(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion cotisations'),
      ),
      body: _selectedMember == null
          ? _buildMemberList(members)
          : _buildMemberCotisations(context),
    );
  }

  Widget _buildMemberList(List<UserModel> members) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sélectionnez un adhérent',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pour consulter et gérer ses cotisations',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Barre de recherche
          SearchBarWidget(
            controller: _searchController,
            hint: 'Rechercher par nom, prénom ou téléphone...',
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
                    'Aucun adhérent approuvé',
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
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                '${member.firstName[0]}${member.lastName[0]}',
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
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
          color: AppColors.primary.withValues(alpha: 0.05),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedMember = null),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
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
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  '${member.firstName[0]}${member.lastName[0]}',
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
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
    final currentYear = DateTime.now().year;
    final years = [currentYear, currentYear - 1, currentYear - 2];

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
            color: Colors.black.withValues(alpha: 0.04),
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
            'Payé',
            AppColors.approved,
          ),
          Container(width: 1, height: 30, color: AppColors.divider),
          _buildSummaryItem(
            '${provider.remaining.toStringAsFixed(0)}€',
            'Restant',
            AppColors.rejected,
          ),
          Container(width: 1, height: 30, color: AppColors.divider),
          _buildSummaryItem(
            '${(provider.percentage * 100).toInt()}%',
            'Progression',
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
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              color: statusColor.withValues(alpha: 0.1),
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
                      ? 'Exempté — Chômage'
                      : isPaid
                          ? '${cotisation.amount.toStringAsFixed(0)}€ — ${cotisation.statusLabel} (${cotisation.paymentMethodLabel})'
                          : '${cotisation.amount.toStringAsFixed(0)}€ — ${cotisation.statusLabel}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isExempted ? const Color(0xFF1976D2) : AppColors.textSecondary,
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
                    color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF1976D2).withValues(alpha: 0.3),
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
                          ? AppColors.rejected.withValues(alpha: 0.1)
                          : AppColors.approved.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPaid
                            ? AppColors.rejected.withValues(alpha: 0.3)
                            : AppColors.approved.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      isPaid ? 'Annuler' : 'Marquer payé',
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Mode de paiement',
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
            _buildPaymentOption(
              ctx,
              cotisation,
              userId,
              PaymentMethod.espece,
              Icons.money_rounded,
              'Espèce',
              const Color(0xFF2E7D32),
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              ctx,
              cotisation,
              userId,
              PaymentMethod.virement,
              Icons.account_balance_rounded,
              'Virement',
              const Color(0xFF1565C0),
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              ctx,
              cotisation,
              userId,
              PaymentMethod.cheque,
              Icons.receipt_long_rounded,
              'Chèque',
              const Color(0xFF6A1B9A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext ctx,
    CotisationModel cotisation,
    String userId,
    PaymentMethod method,
    IconData icon,
    String label,
    Color color,
  ) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(ctx);
        await context.read<CotisationProvider>().markAsPaid(
              cotisation.id,
              userId,
              method,
            );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
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
              'Nov. & Déc. — Mois de vacances (pas de cotisation)',
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
