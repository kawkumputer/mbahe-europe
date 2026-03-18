import 'package:flutter/foundation.dart';
import '../models/cotisation_model.dart';
import '../services/supabase_cotisation_service.dart';

class CotisationProvider extends ChangeNotifier {
  final SupabaseCotisationService _service = SupabaseCotisationService();

  List<CotisationModel> _cotisations = [];
  Map<String, dynamic> _summary = {};
  Map<String, dynamic> _paymentSummary = {};
  bool _isLoading = false;
  int _selectedYear = DateTime.now().year;

  List<CotisationModel> get cotisations => _cotisations;
  Map<String, dynamic> get summary => _summary;
  Map<String, dynamic> get paymentSummary => _paymentSummary;
  bool get isLoading => _isLoading;
  int get selectedYear => _selectedYear;

  int get paidCount => _summary['paid'] ?? 0;
  int get unpaidCount => _summary['unpaid'] ?? 0;
  int get exemptedCount => _summary['exempted'] ?? 0;
  double get totalPaid => (_summary['totalPaid'] ?? 0.0).toDouble();
  double get totalDue => (_summary['totalDue'] ?? 0.0).toDouble();
  double get remaining => (_summary['remaining'] ?? 0.0).toDouble();
  double get percentage => (_summary['percentage'] ?? 0.0).toDouble();

  void setYear(int year) {
    _selectedYear = year;
    notifyListeners();
  }

  Future<void> loadCotisations(String userId) async {
    _isLoading = true;
    notifyListeners();

    _cotisations = await _service.getCotisationsByUserAndYear(
      userId,
      _selectedYear,
    );
    _summary = await _service.getUserYearlySummary(userId, _selectedYear);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsPaid(String cotisationId, String userId, PaymentMethod method) async {
    await _service.markAsPaid(cotisationId, method);
    
    // Mise à jour locale optimisée
    final index = _cotisations.indexWhere((c) => c.id == cotisationId);
    if (index != -1) {
      _cotisations[index] = _cotisations[index].copyWith(
        status: CotisationStatus.paid,
        paymentMethod: method,
        paidAt: DateTime.now(),
      );
      _updateSummaryAfterChange();
      notifyListeners();
    }
  }

  Future<void> markAsPaidWithDate(String cotisationId, String userId, PaymentMethod method, DateTime paymentDate) async {
    await _service.markAsPaidWithDate(cotisationId, method, paymentDate);
    
    // Mise à jour locale optimisée
    final index = _cotisations.indexWhere((c) => c.id == cotisationId);
    if (index != -1) {
      _cotisations[index] = _cotisations[index].copyWith(
        status: CotisationStatus.paid,
        paymentMethod: method,
        paidAt: paymentDate,
      );
      _updateSummaryAfterChange();
      notifyListeners();
    }
  }

  Future<void> markAsUnpaid(String cotisationId, String userId) async {
    await _service.markAsUnpaid(cotisationId);
    
    // Mise à jour locale optimisée
    final index = _cotisations.indexWhere((c) => c.id == cotisationId);
    if (index != -1) {
      _cotisations[index] = _cotisations[index].copyWith(
        status: CotisationStatus.unpaid,
        paymentMethod: null,
        paidAt: null,
      );
      _updateSummaryAfterChange();
      notifyListeners();
    }
  }

  Future<void> markAsExempted(String cotisationId, String userId) async {
    await _service.markAsExempted(cotisationId);
    
    // Mise à jour locale optimisée
    final index = _cotisations.indexWhere((c) => c.id == cotisationId);
    if (index != -1) {
      _cotisations[index] = _cotisations[index].copyWith(
        status: CotisationStatus.exempted,
      );
      _updateSummaryAfterChange();
      notifyListeners();
    }
  }

  Future<void> removeExemption(String cotisationId, String userId) async {
    await _service.removeExemption(cotisationId);
    
    // Mise à jour locale optimisée
    final index = _cotisations.indexWhere((c) => c.id == cotisationId);
    if (index != -1) {
      _cotisations[index] = _cotisations[index].copyWith(
        status: CotisationStatus.unpaid,
      );
      _updateSummaryAfterChange();
      notifyListeners();
    }
  }

  Future<void> generateCotisations(String userId, int year) async {
    await _service.generateCotisationsForUser(userId, year);
    await loadCotisations(userId);
  }

  Future<void> loadPaymentSummary(int year) async {
    _isLoading = true;
    notifyListeners();

    _paymentSummary = await _service.getPaymentSummaryByYear(year);

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> getPaymentSummaryForPeriod(int year, List<int> months) async {
    return await _service.getPaymentSummaryForPeriod(year, months);
  }

  Future<Map<String, dynamic>> getPaymentSummaryByDateRange(DateTime from, DateTime to) async {
    return await _service.getPaymentSummaryByDateRange(from, to);
  }

  /// Récupérer le montant total des années précédentes (2022-2024)
  /// Somme de tous les paiements effectués avant 2025
  Future<double> getPreviousYearsTotalAmount() async {
    return await _service.getPreviousYearsTotalAmount();
  }

  double get paymentTotalPaid => (_paymentSummary['totalPaid'] ?? 0.0).toDouble();
  double get paymentTotalEspece => (_paymentSummary['totalEspece'] ?? 0.0).toDouble();
  double get paymentTotalVirement => (_paymentSummary['totalVirement'] ?? 0.0).toDouble();
  double get paymentTotalCheque => (_paymentSummary['totalCheque'] ?? 0.0).toDouble();
  int get paymentCountEspece => _paymentSummary['countEspece'] ?? 0;
  int get paymentCountVirement => _paymentSummary['countVirement'] ?? 0;
  int get paymentCountCheque => _paymentSummary['countCheque'] ?? 0;
  int get paymentCountTotal => _paymentSummary['countTotal'] ?? 0;

  /// Recalculer le résumé localement après une modification
  void _updateSummaryAfterChange() {
    int paid = 0;
    int unpaid = 0;
    int exempted = 0;
    double totalPaid = 0.0;
    double totalDue = 0.0;

    for (final cotisation in _cotisations) {
      if (cotisation.status == CotisationStatus.paid) {
        paid++;
        totalPaid += cotisation.amount;
      } else if (cotisation.status == CotisationStatus.exempted) {
        exempted++;
      } else {
        unpaid++;
        totalDue += cotisation.amount;
      }
    }

    final remaining = totalDue;
    final percentage = totalDue > 0 ? (totalPaid / (totalPaid + totalDue)) * 100 : 100.0;

    _summary = {
      'paid': paid,
      'unpaid': unpaid,
      'exempted': exempted,
      'totalPaid': totalPaid,
      'totalDue': totalDue,
      'remaining': remaining,
      'percentage': percentage,
    };
  }
}
