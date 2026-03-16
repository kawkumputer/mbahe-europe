import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cotisation_provider.dart';
import '../models/cotisation_model.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class MemberCotisationsScreen extends StatefulWidget {
  const MemberCotisationsScreen({super.key});

  @override
  State<MemberCotisationsScreen> createState() =>
      _MemberCotisationsScreenState();
}

class _MemberCotisationsScreenState extends State<MemberCotisationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      context.read<CotisationProvider>().loadCotisations(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final cotisationProvider = context.watch<CotisationProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.get('cotisations_title')),
      ),
      body: SafeArea(
        child: cotisationProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Résumé annuel
                  _buildSummaryCard(cotisationProvider),

                  const SizedBox(height: 20),

                  // Sélecteur d'année
                  _buildYearSelector(cotisationProvider, user?.id ?? ''),

                  const SizedBox(height: 20),

                  // Légende
                  _buildLegend(),

                  const SizedBox(height: 16),

                  // Liste des mois
                  ...cotisationProvider.cotisations.map(
                    (c) => _buildMonthCard(c),
                  ),

                  // Mois de vacances
                  if (cotisationProvider.selectedYear > 0) ...[
                    const SizedBox(height: 12),
                    _buildVacationCard(),
                  ],
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildSummaryCard(CotisationProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppLocalizations.get('cotis_year')} ${provider.selectedYear}',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${provider.totalPaid.toStringAsFixed(0)}€',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${AppLocalizations.get('cotis_on')} ${provider.totalDue.toStringAsFixed(0)}€',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: provider.percentage,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                    Text(
                      '${(provider.percentage * 100).toInt()}%',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniStat(
                '${provider.paidCount}',
                AppLocalizations.get('cotis_paid_label'),
                Icons.check_circle_rounded,
              ),
              const SizedBox(width: 20),
              _buildMiniStat(
                '${provider.unpaidCount}',
                AppLocalizations.get('cotis_unpaid_label'),
                Icons.cancel_rounded,
              ),
              const SizedBox(width: 20),
              _buildMiniStat(
                '${provider.remaining.toStringAsFixed(0)}€',
                AppLocalizations.get('cotis_remaining_label'),
                Icons.account_balance_wallet_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYearSelector(CotisationProvider provider, String userId) {
    final currentYear = DateTime.now().year;
    final years = [currentYear, currentYear - 1, currentYear - 2];

    return Row(
      children: years.map((year) {
        final isSelected = provider.selectedYear == year;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text('$year'),
            selected: isSelected,
            onSelected: (_) {
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

  Widget _buildLegend() {
    return Row(
      children: [
        _buildLegendItem(AppColors.approved, AppLocalizations.get('cotis_legend_paid')),
        const SizedBox(width: 16),
        _buildLegendItem(AppColors.rejected, AppLocalizations.get('cotis_legend_unpaid')),
        const SizedBox(width: 16),
        _buildLegendItem(const Color(0xFF1976D2), AppLocalizations.get('cotis_legend_exempted')),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.grey.shade400, AppLocalizations.get('cotis_legend_vacation')),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthCard(CotisationModel cotisation) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isExempted
                  ? Icons.work_off_rounded
                  : (isPaid ? Icons.check_circle_rounded : Icons.cancel_rounded),
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cotisation.monthName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (isExempted) ...[
                  Text(
                    AppLocalizations.get('cotis_exempted_label'),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF1976D2),
                    ),
                  ),
                  if (cotisation.updatedByName != null)
                    Text(
                      '${AppLocalizations.get('cotis_by')} ${cotisation.updatedByName}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ] else if (isPaid && cotisation.paidAt != null) ...[
                  Text(
                    '${AppLocalizations.get('cotis_paid_on')} ${cotisation.paidAt!.day}/${cotisation.paidAt!.month}/${cotisation.paidAt!.year}'
                    '${cotisation.paymentMethod != null ? ' — ${cotisation.paymentMethodLabel}' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (cotisation.updatedByName != null)
                    Text(
                      '${AppLocalizations.get('cotis_by')} ${cotisation.updatedByName}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isExempted ? '0€' : '${cotisation.amount.toStringAsFixed(0)}€',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: statusColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  cotisation.statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVacationCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.beach_access_rounded,
              color: Colors.grey.shade500,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.get('cotis_vacation_months'),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  AppLocalizations.get('cotis_vacation_desc'),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
