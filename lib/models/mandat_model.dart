class MandatModel {
  final String id;
  final String label;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;

  MandatModel({
    required this.id,
    required this.label,
    required this.startDate,
    required this.endDate,
    this.isActive = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MandatModel.fromJson(Map<String, dynamic> json) {
    return MandatModel(
      id: json['id'],
      label: json['label'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'start_date': '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'end_date': '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
      'is_active': isActive,
    };
  }

  String get formattedPeriod {
    return '${startDate.year} - ${endDate.year}';
  }

  String get statusLabel => isActive ? 'En cours' : 'Terminé';
}
