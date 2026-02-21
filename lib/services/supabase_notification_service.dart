import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class SupabaseNotificationService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Récupérer les notifications de l'utilisateur courant
  Future<List<NotificationModel>> getMyNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('notifications')
        .select()
        .eq('recipient_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);

    return data
        .map<NotificationModel>((json) => NotificationModel.fromJson(json))
        .toList();
  }

  /// Nombre de notifications non lues
  Future<int> getUnreadCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    final data = await _client
        .from('notifications')
        .select('id')
        .eq('recipient_id', user.id)
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
  Future<void> markAllAsRead() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_id', user.id)
        .eq('is_read', false);
  }

  /// Envoyer une notification à tous les admins
  Future<void> notifyAllAdmins({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    String? excludeAdminId,
  }) async {
    final admins = await _client
        .from('profiles')
        .select('id')
        .eq('role', 'admin')
        .eq('status', 'approved');

    final notifications = <Map<String, dynamic>>[];
    for (final admin in admins) {
      final adminId = admin['id'] as String;
      if (adminId == excludeAdminId) continue;
      notifications.add({
        'recipient_id': adminId,
        'title': title,
        'body': body,
        'type': NotificationModel.typeToString(type),
        'data': data,
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
  }) async {
    final users = await _client
        .from('profiles')
        .select('id')
        .eq('status', 'approved');

    final notifications = <Map<String, dynamic>>[];
    for (final user in users) {
      final userId = user['id'] as String;
      if (userId == excludeUserId) continue;
      notifications.add({
        'recipient_id': userId,
        'title': title,
        'body': body,
        'type': NotificationModel.typeToString(type),
        'data': data,
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
  }) async {
    await _client.from('notifications').insert({
      'recipient_id': recipientId,
      'title': title,
      'body': body,
      'type': NotificationModel.typeToString(type),
      'data': data,
    });
  }
}
