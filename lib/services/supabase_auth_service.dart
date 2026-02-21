import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class SupabaseAuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Connexion avec téléphone + mot de passe
  /// On utilise le téléphone comme email fictif pour Supabase Auth
  Future<UserModel?> login(String phone, String password) async {
    try {
      final email = _phoneToEmail(phone);
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) return null;

      final profile = await _getProfile(response.user!.id);
      return profile;
    } catch (e) {
      return null;
    }
  }

  /// Inscription d'un nouveau membre
  Future<UserModel?> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
  }) async {
    try {
      final email = _phoneToEmail(phone);
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
          'role': 'member',
        },
      );

      if (response.user == null) return null;

      // Le trigger handle_new_user crée le profil automatiquement
      // Attendre un peu pour que le trigger s'exécute
      await Future.delayed(const Duration(milliseconds: 500));

      final profile = await _getProfile(response.user!.id);
      return profile;
    } catch (e) {
      debugPrint('Register error: $e');
      return null;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  /// Récupérer l'utilisateur courant (session existante)
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return await _getProfile(user.id);
  }

  /// Récupérer le profil depuis la table profiles
  Future<UserModel?> _getProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return UserModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Récupérer les utilisateurs en attente d'approbation
  Future<List<UserModel>> getPendingUsers() async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('status', 'pending')
        .eq('role', 'member')
        .order('created_at', ascending: false);
    return data.map<UserModel>((json) => UserModel.fromJson(json)).toList();
  }

  /// Récupérer tous les membres
  Future<List<UserModel>> getAllMembers() async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('role', 'member')
        .order('last_name', ascending: true);
    return data.map<UserModel>((json) => UserModel.fromJson(json)).toList();
  }

  /// Approuver un utilisateur
  Future<bool> approveUser(String userId) async {
    try {
      await _client
          .from('profiles')
          .update({'status': 'approved'})
          .eq('id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Rejeter un utilisateur
  Future<bool> rejectUser(String userId) async {
    try {
      await _client
          .from('profiles')
          .update({'status': 'rejected'})
          .eq('id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Convertir un numéro de téléphone en email fictif pour Supabase Auth
  /// Ex: +33600000000 -> 33600000000@mbahe.app
  String _phoneToEmail(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return '$cleaned@mbahe.app';
  }
}
