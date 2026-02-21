import 'package:flutter/foundation.dart';
import '../models/compte_rendu_model.dart';
import '../services/supabase_compte_rendu_service.dart';

class CompteRenduProvider extends ChangeNotifier {
  final SupabaseCompteRenduService _service = SupabaseCompteRenduService();

  List<CompteRenduModel> _comptesRendus = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CompteRenduModel> get comptesRendus => _comptesRendus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadComptesRendus() async {
    _isLoading = true;
    notifyListeners();

    _comptesRendus = await _service.getAllComptesRendus();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createCompteRendu({
    required String title,
    required ReunionType type,
    required DateTime reunionDate,
    required String authorId,
    required String authorName,
    required List<String> points,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.createCompteRendu(
        title: title,
        type: type,
        reunionDate: reunionDate,
        authorId: authorId,
        authorName: authorName,
        points: points,
        notes: notes,
      );
      await loadComptesRendus();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la création du compte rendu';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCompteRendu(CompteRenduModel updated) async {
    _isLoading = true;
    notifyListeners();

    final success = await _service.updateCompteRendu(updated);
    await loadComptesRendus();
    return success;
  }

  Future<bool> deleteCompteRendu(String id) async {
    final success = await _service.deleteCompteRendu(id);
    await loadComptesRendus();
    return success;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
