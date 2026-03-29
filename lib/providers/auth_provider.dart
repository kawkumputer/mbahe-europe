import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/supabase_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseAuthService _authService = SupabaseAuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String _currentAssociationType = 'general';

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isSysAdmin => _currentUser?.role == UserRole.sysAdmin;
  bool get isAdminOrSysAdmin => isAdmin || isSysAdmin;
  bool get isApproved => _currentUser?.status == AccountStatus.approved;
  
  // Rôle pour l'association active
  UserRole get currentAssociationRole => _currentUser?.getRoleForAssociation(_currentAssociationType) ?? UserRole.member;
  bool get isAdminForCurrentAssociation => _currentUser?.isAdminForAssociation(_currentAssociationType) ?? false;
  bool get isSysAdminForCurrentAssociation => currentAssociationRole == UserRole.sysAdmin;
  
  String get currentAssociationType => _currentAssociationType;
  List<String> get userAssociationTypes => _currentUser?.associationTypes ?? ['general'];
  bool get hasMultipleAssociations => userAssociationTypes.length > 1;
  
  String get associationLabel {
    return _currentAssociationType == 'general' ? 'MBAHE Europe' : 'MBAHE Jeunes';
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final user = await _authService.login(phone, password);

    _isLoading = false;
    if (user == null) {
      _errorMessage = 'Nom d\'utilisateur ou mot de passe incorrect';
      notifyListeners();
      return false;
    }

    _currentUser = user;
    await _loadActiveAssociation();
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String username,
    required String password,
    String associationType = 'general',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        username: username,
        password: password,
        associationType: associationType,
      );

      _isLoading = false;
      if (user == null) {
        _errorMessage = 'Erreur lors de l\'inscription';
        notifyListeners();
        return false;
      }

      _currentUser = user;
      await _loadActiveAssociation();
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      
      // Déterminer le message d'erreur approprié
      if (e.toString().contains('PHONE_EXISTS')) {
        _errorMessage = 'Ce numéro de téléphone est déjà utilisé';
      } else if (e.toString().contains('User already registered')) {
        _errorMessage = 'Ce nom d\'utilisateur est déjà utilisé';
      } else {
        _errorMessage = 'Erreur lors de l\'inscription';
      }
      
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _errorMessage = null;
    _currentAssociationType = 'general';
    await _clearActiveAssociation();
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      await _loadActiveAssociation();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<List<UserModel>> getPendingUsers({String? associationType}) async {
    final type = associationType ?? _currentAssociationType;
    return await _authService.getPendingUsers(associationType: type);
  }

  Future<List<UserModel>> getAllMembers({String? associationType}) async {
    final type = associationType ?? _currentAssociationType;
    return await _authService.getAllMembers(associationType: type);
  }

  Future<void> approveUser(String userId) async {
    await _authService.approveUser(userId);
    notifyListeners();
  }

  Future<void> rejectUser(String userId) async {
    await _authService.rejectUser(userId);
    notifyListeners();
  }

  Future<bool> updateUserRole(String userId, String role) async {
    final success = await _authService.updateUserRole(userId, role);
    if (success) notifyListeners();
    return success;
  }

  Future<bool> markAdhesionPaid(String userId) async {
    final success = await _authService.markAdhesionPaid(userId);
    if (success) notifyListeners();
    return success;
  }

  Future<bool> markAdhesionUnpaid(String userId) async {
    final success = await _authService.markAdhesionUnpaid(userId);
    if (success) notifyListeners();
    return success;
  }

  Future<double> getTotalAdhesionPaid() async {
    return await _authService.getTotalAdhesionPaid();
  }

  /// Restaurer la session existante au démarrage
  Future<void> restoreSession() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      await _loadActiveAssociation();
      notifyListeners();
    }
  }

  /// Charger l'association active depuis SharedPreferences
  Future<void> _loadActiveAssociation() async {
    if (_currentUser == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final savedAssociation = prefs.getString('active_association_${_currentUser!.id}');
    
    if (savedAssociation != null && _currentUser!.associationTypes.contains(savedAssociation)) {
      _currentAssociationType = savedAssociation;
    } else {
      _currentAssociationType = _currentUser!.associationTypes.first;
    }
  }

  /// Sauvegarder l'association active dans SharedPreferences
  Future<void> _saveActiveAssociation() async {
    if (_currentUser == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_association_${_currentUser!.id}', _currentAssociationType);
  }

  /// Effacer l'association active
  Future<void> _clearActiveAssociation() async {
    if (_currentUser == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_association_${_currentUser!.id}');
  }

  /// Changer l'association active
  Future<void> switchAssociation(String associationType) async {
    if (_currentUser == null) return;
    
    if (!_currentUser!.associationTypes.contains(associationType)) {
      throw Exception('L\'utilisateur n\'appartient pas à cette association');
    }
    
    _currentAssociationType = associationType;
    await _saveActiveAssociation();
    notifyListeners();
  }

  /// Définir l'association active (utilisé après sélection)
  Future<void> setActiveAssociation(String associationType) async {
    await switchAssociation(associationType);
  }

  /// Changer le mot de passe de l'utilisateur connecté
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final success = await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    _isLoading = false;
    if (!success) {
      _errorMessage = 'Mot de passe actuel incorrect';
    }
    notifyListeners();
    return success;
  }

  /// Réinitialiser le mot de passe d'un utilisateur (admin uniquement)
  Future<bool> resetUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    final success = await _authService.resetUserPassword(
      userId: userId,
      newPassword: newPassword,
    );
    if (success) notifyListeners();
    return success;
  }
}
