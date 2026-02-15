import 'package:flutter/foundation.dart';
import '../models/cotisation_model.dart';
import '../services/mock_cotisation_service.dart';

class CotisationProvider extends ChangeNotifier {
  final MockCotisationService _service = MockCotisationService();

  List<CotisationModel> _cotisations = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = false;
  int _selectedYear = DateTime.now().year;

  List<CotisationModel> get cotisations => _cotisations;
  Map<String, dynamic> get summary => _summary;
  bool get isLoading => _isLoading;
  int get selectedYear => _selectedYear;

  int get paidCount => _summary['paid'] ?? 0;
  int get unpaidCount => _summary['unpaid'] ?? 0;
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

  Future<void> markAsPaid(String cotisationId, String userId) async {
    await _service.markAsPaid(cotisationId);
    await loadCotisations(userId);
  }

  Future<void> markAsUnpaid(String cotisationId, String userId) async {
    await _service.markAsUnpaid(cotisationId);
    await loadCotisations(userId);
  }

  Future<void> generateCotisations(String userId, int year) async {
    await _service.generateCotisationsForUser(userId, year);
    await loadCotisations(userId);
  }
}
