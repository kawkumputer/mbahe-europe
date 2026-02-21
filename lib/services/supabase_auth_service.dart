import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import 'supabase_notification_service.dart';

class SupabaseAuthService {
  final SupabaseClient _client = Supabase.instance.client;
  final SupabaseNotificationService _notifService = SupabaseNotificationService();

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

      // Notifier les admins d'une nouvelle inscription
      if (profile != null) {
        try {
          await _notifService.notifyAllAdmins(
            title: 'Nouvelle inscription',
            body: '${profile.fullName} demande à rejoindre l\'association.',
            type: NotificationType.member,
            data: {'user_id': profile.id},
          );
        } catch (_) {}
      }

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

  /// Récupérer le nom complet d'un utilisateur par son id
  Future<String> _getUserName(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select('first_name, last_name')
          .eq('id', userId)
          .single();
      return '${data['first_name']} ${data['last_name']}';
    } catch (_) {
      return 'un membre';
    }
  }

  /// Approuver un utilisateur
  Future<bool> approveUser(String userId) async {
    try {
      final admin = await _getCurrentAdmin();
      final memberName = await _getUserName(userId);
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

      // Notifier le membre approuvé
      await _notifService.notifyUser(
        recipientId: userId,
        title: 'Compte approuvé',
        body: 'Votre compte a été approuvé par ${admin['name']}. Bienvenue !',
        type: NotificationType.member,
      );
      // Notifier les autres admins
      await _notifService.notifyAllAdmins(
        title: 'Membre approuvé',
        body: '${admin['name']} a approuvé $memberName.',
        type: NotificationType.member,
        data: {'user_id': userId},
        excludeAdminId: admin['id'],
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
      final memberName = await _getUserName(userId);
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

      // Notifier les autres admins
      await _notifService.notifyAllAdmins(
        title: 'Membre rejeté',
        body: '${admin['name']} a rejeté $memberName.',
        type: NotificationType.member,
        data: {'user_id': userId},
        excludeAdminId: admin['id'],
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
      final memberName = await _getUserName(userId);
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

      // Notifier l'utilisateur concerné
      final roleLabel = role == 'admin' ? 'Admin' : 'Membre';
      await _notifService.notifyUser(
        recipientId: userId,
        title: 'Changement de rôle',
        body: 'Vous êtes maintenant $roleLabel.',
        type: NotificationType.role,
      );
      // Notifier les autres admins
      await _notifService.notifyAllAdmins(
        title: 'Changement de rôle',
        body: '${admin['name']} a promu $memberName en $roleLabel.',
        type: NotificationType.role,
        data: {'user_id': userId, 'new_role': role},
        excludeAdminId: admin['id'],
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
