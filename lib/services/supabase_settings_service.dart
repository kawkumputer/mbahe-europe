import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSettingsService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Récupérer une valeur de paramètre par sa clé
  Future<String?> getSetting(String key) async {
    try {
      final data = await _client
          .from('app_settings')
          .select('setting_value')
          .eq('setting_key', key)
          .maybeSingle();

      return data?['setting_value'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Récupérer le montant total des années précédentes
  Future<double> getPreviousYearsTotalAmount() async {
    try {
      final value = await getSetting('previous_years_total_amount');
      return value != null ? double.tryParse(value) ?? 0.0 : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Mettre à jour le montant total des années précédentes (sys_admin uniquement)
  Future<bool> updatePreviousYearsTotalAmount(double amount) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      await _client
          .from('app_settings')
          .update({
            'setting_value': amount.toString(),
            'updated_at': DateTime.now().toIso8601String(),
            'updated_by': userId,
          })
          .eq('setting_key', 'previous_years_total_amount');

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Récupérer tous les paramètres
  Future<List<Map<String, dynamic>>> getAllSettings() async {
    try {
      final data = await _client
          .from('app_settings')
          .select()
          .order('setting_key');

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }
}
