class BureauMembreModel {
  final String id;
  final String mandatId;
  final String userId;
  final String userName;
  final String poste;
  final DateTime createdAt;

  BureauMembreModel({
    required this.id,
    required this.mandatId,
    required this.userId,
    required this.userName,
    required this.poste,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory BureauMembreModel.fromJson(Map<String, dynamic> json) {
    return BureauMembreModel(
      id: json['id'],
      mandatId: json['mandat_id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? '',
      poste: json['poste'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mandat_id': mandatId,
      'user_id': userId,
      'user_name': userName,
      'poste': poste,
    };
  }

  static const List<String> postes = [
    'Président',
    'Vice-Président',
    'Secrétaire Général',
    'Secrétaire Général Adjoint',
    'Trésorier',
    'Trésorier Adjoint',
    'Commissaire aux comptes',
    'Chargé de communication',
    'Conseiller',
  ];
}
