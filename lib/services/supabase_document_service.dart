import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDocumentService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Récupérer un document par son type (statuts ou reglement)
  Future<Map<String, dynamic>?> getDocument(String documentType) async {
    try {
      final data = await _client
          .from('documents')
          .select()
          .eq('document_type', documentType)
          .single();
      return data;
    } catch (_) {
      return null;
    }
  }

  /// Mettre à jour le contenu d'un document
  Future<bool> updateDocument(String documentType, String content) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final profile = await _client
          .from('profiles')
          .select('first_name, last_name')
          .eq('id', user.id)
          .single();
      final adminName = '${profile['first_name']} ${profile['last_name']}';

      await _client.from('documents').update({
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by_name': adminName,
      }).eq('document_type', documentType);

      return true;
    } catch (_) {
      return false;
    }
  }
}
