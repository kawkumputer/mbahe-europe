import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mandat_model.dart';
import '../models/bureau_membre_model.dart';

class SupabaseBureauService {
  final SupabaseClient _client = Supabase.instance.client;

  // ===================== MANDATS =====================

  /// Récupérer tous les mandats
  Future<List<MandatModel>> getAllMandats() async {
    final data = await _client
        .from('mandats')
        .select()
        .order('start_date', ascending: false);

    return data.map<MandatModel>((json) => MandatModel.fromJson(json)).toList();
  }

  /// Récupérer le mandat actif
  Future<MandatModel?> getActiveMandat() async {
    final data = await _client
        .from('mandats')
        .select()
        .eq('is_active', true)
        .limit(1);

    if (data.isEmpty) return null;
    return MandatModel.fromJson(data.first);
  }

  /// Créer un mandat
  Future<MandatModel> createMandat({
    required String label,
    required DateTime startDate,
    required DateTime endDate,
    bool isActive = false,
  }) async {
    // Si ce mandat est actif, désactiver les autres
    if (isActive) {
      await _client
          .from('mandats')
          .update({'is_active': false})
          .eq('is_active', true);
    }

    final mandat = MandatModel(
      id: '',
      label: label,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
    );

    final data = await _client
        .from('mandats')
        .insert(mandat.toJson())
        .select()
        .single();

    return MandatModel.fromJson(data);
  }

  /// Activer un mandat (désactive les autres)
  Future<bool> activateMandat(String mandatId) async {
    try {
      await _client
          .from('mandats')
          .update({'is_active': false})
          .eq('is_active', true);

      await _client
          .from('mandats')
          .update({'is_active': true})
          .eq('id', mandatId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Supprimer un mandat
  Future<bool> deleteMandat(String mandatId) async {
    try {
      await _client.from('mandats').delete().eq('id', mandatId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ===================== BUREAU MEMBRES =====================

  /// Récupérer les membres du bureau pour un mandat
  Future<List<BureauMembreModel>> getBureauMembres(String mandatId) async {
    final data = await _client
        .from('bureau_membres')
        .select()
        .eq('mandat_id', mandatId)
        .order('created_at', ascending: true);

    return data
        .map<BureauMembreModel>((json) => BureauMembreModel.fromJson(json))
        .toList();
  }

  /// Ajouter un membre au bureau
  Future<BureauMembreModel> addBureauMembre({
    required String mandatId,
    required String userId,
    required String userName,
    required String poste,
  }) async {
    final data = await _client
        .from('bureau_membres')
        .insert({
          'mandat_id': mandatId,
          'user_id': userId,
          'user_name': userName,
          'poste': poste,
        })
        .select()
        .single();

    return BureauMembreModel.fromJson(data);
  }

  /// Supprimer un membre du bureau
  Future<bool> removeBureauMembre(String id) async {
    try {
      await _client.from('bureau_membres').delete().eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mettre à jour le poste d'un membre du bureau
  Future<bool> updateBureauMembre(String id, {
    required String userId,
    required String userName,
    required String poste,
  }) async {
    try {
      await _client
          .from('bureau_membres')
          .update({
            'user_id': userId,
            'user_name': userName,
            'poste': poste,
          })
          .eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
