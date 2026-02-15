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
