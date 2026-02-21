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

  /// Récupérer tous les membres (admins inclus, car ils cotisent aussi)
  Future<List<UserModel>> getAllMembers() async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('status', 'approved')
        .order('last_name', ascending: true);
    return data.map<UserModel>((json) => UserModel.fromJson(json)).toList();
  }

  /// Helper: récupérer l'admin courant (id + nom)
  Future<Map<String, String>> _getCurrentAdmin() async {
    final user = _client.auth.currentUser;
    if (user == null) return {'id': '', 'name': ''};
    final profile = await _client
        .from('profiles')
        .select('id, first_name, last_name')
        .eq('id', user.id)
        .single();
    final name = '${profile['first_name']} ${profile['last_name']}';
    return {'id': user.id, 'name': name};
  }

  /// Helper: enregistrer une action dans audit_log
  Future<void> _logAction({
    required String adminId,
    required String adminName,
    required String action,
    required String targetTable,
    String? targetId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _client.from('audit_log').insert({
        'admin_id': adminId,
        'admin_name': adminName,
        'action': action,
        'target_table': targetTable,
        'target_id': targetId,
        'details': details,
      });
    } catch (_) {}
  }

  /// Approuver un utilisateur
  Future<bool> approveUser(String userId) async {
    try {
      final admin = await _getCurrentAdmin();
      await _client
          .from('profiles')
          .update({'status': 'approved'})
          .eq('id', userId);
      await _logAction(
        adminId: admin['id']!,
        adminName: admin['name']!,
        action: 'approve_user',
        targetTable: 'profiles',
        targetId: userId,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Rejeter un utilisateur
  Future<bool> rejectUser(String userId) async {
    try {
      final admin = await _getCurrentAdmin();
      await _client
          .from('profiles')
          .update({'status': 'rejected'})
          .eq('id', userId);
      await _logAction(
        adminId: admin['id']!,
        adminName: admin['name']!,
        action: 'reject_user',
        targetTable: 'profiles',
        targetId: userId,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mettre à jour le rôle d'un utilisateur (admin/member)
  Future<bool> updateUserRole(String userId, String role) async {
    try {
      final admin = await _getCurrentAdmin();
      await _client
          .from('profiles')
          .update({'role': role})
          .eq('id', userId);
      await _logAction(
        adminId: admin['id']!,
        adminName: admin['name']!,
        action: 'update_role',
        targetTable: 'profiles',
        targetId: userId,
        details: {'new_role': role},
      );
      return true;
    } catch (e) {
      debugPrint('updateUserRole error: $e');
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
