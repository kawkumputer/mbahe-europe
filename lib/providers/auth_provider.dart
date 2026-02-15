import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/mock_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final MockAuthService _authService = MockAuthService();

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
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final user = await _authService.register(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      password: password,
    );

    _isLoading = false;
    if (user == null) {
      _errorMessage = 'Ce numéro de téléphone est déjà utilisé';
      notifyListeners();
      return false;
    }

    _currentUser = user;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  List<UserModel> getPendingUsers() => _authService.getPendingUsers();
  List<UserModel> getAllMembers() => _authService.getAllMembers();

  Future<void> approveUser(String userId) async {
    await _authService.approveUser(userId);
    notifyListeners();
  }

  Future<void> rejectUser(String userId) async {
    await _authService.rejectUser(userId);
    notifyListeners();
  }
}
