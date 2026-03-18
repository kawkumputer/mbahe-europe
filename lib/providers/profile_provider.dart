import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/supabase_profile_service.dart';

class ProfileProvider with ChangeNotifier {
  final SupabaseProfileService _profileService = SupabaseProfileService();

  UserModel? _currentProfile;
  Map<String, int> _stats = {};
  bool _isLoading = false;
  String? _error;

  UserModel? get currentProfile => _currentProfile;
  Map<String, int> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setCurrentProfile(UserModel? profile) {
    _currentProfile = profile;
    notifyListeners();
  }

  Future<void> loadUserData(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await loadStats(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStats(String userId) async {
    try {
      _stats = await _profileService.getUserStats(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('loadStats error: $e');
    }
  }

  Future<bool> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
    DateTime? dateOfBirth,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedProfile = await _profileService.updateProfile(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        bio: bio,
        dateOfBirth: dateOfBirth,
      );

      if (updatedProfile != null) {
        _currentProfile = updatedProfile;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erreur lors de la mise à jour du profil';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadProfilePhoto({
    required String userId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final photoUrl = await _profileService.uploadProfilePhoto(
        userId: userId,
        imageBytes: imageBytes,
        fileName: fileName,
      );

      if (photoUrl != null) {
        _currentProfile = _currentProfile?.copyWith(photoUrl: photoUrl);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erreur lors de l\'upload de la photo';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProfilePhoto(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _profileService.deleteProfilePhoto(userId);

      if (success) {
        _currentProfile = _currentProfile?.copyWith(photoUrl: null);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erreur lors de la suppression de la photo';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _currentProfile = null;
    _stats = {};
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
