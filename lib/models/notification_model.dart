enum NotificationType { info, cotisation, member, compteRendu, role, actualite }

class NotificationModel {
  final String id;
  final String recipientId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.body,
    this.type = NotificationType.info,
    this.isRead = false,
    this.data,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      recipientId: json['recipient_id'],
      title: json['title'],
      body: json['body'],
      type: _parseType(json['type']),
      isRead: json['is_read'] ?? false,
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'cotisation':
        return NotificationType.cotisation;
      case 'member':
        return NotificationType.member;
      case 'compte_rendu':
        return NotificationType.compteRendu;
      case 'role':
        return NotificationType.role;
      case 'actualite':
        return NotificationType.actualite;
      default:
        return NotificationType.info;
    }
  }

  static String typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.cotisation:
        return 'cotisation';
      case NotificationType.member:
        return 'member';
      case NotificationType.compteRendu:
        return 'compte_rendu';
      case NotificationType.role:
        return 'role';
      case NotificationType.info:
        return 'info';
      case NotificationType.actualite:
        return 'actualite';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
