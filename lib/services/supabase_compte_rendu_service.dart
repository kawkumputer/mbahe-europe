import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/compte_rendu_model.dart';

class SupabaseCompteRenduService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Récupérer tous les comptes rendus
  Future<List<CompteRenduModel>> getAllComptesRendus() async {
    final data = await _client
        .from('comptes_rendus')
        .select()
        .order('reunion_date', ascending: false);

    return data.map<CompteRenduModel>(
      (json) => CompteRenduModel.fromJson(json),
    ).toList();
  }

  /// Récupérer un compte rendu par ID
  Future<CompteRenduModel?> getCompteRenduById(String id) async {
    try {
      final data = await _client
          .from('comptes_rendus')
          .select()
          .eq('id', id)
          .single();
      return CompteRenduModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Créer un nouveau compte rendu
  Future<CompteRenduModel> createCompteRendu({
    required String title,
    required ReunionType type,
    required DateTime reunionDate,
    required String authorId,
    required String authorName,
    required List<String> points,
    String? notes,
  }) async {
    final cr = CompteRenduModel(
      id: '', // sera généré par Supabase
      title: title,
      type: type,
      reunionDate: reunionDate,
      authorId: authorId,
      authorName: authorName,
      points: points,
      notes: notes,
    );

    final data = await _client
        .from('comptes_rendus')
        .insert(cr.toJson())
        .select()
        .single();

    return CompteRenduModel.fromJson(data);
  }

  /// Mettre à jour un compte rendu
  Future<bool> updateCompteRendu(CompteRenduModel updated) async {
    try {
      await _client
          .from('comptes_rendus')
          .update(updated.toJson())
          .eq('id', updated.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Supprimer un compte rendu
  Future<bool> deleteCompteRendu(String id) async {
    try {
      await _client
          .from('comptes_rendus')
          .delete()
          .eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
