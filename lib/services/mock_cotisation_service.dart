import '../models/cotisation_model.dart';

class MockCotisationService {
  static final MockCotisationService _instance =
      MockCotisationService._internal();
  factory MockCotisationService() => _instance;
  MockCotisationService._internal() {
    _generateMockData();
  }

  final List<CotisationModel> _cotisations = [];

  List<CotisationModel> get cotisations => List.unmodifiable(_cotisations);

  void _generateMockData() {
    int idCounter = 1;

    // Cotisations pour l'adhérent approuvé (userId: '2' - Jean Dupont)
    // 2025 : Janvier à Juin payés, Juillet à Octobre impayés
    for (final month in CotisationModel.cotisableMonths) {
      _cotisations.add(CotisationModel(
        id: (idCounter++).toString(),
        userId: '2',
        month: month,
        year: 2025,
        status: month <= 6 ? CotisationStatus.paid : CotisationStatus.unpaid,
        paidAt: month <= 6 ? DateTime(2025, month, 15) : null,
        paymentMethod: month <= 6
            ? (month % 3 == 0 ? PaymentMethod.cheque : (month % 2 == 0 ? PaymentMethod.virement : PaymentMethod.espece))
            : null,
      ));
    }

    // 2024 : Tout payé pour Jean Dupont
    for (final month in CotisationModel.cotisableMonths) {
      _cotisations.add(CotisationModel(
        id: (idCounter++).toString(),
        userId: '2',
        month: month,
        year: 2024,
        status: CotisationStatus.paid,
        paidAt: DateTime(2024, month, 10),
        paymentMethod: month <= 5 ? PaymentMethod.espece : PaymentMethod.virement,
      ));
    }

    // Cotisations pour l'adhérent en attente (userId: '3' - Marie Kamga)
    // 2025 : Janvier à Mars payés, reste impayé
    for (final month in CotisationModel.cotisableMonths) {
      _cotisations.add(CotisationModel(
        id: (idCounter++).toString(),
        userId: '3',
        month: month,
        year: 2025,
        status: month <= 3 ? CotisationStatus.paid : CotisationStatus.unpaid,
        paidAt: month <= 3 ? DateTime(2025, month, 5) : null,
        paymentMethod: month <= 3 ? PaymentMethod.espece : null,
      ));
    }
  }

  /// Récupérer les cotisations d'un adhérent pour une année
  /// Génère automatiquement les cotisations si elles n'existent pas
  Future<List<CotisationModel>> getCotisationsByUserAndYear(
    String userId,
    int year,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final existing = _cotisations
        .where((c) => c.userId == userId && c.year == year)
        .toList();

    if (existing.isEmpty) {
      await generateCotisationsForUser(userId, year);
    }

    return _cotisations
        .where((c) => c.userId == userId && c.year == year)
        .toList()
      ..sort((a, b) => a.month.compareTo(b.month));
  }

