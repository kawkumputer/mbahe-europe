import 'package:flutter/foundation.dart';
import '../models/depense_model.dart';
import '../services/supabase_depense_service.dart';

class DepenseProvider extends ChangeNotifier {
  final SupabaseDepenseService _service = SupabaseDepenseService();

  List<DepenseModel> _depenses = [];
  List<DepenseModel> _pendingDepenses = [];
  bool _isLoading = false;
  double _totalApproved = 0.0;
  String _associationType = 'general';

  List<DepenseModel> get depenses => _depenses;
  List<DepenseModel> get pendingDepenses => _pendingDepenses;
  bool get isLoading => _isLoading;
  double get totalApproved => _totalApproved;
  int get pendingCount => _pendingDepenses.length;
  String get associationType => _associationType;

  void setAssociationType(String type) {
    _associationType = type;
    notifyListeners();
  }

  /// Charger toutes les dépenses (admin voit tout, membres voient validées)
  Future<void> loadDepenses({String? associationType}) async {
    _isLoading = true;
    notifyListeners();

    final type = associationType ?? _associationType;
    _depenses = await _service.getAllDepenses(associationType: type);
    _totalApproved = await _service.getTotalApprovedDepenses(associationType: type);

    _isLoading = false;
    notifyListeners();
  }

  /// Charger les dépenses en attente de validation
  Future<void> loadPendingDepenses({String? associationType}) async {
    final type = associationType ?? _associationType;
    _pendingDepenses = await _service.getPendingDepenses(associationType: type);
    notifyListeners();
  }

  /// Créer une nouvelle dépense
  Future<bool> createDepense({
    required double amount,
    required String motif,
    String? description,
    required DateTime depenseDate,
    String? associationType,
  }) async {
    final type = associationType ?? _associationType;
    final depense = await _service.createDepense(
      amount: amount,
      motif: motif,
      description: description,
      depenseDate: depenseDate,
      associationType: type,
    );
    if (depense != null) {
      _depenses.insert(0, depense);
      _pendingDepenses.insert(0, depense);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Valider une dépense
  Future<bool> approveDepense(String depenseId) async {
    final success = await _service.approveDepense(depenseId);
    if (success) {
      // Mettre à jour localement
      final index = _depenses.indexWhere((d) => d.id == depenseId);
      if (index != -1) {
        // Recharger depuis la base pour avoir les infos du validateur
        await loadDepenses();
        await loadPendingDepenses();
      }
      return true;
    }
    return false;
  }

  /// Rejeter une dépense
  Future<bool> rejectDepense(String depenseId, String reason) async {
    final success = await _service.rejectDepense(depenseId, reason);
    if (success) {
      await loadDepenses();
      await loadPendingDepenses();
      return true;
    }
    return false;
  }

  /// Supprimer une dépense (seulement si pending)
  Future<bool> deleteDepense(String depenseId) async {
    final success = await _service.deleteDepense(depenseId);
    if (success) {
      _depenses.removeWhere((d) => d.id == depenseId);
      _pendingDepenses.removeWhere((d) => d.id == depenseId);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Total des dépenses validées
  Future<double> getTotalApprovedDepenses({String? associationType}) async {
    final type = associationType ?? _associationType;
    return await _service.getTotalApprovedDepenses(associationType: type);
  }
}
