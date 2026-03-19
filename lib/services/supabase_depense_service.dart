import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/depense_model.dart';

class SupabaseDepenseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Récupérer toutes les dépenses (admins voient tout, membres voient validées)
  Future<List<DepenseModel>> getAllDepenses() async {
    try {
      final data = await _client
          .from('depenses')
          .select()
          .order('depense_date', ascending: false);
      return (data as List).map((e) => DepenseModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Récupérer les dépenses validées uniquement
  Future<List<DepenseModel>> getApprovedDepenses() async {
    try {
      final data = await _client
          .from('depenses')
          .select()
          .eq('status', 'approved')
          .order('depense_date', ascending: false);
      return (data as List).map((e) => DepenseModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Récupérer les dépenses en attente de validation
  Future<List<DepenseModel>> getPendingDepenses() async {
    try {
      final data = await _client
          .from('depenses')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return (data as List).map((e) => DepenseModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Créer une nouvelle dépense
  Future<DepenseModel?> createDepense({
    required double amount,
    required String motif,
    String? description,
    required DateTime depenseDate,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final profile = await _client
          .from('profiles')
          .select('first_name, last_name')
          .eq('id', user.id)
          .single();
      final creatorName = '${profile['first_name']} ${profile['last_name']}';

      final data = await _client.from('depenses').insert({
        'amount': amount,
        'motif': motif,
        'description': description,
        'depense_date': depenseDate.toIso8601String().split('T')[0],
        'created_by': user.id,
        'created_by_name': creatorName,
        'status': 'pending',
      }).select().single();

      return DepenseModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Valider une dépense (par un autre admin)
  Future<bool> approveDepense(String depenseId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      // Vérifier que ce n'est pas le même admin qui a créé la dépense
      final depense = await _client
          .from('depenses')
          .select('created_by')
          .eq('id', depenseId)
          .single();

      if (depense['created_by'] == user.id) {
        return false;
      }

      final profile = await _client
          .from('profiles')
          .select('first_name, last_name')
          .eq('id', user.id)
          .single();
      final validatorName = '${profile['first_name']} ${profile['last_name']}';

      await _client.from('depenses').update({
        'status': 'approved',
        'validated_by': user.id,
        'validated_by_name': validatorName,
        'validated_at': DateTime.now().toIso8601String(),
      }).eq('id', depenseId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Rejeter une dépense (par un autre admin)
  Future<bool> rejectDepense(String depenseId, String reason) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      // Vérifier que ce n'est pas le même admin qui a créé la dépense
      final depense = await _client
          .from('depenses')
          .select('created_by')
          .eq('id', depenseId)
          .single();

      if (depense['created_by'] == user.id) {
        return false;
      }

      final profile = await _client
          .from('profiles')
          .select('first_name, last_name')
          .eq('id', user.id)
          .single();
      final validatorName = '${profile['first_name']} ${profile['last_name']}';

      await _client.from('depenses').update({
        'status': 'rejected',
        'validated_by': user.id,
        'validated_by_name': validatorName,
        'validated_at': DateTime.now().toIso8601String(),
        'rejection_reason': reason,
      }).eq('id', depenseId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Supprimer une dépense (seulement si pending)
  Future<bool> deleteDepense(String depenseId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      // Vérifier que la dépense est bien en pending
      final depense = await _client
          .from('depenses')
          .select('status, created_by')
          .eq('id', depenseId)
          .single();

      if (depense['status'] != 'pending') {
        return false;
      }

      await _client.from('depenses').delete().eq('id', depenseId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Total des dépenses validées
  Future<double> getTotalApprovedDepenses() async {
    try {
      final data = await _client
          .from('depenses')
          .select('amount')
          .eq('status', 'approved');
      double total = 0.0;
      for (final row in data) {
        total += (row['amount'] ?? 0.0).toDouble();
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }
}
