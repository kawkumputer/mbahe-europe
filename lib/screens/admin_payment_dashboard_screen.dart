import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/compte_rendu_model.dart';
import '../providers/cotisation_provider.dart';
import '../providers/compte_rendu_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class AdminPaymentDashboardScreen extends StatefulWidget {
  const AdminPaymentDashboardScreen({super.key});

  @override
  State<AdminPaymentDashboardScreen> createState() =>
      _AdminPaymentDashboardScreenState();
}

/// Données de récap pour une réunion
class _ReunionSummary {
  final CompteRenduModel reunion;
  final String periodLabel;
  final Map<String, dynamic> paymentData;
  final double cumulativeTotal;

  _ReunionSummary({
    required this.reunion,
    required this.periodLabel,
    required this.paymentData,
    required this.cumulativeTotal,
  });

  double get totalPaid => (paymentData['totalPaid'] ?? 0.0).toDouble();
  double get totalEspece => (paymentData['totalEspece'] ?? 0.0).toDouble();
  double get totalVirement => (paymentData['totalVirement'] ?? 0.0).toDouble();
  double get totalCheque => (paymentData['totalCheque'] ?? 0.0).toDouble();
  int get countEspece => paymentData['countEspece'] ?? 0;
  int get countVirement => paymentData['countVirement'] ?? 0;
  int get countCheque => paymentData['countCheque'] ?? 0;
  int get countTotal => paymentData['countTotal'] ?? 0;
}

class _AdminPaymentDashboardScreenState
    extends State<AdminPaymentDashboardScreen> {
  bool _isLoading = true;
  List<_ReunionSummary> _reunionSummaries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final compteRenduProvider = context.read<CompteRenduProvider>();
    final cotisationProvider = context.read<CotisationProvider>();

    await compteRenduProvider.loadComptesRendus();
    final reunions = compteRenduProvider.comptesRendus;

    // Trier par date croissante pour calculer les plages entre réunions
    final sortedAsc = List<CompteRenduModel>.from(reunions)
      ..sort((a, b) => a.reunionDate.compareTo(b.reunionDate));

    final summaries = <_ReunionSummary>[];

    for (int i = 0; i < sortedAsc.length; i++) {
      final reunion = sortedAsc[i];

      // Plage de dates : du lendemain de la réunion précédente jusqu'à la date de cette réunion
      // Pour la première réunion : depuis le 1er janvier de l'année de la réunion
      DateTime fromDate;
      if (i > 0) {
        final previous = sortedAsc[i - 1];
        fromDate = previous.reunionDate.add(const Duration(days: 1));
      } else {
        fromDate = DateTime(reunion.reunionDate.year, 1, 1);
      }
      final toDate = reunion.reunionDate;

      final periodLabel = _buildDateRangeLabel(fromDate, toDate);

      // Récupérer les paiements effectués (paidAt) dans cette plage
      // Inclut les paiements anticipés (ex: payer mars en février)
      final paymentData = await cotisationProvider.getPaymentSummaryByDateRange(
        fromDate,
        toDate,
      );

      summaries.add(_ReunionSummary(
        reunion: reunion,
        periodLabel: periodLabel,
        paymentData: paymentData,
        cumulativeTotal: 0,
      ));
    }

    // Calculer le total général cumulé (ordre chronologique)
    double cumul = 0;
    for (int i = 0; i < summaries.length; i++) {
      cumul += summaries[i].totalPaid;
      summaries[i] = _ReunionSummary(
        reunion: summaries[i].reunion,
        periodLabel: summaries[i].periodLabel,
        paymentData: summaries[i].paymentData,
        cumulativeTotal: cumul,
      );
    }

    // Afficher de la plus récente à la plus ancienne
    summaries.sort((a, b) =>
        b.reunion.reunionDate.compareTo(a.reunion.reunionDate));

    setState(() {
      _reunionSummaries = summaries;
      _isLoading = false;
    });
  }

  String _buildDateRangeLabel(DateTime from, DateTime to) {
    const months = [
      '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc',
    ];
    final fromStr = '${from.day} ${months[from.month]} ${from.year}';
    final toStr = '${to.day} ${months[to.month]} ${to.year}';
    return '$fromStr — $toStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.get('payment_title')),
      ),
      body: SafeArea(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reunionSummaries.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _reunionSummaries.length,
                    itemBuilder: (context, index) {
                      return _buildReunionCard(_reunionSummaries[index]);
                    },
                  ),
                ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.get('payment_no_reunion'),
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.get('payment_no_reunion_desc'),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReunionCard(_ReunionSummary summary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête réunion
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        summary.reunion.title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      summary.reunion.formattedDate,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        summary.periodLabel,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Total
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.get('payment_total_collected'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${summary.totalPaid.toStringAsFixed(0)}€',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Barre de répartition
          if (summary.totalPaid > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildDistributionBar(summary),
            ),

          const SizedBox(height: 12),

          // Détail par mode
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: _buildPaymentRow(
              Icons.money_rounded,
              AppLocalizations.get('payment_cash'),
              const Color(0xFF2E7D32),
              summary.totalEspece,
              summary.countEspece,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: _buildPaymentRow(
              Icons.account_balance_rounded,
              AppLocalizations.get('payment_transfer'),
              const Color(0xFF1565C0),
              summary.totalVirement,
              summary.countVirement,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: _buildPaymentRow(
              Icons.receipt_long_rounded,
              AppLocalizations.get('payment_check'),
              const Color(0xFF6A1B9A),
              summary.totalCheque,
              summary.countCheque,
            ),
          ),

          // Total général cumulé
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.get('payment_total_cumul'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${summary.cumulativeTotal.toStringAsFixed(0)}€',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              '${summary.countTotal} ${AppLocalizations.get('payment_count')}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBar(_ReunionSummary summary) {
    final total = summary.totalPaid;
    final especeRatio = total > 0 ? summary.totalEspece / total : 0.0;
    final virementRatio = total > 0 ? summary.totalVirement / total : 0.0;
    final chequeRatio = total > 0 ? summary.totalCheque / total : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 20,
        child: Row(
          children: [
            if (especeRatio > 0)
              Expanded(
                flex: (especeRatio * 100).round(),
                child: Container(
                  color: const Color(0xFF2E7D32),
                  alignment: Alignment.center,
                  child: especeRatio >= 0.18
                      ? Text(
                          '${(especeRatio * 100).round()}%',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
              ),
            if (virementRatio > 0)
              Expanded(
                flex: (virementRatio * 100).round(),
                child: Container(
                  color: const Color(0xFF1565C0),
                  alignment: Alignment.center,
                  child: virementRatio >= 0.18
                      ? Text(
                          '${(virementRatio * 100).round()}%',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
              ),
            if (chequeRatio > 0)
              Expanded(
                flex: (chequeRatio * 100).round(),
                child: Container(
                  color: const Color(0xFF6A1B9A),
                  alignment: Alignment.center,
                  child: chequeRatio >= 0.18
                      ? Text(
                          '${(chequeRatio * 100).round()}%',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(
    IconData icon,
    String label,
    Color color,
    double total,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label ($count)',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '${total.toStringAsFixed(0)}€',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
