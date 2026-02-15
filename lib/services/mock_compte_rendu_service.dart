import '../models/compte_rendu_model.dart';

class MockCompteRenduService {
  static final MockCompteRenduService _instance =
      MockCompteRenduService._internal();
  factory MockCompteRenduService() => _instance;
  MockCompteRenduService._internal() {
    _generateMockData();
  }

  final List<CompteRenduModel> _comptesRendus = [];

  void _generateMockData() {
    _comptesRendus.addAll([
      CompteRenduModel(
        id: '1',
        title: 'AG Décembre 2025',
        type: ReunionType.assembleeGenerale,
        reunionDate: DateTime(2025, 12, 14),
        authorId: '1',
        authorName: 'Admin MBAHE',
        points: [
          'Bilan financier de l\'année 2025 : 850€ collectés sur 1000€ prévus',
          'Renouvellement du bureau : élection du nouveau trésorier',
          'Planification des événements 2026 : fête culturelle en Mars',
          'Discussion sur l\'augmentation éventuelle des cotisations — rejetée à l\'unanimité',
          'Prochaine AG prévue en Avril 2026',
        ],
        notes:
            'Réunion tenue en visioconférence. 12 membres présents sur 15.',
        createdAt: DateTime(2025, 12, 15),
      ),
      CompteRenduModel(
        id: '2',
        title: 'AG Août 2025',
        type: ReunionType.assembleeGenerale,
        reunionDate: DateTime(2025, 8, 10),
        authorId: '1',
        authorName: 'Admin MBAHE',
        points: [
          'Point sur les cotisations du 1er semestre : 60% de recouvrement',
          'Organisation de la fête de rentrée en Septembre',
          'Accueil de 3 nouveaux membres',
          'Mise en place d\'un groupe WhatsApp pour la communication',
        ],
        notes: 'Réunion en présentiel à Paris. 10 membres présents.',
        createdAt: DateTime(2025, 8, 11),
      ),
      CompteRenduModel(
        id: '3',
        title: 'AG Avril 2025',
        type: ReunionType.assembleeGenerale,
        reunionDate: DateTime(2025, 4, 5),
        authorId: '1',
        authorName: 'Admin MBAHE',
        points: [
          'Bilan du 1er trimestre 2025',
          'Validation du budget prévisionnel',
          'Projet de création d\'une application mobile pour l\'association',
          'Organisation d\'une collecte de fonds pour le village',
        ],
        notes: null,
        createdAt: DateTime(2025, 4, 6),
      ),
    ]);
  }

  Future<List<CompteRenduModel>> getAllComptesRendus() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_comptesRendus)
      ..sort((a, b) => b.reunionDate.compareTo(a.reunionDate));
  }

  Future<CompteRenduModel?> getCompteRenduById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _comptesRendus.firstWhere((cr) => cr.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<CompteRenduModel> createCompteRendu({
    required String title,
    required ReunionType type,
    required DateTime reunionDate,
    required String authorId,
    required String authorName,
    required List<String> points,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final cr = CompteRenduModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      type: type,
      reunionDate: reunionDate,
      authorId: authorId,
      authorName: authorName,
      points: points,
      notes: notes,
    );
    _comptesRendus.add(cr);
    return cr;
  }

  Future<bool> updateCompteRendu(CompteRenduModel updated) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _comptesRendus.indexWhere((cr) => cr.id == updated.id);
    if (index == -1) return false;
    _comptesRendus[index] = updated;
    return true;
  }

  Future<bool> deleteCompteRendu(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _comptesRendus.indexWhere((cr) => cr.id == id);
    if (index == -1) return false;
    _comptesRendus.removeAt(index);
    return true;
  }
}
