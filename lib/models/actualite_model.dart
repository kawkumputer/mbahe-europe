enum ActualiteCategory { actualite, evenement, annonce }

class ActualiteModel {
  final String id;
  final String title;
  final String content;
  final ActualiteCategory category;
  final String authorId;
  final String authorName;
  final DateTime publishedAt;
  final DateTime createdAt;

  ActualiteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.authorId,
    required this.authorName,
    required this.publishedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ActualiteModel.fromJson(Map<String, dynamic> json) {
    return ActualiteModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      category: _parseCategory(json['category']),
      authorId: json['author_id'],
      authorName: json['author_name'] ?? '',
      publishedAt: DateTime.parse(json['published_at']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'category': category.name,
      'author_id': authorId,
      'author_name': authorName,
      'published_at': publishedAt.toIso8601String(),
    };
  }

  static ActualiteCategory _parseCategory(String? cat) {
    switch (cat) {
      case 'evenement':
        return ActualiteCategory.evenement;
      case 'annonce':
        return ActualiteCategory.annonce;
      default:
        return ActualiteCategory.actualite;
    }
  }

  String get categoryLabel {
    switch (category) {
      case ActualiteCategory.actualite:
        return 'Actualité';
      case ActualiteCategory.evenement:
        return 'Événement';
      case ActualiteCategory.annonce:
        return 'Annonce';
    }
  }

  String get formattedDate {
    const months = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    return '${publishedAt.day} ${months[publishedAt.month]} ${publishedAt.year}';
  }
}
