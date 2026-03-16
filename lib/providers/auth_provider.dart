import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/supabase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseAuthService _authService = SupabaseAuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isApproved => _currentUser?.status == AccountStatus.approved;

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final user = await _authService.login(phone, password);

    _isLoading = false;
    if (user == null) {
      _errorMessage = 'Numéro de téléphone ou mot de passe incorrect';
      notifyListeners();
      return false;
    }

    _currentUser = user;
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final user = await _authService.register(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      username: username,
      password: password,
    );

    _isLoading = false;
    if (user == null) {
      _errorMessage = 'Ce nom d\'utilisateur est déjà utilisé';
      notifyListeners();
      return false;
    }

    _currentUser = user;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<List<UserModel>> getPendingUsers() => _authService.getPendingUsers();
  Future<List<UserModel>> getAllMembers() => _authService.getAllMembers();

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

  /// Restaurer la session existante au démarrage
  Future<void> restoreSession() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      notifyListeners();
    }
  }
}
