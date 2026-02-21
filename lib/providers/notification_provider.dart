import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../services/supabase_notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final SupabaseNotificationService _service = SupabaseNotificationService();
  final SupabaseClient _client = Supabase.instance.client;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  RealtimeChannel? _channel;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  /// Démarrer l'écoute Realtime des nouvelles notifications
  void startListening() {
    final user = _client.auth.currentUser;
    if (user == null) return;

    _channel?.unsubscribe();
    _channel = _client
        .channel('notifications:${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: user.id,
          ),
          callback: (payload) {
            final newNotif = NotificationModel.fromJson(payload.newRecord);
            _notifications.insert(0, newNotif);
            _unreadCount++;
            notifyListeners();
          },
        )
        .subscribe();
  }

  /// Arrêter l'écoute Realtime
  void stopListening() {
    _channel?.unsubscribe();
    _channel = null;
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    _notifications = await _service.getMyNotifications();
    _unreadCount = _notifications.where((n) => !n.isRead).length;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshUnreadCount() async {
    _unreadCount = await _service.getUnreadCount();
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = NotificationModel(
        id: _notifications[index].id,
        recipientId: _notifications[index].recipientId,
        title: _notifications[index].title,
        body: _notifications[index].body,
        type: _notifications[index].type,
        isRead: true,
        data: _notifications[index].data,
        createdAt: _notifications[index].createdAt,
      );
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    await _service.markAllAsRead();
    _notifications = _notifications.map((n) => NotificationModel(
      id: n.id,
      recipientId: n.recipientId,
      title: n.title,
      body: n.body,
      type: n.type,
      isRead: true,
      data: n.data,
      createdAt: n.createdAt,
    )).toList();
    _unreadCount = 0;
    notifyListeners();
  }
}
