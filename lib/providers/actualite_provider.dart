import 'package:flutter/foundation.dart';
import '../models/actualite_model.dart';
import '../services/supabase_actualite_service.dart';

class ActualiteProvider extends ChangeNotifier {
  final SupabaseActualiteService _service = SupabaseActualiteService();

  List<ActualiteModel> _actualites = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ActualiteModel> get actualites => _actualites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadActualites() async {
    _isLoading = true;
    notifyListeners();

    try {
      _actualites = await _service.getAllActualites();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des actualités';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createActualite({
    required String title,
    required String content,
    required ActualiteCategory category,
    required String authorId,
    required String authorName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.createActualite(
        title: title,
        content: content,
        category: category,
        authorId: authorId,
        authorName: authorName,
      );
      await loadActualites();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la création';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateActualite(String id, {
    required String title,
    required String content,
    required ActualiteCategory category,
  }) async {
    _isLoading = true;
    notifyListeners();

    final success = await _service.updateActualite(
      id,
      title: title,
      content: content,
      category: category,
    );
    await loadActualites();
    return success;
  }

  Future<bool> deleteActualite(String id) async {
    final success = await _service.deleteActualite(id);
    await loadActualites();
    return success;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
