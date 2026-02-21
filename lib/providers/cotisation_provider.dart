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
    await loadCotisations(userId);
  }

  Future<void> markAsUnpaid(String cotisationId, String userId) async {
    await _service.markAsUnpaid(cotisationId);
    await loadCotisations(userId);
  }

  Future<void> markAsExempted(String cotisationId, String userId) async {
    await _service.markAsExempted(cotisationId);
    await loadCotisations(userId);
  }

  Future<void> removeExemption(String cotisationId, String userId) async {
    await _service.removeExemption(cotisationId);
    await loadCotisations(userId);
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

  double get paymentTotalPaid => (_paymentSummary['totalPaid'] ?? 0.0).toDouble();
  double get paymentTotalEspece => (_paymentSummary['totalEspece'] ?? 0.0).toDouble();
  double get paymentTotalVirement => (_paymentSummary['totalVirement'] ?? 0.0).toDouble();
  double get paymentTotalCheque => (_paymentSummary['totalCheque'] ?? 0.0).toDouble();
  int get paymentCountEspece => _paymentSummary['countEspece'] ?? 0;
  int get paymentCountVirement => _paymentSummary['countVirement'] ?? 0;
  int get paymentCountCheque => _paymentSummary['countCheque'] ?? 0;
  int get paymentCountTotal => _paymentSummary['countTotal'] ?? 0;
}
