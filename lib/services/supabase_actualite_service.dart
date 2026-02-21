import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/actualite_model.dart';

class SupabaseActualiteService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Récupérer toutes les actualités
  Future<List<ActualiteModel>> getAllActualites() async {
    final data = await _client
        .from('actualites')
        .select()
        .order('published_at', ascending: false);

    return data.map<ActualiteModel>(
      (json) => ActualiteModel.fromJson(json),
    ).toList();
  }

  /// Créer une actualité
  Future<ActualiteModel> createActualite({
    required String title,
    required String content,
    required ActualiteCategory category,
    required String authorId,
    required String authorName,
  }) async {
    final actu = ActualiteModel(
      id: '',
      title: title,
      content: content,
      category: category,
      authorId: authorId,
      authorName: authorName,
      publishedAt: DateTime.now(),
    );

    final data = await _client
        .from('actualites')
        .insert(actu.toJson())
        .select()
        .single();

    return ActualiteModel.fromJson(data);
  }

  /// Mettre à jour une actualité
  Future<bool> updateActualite(String id, {
    required String title,
    required String content,
    required ActualiteCategory category,
  }) async {
    try {
      await _client
          .from('actualites')
          .update({
            'title': title,
            'content': content,
            'category': category.name,
          })
          .eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Supprimer une actualité
  Future<bool> deleteActualite(String id) async {
    try {
      await _client
          .from('actualites')
          .delete()
          .eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