  /// Récupérer toutes les cotisations d'un adhérent
  Future<List<CotisationModel>> getCotisationsByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _cotisations.where((c) => c.userId == userId).toList()
      ..sort((a, b) {
        final yearCmp = b.year.compareTo(a.year);
        if (yearCmp != 0) return yearCmp;
        return a.month.compareTo(b.month);
      });
  }

  /// Marquer une cotisation comme payée (admin) avec mode de paiement
  Future<bool> markAsPaid(String cotisationId, PaymentMethod method) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _cotisations.indexWhere((c) => c.id == cotisationId);
    if (index == -1) return false;
    _cotisations[index] = _cotisations[index].copyWith(
      status: CotisationStatus.paid,
      paidAt: DateTime.now(),
      paymentMethod: method,
    );
    return true;
  }

  /// Marquer une cotisation comme impayée (admin)
  Future<bool> markAsUnpaid(String cotisationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _cotisations.indexWhere((c) => c.id == cotisationId);
    if (index == -1) return false;
    _cotisations[index] = _cotisations[index].copyWith(
      status: CotisationStatus.unpaid,
      clearPaymentMethod: true,
    );
    return true;
  }

  /// Marquer une cotisation comme exemptée (chômage)
  Future<bool> markAsExempted(String cotisationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _cotisations.indexWhere((c) => c.id == cotisationId);
    if (index == -1) return false;
    _cotisations[index] = _cotisations[index].copyWith(
      status: CotisationStatus.exempted,
      clearPaymentMethod: true,
    );
    return true;
  }

  /// Retirer l'exemption chômage (remettre en impayé)
  Future<bool> removeExemption(String cotisationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _cotisations.indexWhere((c) => c.id == cotisationId);
    if (index == -1) return false;
    _cotisations[index] = _cotisations[index].copyWith(
      status: CotisationStatus.unpaid,
      clearPaymentMethod: true,
    );
    return true;
  }

  /// Générer les cotisations pour un nouvel adhérent pour l'année en cours
  Future<void> generateCotisationsForUser(String userId, int year) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final existing = _cotisations
        .where((c) => c.userId == userId && c.year == year)
        .toList();

    if (existing.isNotEmpty) return;

    int idCounter = DateTime.now().millisecondsSinceEpoch;
    for (final month in CotisationModel.cotisableMonths) {
      _cotisations.add(CotisationModel(
        id: (idCounter++).toString(),
        userId: userId,
        month: month,
        year: year,
      ));
    }
  }

  /// Résumé des cotisations d'un adhérent pour une année
  /// Les mois exemptés (chômage) sont exclus du total dû
  Future<Map<String, dynamic>> getUserYearlySummary(
    String userId,
    int year,
  ) async {
    final cotisations = await getCotisationsByUserAndYear(userId, year);
    final paid = cotisations.where((c) => c.isPaid).length;
    final exempted = cotisations.where((c) => c.isExempted).length;
    final unpaid = cotisations.where((c) => c.status == CotisationStatus.unpaid).length;
    final totalPaid = paid * CotisationModel.monthlyAmount;
    final totalDue = (CotisationModel.cotisableMonths.length - exempted) * CotisationModel.monthlyAmount;

    return {
      'paid': paid,
      'unpaid': unpaid,
      'exempted': exempted,
      'totalPaid': totalPaid,
      'totalDue': totalDue,
      'remaining': totalDue - totalPaid,
      'percentage': totalDue > 0 ? (totalPaid / totalDue) : 0.0,
    };
  }

  /// Résumé des paiements par mode pour une année donnée
  Future<Map<String, dynamic>> getPaymentSummaryByYear(int year) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final paidCotisations = _cotisations
        .where((c) => c.year == year && c.isPaid)
        .toList();

    return _computePaymentBreakdown(paidCotisations);
  }

  /// Résumé des paiements par mode pour une période donnée (mois spécifiques d'une année)
  Future<Map<String, dynamic>> getPaymentSummaryForPeriod(
    int year,
    List<int> months,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final paidCotisations = _cotisations
        .where((c) => c.year == year && c.isPaid && months.contains(c.month))
        .toList();

    return _computePaymentBreakdown(paidCotisations);
  }

  Map<String, dynamic> _computePaymentBreakdown(List<CotisationModel> paidCotisations) {
    double totalEspece = 0;
    double totalVirement = 0;
    double totalCheque = 0;
    int countEspece = 0;
    int countVirement = 0;
    int countCheque = 0;

    for (final c in paidCotisations) {
      switch (c.paymentMethod) {
        case PaymentMethod.espece:
          totalEspece += c.amount;
          countEspece++;
          break;
        case PaymentMethod.virement:
          totalVirement += c.amount;
          countVirement++;
          break;
        case PaymentMethod.cheque:
          totalCheque += c.amount;
          countCheque++;
          break;
        case null:
          break;
      }
    }

    final totalPaid = totalEspece + totalVirement + totalCheque;

    return {
      'totalPaid': totalPaid,
      'totalEspece': totalEspece,
      'totalVirement': totalVirement,
      'totalCheque': totalCheque,
      'countEspece': countEspece,
      'countVirement': countVirement,
      'countCheque': countCheque,
      'countTotal': paidCotisations.length,
    };
  }

  /// Résumé des paiements effectués entre deux dates (basé sur paidAt)
  /// Capture les paiements anticipés : un adhérent qui paie en février pour mars/avril
  Future<Map<String, dynamic>> getPaymentSummaryByDateRange(
    DateTime from,
    DateTime to,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final paidCotisations = _cotisations
        .where((c) =>
            c.isPaid &&
            c.paidAt != null &&
            !c.paidAt!.isBefore(from) &&
            c.paidAt!.isBefore(to.add(const Duration(days: 1))))
        .toList();

    return _computePaymentBreakdown(paidCotisations);
  }

  /// Résumé global pour l'admin (tous les adhérents, année donnée)
  Future<List<Map<String, dynamic>>> getAllMembersSummary(int year) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final userIds = _cotisations.map((c) => c.userId).toSet();
    final summaries = <Map<String, dynamic>>[];

    for (final userId in userIds) {
      final summary = await getUserYearlySummary(userId, year);
      summary['userId'] = userId;
      summaries.add(summary);
    }

    return summaries;
  }
}
