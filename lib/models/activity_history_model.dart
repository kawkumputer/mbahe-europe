enum ActivityType {
  login,
  profileUpdate,
  cotisationPaid,
  roleChanged,
  statusChanged,
  accountCreated,
}

class ActivityHistoryModel {
  final String id;
  final String userId;
  final ActivityType actionType;
  final String description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  ActivityHistoryModel({
    required this.id,
    required this.userId,
    required this.actionType,
    required this.description,
    this.metadata,
    required this.createdAt,
  });

  factory ActivityHistoryModel.fromJson(Map<String, dynamic> json) {
    return ActivityHistoryModel(
      id: json['id'],
      userId: json['user_id'],
      actionType: _parseActionType(json['action_type']),
      description: json['description'] ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action_type': _actionTypeToString(actionType),
      'description': description,
      'metadata': metadata,
    };
  }

  static ActivityType _parseActionType(String? type) {
    switch (type) {
      case 'login':
        return ActivityType.login;
      case 'profile_update':
        return ActivityType.profileUpdate;
      case 'cotisation_paid':
        return ActivityType.cotisationPaid;
      case 'role_changed':
        return ActivityType.roleChanged;
      case 'status_changed':
        return ActivityType.statusChanged;
      case 'account_created':
        return ActivityType.accountCreated;
      default:
        return ActivityType.login;
    }
  }

  static String _actionTypeToString(ActivityType type) {
    switch (type) {
      case ActivityType.login:
        return 'login';
      case ActivityType.profileUpdate:
        return 'profile_update';
      case ActivityType.cotisationPaid:
        return 'cotisation_paid';
      case ActivityType.roleChanged:
        return 'role_changed';
      case ActivityType.statusChanged:
        return 'status_changed';
      case ActivityType.accountCreated:
        return 'account_created';
    }
  }

  String get icon {
    switch (actionType) {
      case ActivityType.login:
        return '🔐';
      case ActivityType.profileUpdate:
        return '✏️';
      case ActivityType.cotisationPaid:
        return '💰';
      case ActivityType.roleChanged:
        return '👤';
      case ActivityType.statusChanged:
        return '✅';
      case ActivityType.accountCreated:
        return '🎉';
    }
  }
}
