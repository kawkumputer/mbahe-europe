enum ReunionType { assembleeGenerale, bureau, extraordinaire }

class CompteRenduModel {
  final String id;
  final String title;
  final ReunionType type;
  final DateTime reunionDate;
  final String authorId;
  final String authorName;
  final List<String> points;
  final String? notes;
  final DateTime createdAt;

  CompteRenduModel({
    required this.id,
    required this.title,
    required this.type,
    required this.reunionDate,
    required this.authorId,
    required this.authorName,
    required this.points,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CompteRenduModel.fromJson(Map<String, dynamic> json) {
    return CompteRenduModel(
      id: json['id'],
      title: json['title'],
      type: _parseType(json['type']),
      reunionDate: DateTime.parse(json['reunion_date']),
      authorId: json['author_id'],
      authorName: json['author_name'] ?? '',
      points: (json['points'] as List<dynamic>?)?.cast<String>() ?? [],
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type.name,
      'reunion_date': '${reunionDate.year}-${reunionDate.month.toString().padLeft(2, '0')}-${reunionDate.day.toString().padLeft(2, '0')}',
      'author_id': authorId,
      'author_name': authorName,
      'points': points,
      'notes': notes,
    };
  }

  static ReunionType _parseType(String? type) {
    switch (type) {
      case 'assembleeGenerale':
        return ReunionType.assembleeGenerale;
      case 'bureau':
        return ReunionType.bureau;
      case 'extraordinaire':
        return ReunionType.extraordinaire;
      default:
        return ReunionType.assembleeGenerale;
    }
  }

  CompteRenduModel copyWith({
    String? id,
    String? title,
    ReunionType? type,
    DateTime? reunionDate,
    String? authorId,
    String? authorName,
    List<String>? points,
    String? notes,
    DateTime? createdAt,
  }) {
    return CompteRenduModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      reunionDate: reunionDate ?? this.reunionDate,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      points: points ?? this.points,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get typeLabel {
    switch (type) {
      case ReunionType.assembleeGenerale:
        return 'Assemblée Générale';
      case ReunionType.bureau:
        return 'Réunion de Bureau';
      case ReunionType.extraordinaire:
        return 'Réunion Extraordinaire';
    }
  }

  String get formattedDate {
    const months = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    return '${reunionDate.day} ${months[reunionDate.month]} ${reunionDate.year}';
  }
}
