class UserActiveAssociationModel {
  final String userId;
  final String activeAssociationType;
  final DateTime updatedAt;

  UserActiveAssociationModel({
    required this.userId,
    required this.activeAssociationType,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory UserActiveAssociationModel.fromJson(Map<String, dynamic> json) {
    return UserActiveAssociationModel(
      userId: json['user_id'],
      activeAssociationType: json['active_association_type'] ?? 'general',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'active_association_type': activeAssociationType,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserActiveAssociationModel copyWith({
    String? userId,
    String? activeAssociationType,
    DateTime? updatedAt,
  }) {
    return UserActiveAssociationModel(
      userId: userId ?? this.userId,
      activeAssociationType: activeAssociationType ?? this.activeAssociationType,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
