import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class SupabaseNotificationService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Récupérer les notifications de l'utilisateur courant
  Future<List<NotificationModel>> getMyNotifications({String associationType = 'general'}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('notifications')
        .select()
        .eq('recipient_id', user.id)
        .eq('association_type', associationType)
        .order('created_at', ascending: false)
        .limit(50);

    return data
        .map<NotificationModel>((json) => NotificationModel.fromJson(json))
        .toList();
  }

  /// Nombre de notifications non lues
  Future<int> getUnreadCount({String associationType = 'general'}) async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    final data = await _client
        .from('notifications')
        .select('id')
        .eq('recipient_id', user.id)
        .eq('association_type', associationType)
        .eq('is_read', false);

    return data.length;
  }

  /// Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  /// Marquer toutes les notifications comme lues
  Future<void> markAllAsRead({String associationType = 'general'}) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_id', user.id)
        .eq('association_type', associationType)
        .eq('is_read', false);
  }

  /// Envoyer une notification à tous les admins
  Future<void> notifyAllAdmins({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    String? excludeAdminId,
    String associationType = 'general',
  }) async {
    final admins = await _client
        .from('profiles')
        .select('id, association_roles')
        .eq('status', 'approved');

    final notifications = <Map<String, dynamic>>[];
    for (final admin in admins) {
      final adminId = admin['id'] as String;
      if (adminId == excludeAdminId) continue;
      
      // Vérifier si l'admin a un rôle admin pour cette association
      final associationRoles = admin['association_roles'] as Map<String, dynamic>?;
      final roleForAssociation = associationRoles?[associationType];
      if (roleForAssociation != 'admin' && roleForAssociation != 'sys_admin') continue;
      
      notifications.add({
        'recipient_id': adminId,
        'title': title,
        'body': body,
        'type': NotificationModel.typeToString(type),
        'data': data,
        'association_type': associationType,
      });
    }

    if (notifications.isNotEmpty) {
      await _client.from('notifications').insert(notifications);
    }
  }

  /// Envoyer une notification à tous les utilisateurs approuvés (membres + admins)
  Future<void> notifyAllApprovedUsers({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    String? excludeUserId,
    String associationType = 'general',
  }) async {
    final users = await _client
        .from('profiles')
        .select('id, association_types')
        .eq('status', 'approved');

    final notifications = <Map<String, dynamic>>[];
    for (final user in users) {
      final userId = user['id'] as String;
      if (userId == excludeUserId) continue;
      
      // Vérifier si l'utilisateur appartient à cette association
      final associationTypes = List<String>.from(user['association_types'] ?? ['general']);
      if (!associationTypes.contains(associationType)) continue;
      
      notifications.add({
        'recipient_id': userId,
        'title': title,
        'body': body,
        'type': NotificationModel.typeToString(type),
        'data': data,
        'association_type': associationType,
      });
    }

    if (notifications.isNotEmpty) {
      await _client.from('notifications').insert(notifications);
    }
  }

  /// Envoyer une notification à un utilisateur spécifique
  Future<void> notifyUser({
    required String recipientId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    String associationType = 'general',
  }) async {
    await _client.from('notifications').insert({
      'recipient_id': recipientId,
      'title': title,
      'body': body,
      'type': NotificationModel.typeToString(type),
      'data': data,
      'association_type': associationType,
    });
  }
}
