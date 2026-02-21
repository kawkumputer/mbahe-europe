import 'package:flutter/foundation.dart';
import '../models/mandat_model.dart';
import '../models/bureau_membre_model.dart';
import '../services/supabase_bureau_service.dart';

class BureauProvider extends ChangeNotifier {
  final SupabaseBureauService _service = SupabaseBureauService();

  List<MandatModel> _mandats = [];
  MandatModel? _activeMandat;
  List<BureauMembreModel> _bureauMembres = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MandatModel> get mandats => _mandats;
  MandatModel? get activeMandat => _activeMandat;
  List<BureauMembreModel> get bureauMembres => _bureauMembres;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMandats() async {
    _isLoading = true;
    notifyListeners();

    try {
      _mandats = await _service.getAllMandats();
      _activeMandat = _mandats.where((m) => m.isActive).firstOrNull;
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des mandats';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadBureauMembres(String mandatId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _bureauMembres = await _service.getBureauMembres(mandatId);
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement du bureau';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createMandat({
    required String label,
    required DateTime startDate,
    required DateTime endDate,
    bool isActive = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.createMandat(
        label: label,
        startDate: startDate,
        endDate: endDate,
        isActive: isActive,
      );
      await loadMandats();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la création du mandat';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> activateMandat(String mandatId) async {
    final success = await _service.activateMandat(mandatId);
    if (success) await loadMandats();
    return success;
  }

  Future<bool> deleteMandat(String mandatId) async {
    final success = await _service.deleteMandat(mandatId);
    if (success) await loadMandats();
    return success;
  }

  Future<bool> addBureauMembre({
    required String mandatId,
    required String userId,
    required String userName,
    required String poste,
  }) async {
    try {
      await _service.addBureauMembre(
        mandatId: mandatId,
        userId: userId,
        userName: userName,
        poste: poste,
      );
      await loadBureauMembres(mandatId);
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ajout du membre';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBureauMembre(String id, {
    required String mandatId,
    required String userId,
    required String userName,
    required String poste,
  }) async {
    final success = await _service.updateBureauMembre(
      id,
      userId: userId,
      userName: userName,
      poste: poste,
    );
    if (success) await loadBureauMembres(mandatId);
    return success;
  }

  Future<bool> removeBureauMembre(String id, String mandatId) async {
    final success = await _service.removeBureauMembre(id);
    if (success) await loadBureauMembres(mandatId);
    return success;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
