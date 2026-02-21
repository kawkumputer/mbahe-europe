import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cotisation_model.dart';

class SupabaseCotisationService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Helper: récupérer l'admin courant (id + nom)
  Future<Map<String, String>> _getCurrentAdmin() async {
    final user = _client.auth.currentUser;
    if (user == null) return {'id': '', 'name': ''};
    final profile = await _client
        .from('profiles')
        .select('id, first_name, last_name')
        .eq('id', user.id)
        .single();
    final name = '${profile['first_name']} ${profile['last_name']}';
    return {'id': user.id, 'name': name};
  }

  /// Helper: enregistrer une action dans audit_log
  Future<void> _logAction({
    required String adminId,
    required String adminName,
    required String action,
    required String targetTable,
    String? targetId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _client.from('audit_log').insert({
        'admin_id': adminId,
        'admin_name': adminName,
        'action': action,
        'target_table': targetTable,
        'target_id': targetId,
        'details': details,
      });
    } catch (_) {}
  }

  /// Récupérer les cotisations d'un adhérent pour une année
  /// Génère automatiquement les cotisations si elles n'existent pas
  Future<List<CotisationModel>> getCotisationsByUserAndYear(
    String userId,
    int year,
  ) async {
    // Vérifier si les cotisations existent
    final existing = await _client
        .from('cotisations')
        .select()
        .eq('user_id', userId)
        .eq('year', year);

    if (existing.isEmpty) {
      await generateCotisationsForUser(userId, year);
    }

    final data = await _client
        .from('cotisations')
        .select()
        .eq('user_id', userId)
        .eq('year', year)
        .order('month', ascending: true);

    return data.map<CotisationModel>((json) => CotisationModel.fromJson(json)).toList();
  }

  /// Récupérer toutes les cotisations d'un adhérent
  Future<List<CotisationModel>> getCotisationsByUser(String userId) async {
    final data = await _client
        .from('cotisations')
        .select()
        .eq('user_id', userId)
        .order('year', ascending: false)
        .order('month', ascending: true);

    return data.map<CotisationModel>((json) => CotisationModel.fromJson(json)).toList();
  }

  /// Marquer une cotisation comme payée avec mode de paiement
  Future<bool> markAsPaid(String cotisationId, PaymentMethod method) async {
    try {
      final admin = await _getCurrentAdmin();
      await _client.from('cotisations').update({
        'status': 'paid',
        'paid_at': DateTime.now().toIso8601String(),
        'payment_method': method.name,
        'updated_by': admin['id'],
        'updated_by_name': admin['name'],
      }).eq('id', cotisationId);
      await _logAction(
        adminId: admin['id']!,
        adminName: admin['name']!,
        action: 'mark_paid',
        targetTable: 'cotisations',
        targetId: cotisationId,
        details: {'payment_method': method.name},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Marquer une cotisation comme impayée
  Future<bool> markAsUnpaid(String cotisationId) async {
    try {
      final admin = await _getCurrentAdmin();
      await _client.from('cotisations').update({
        'status': 'unpaid',
        'paid_at': null,
        'payment_method': null,
        'updated_by': admin['id'],
        'updated_by_name': admin['name'],
      }).eq('id', cotisationId);
      await _logAction(
        adminId: admin['id']!,
        adminName: admin['name']!,
        action: 'mark_unpaid',
        targetTable: 'cotisations',
        targetId: cotisationId,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Marquer une cotisation comme exemptée (chômage)
  Future<bool> markAsExempted(String cotisationId) async {
    try {
      final admin = await _getCurrentAdmin();
      await _client.from('cotisations').update({
        'status': 'exempted',
        'paid_at': null,
        'payment_method': null,
        'updated_by': admin['id'],
        'updated_by_name': admin['name'],
      }).eq('id', cotisationId);
      await _logAction(
        adminId: admin['id']!,
        adminName: admin['name']!,
        action: 'mark_exempted',
        targetTable: 'cotisations',
        targetId: cotisationId,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Retirer l'exemption chômage
  Future<bool> removeExemption(String cotisationId) async {
    try {
      final admin = await _getCurrentAdmin();
      await _client.from('cotisations').update({
        'status': 'unpaid',
        'paid_at': null,
        'payment_method': null,
        'updated_by': admin['id'],
        'updated_by_name': admin['name'],
      }).eq('id', cotisationId);
      await _logAction(
        adminId: admin['id']!,
        adminName: admin['name']!,
        action: 'remove_exemption',
        targetTable: 'cotisations',
        targetId: cotisationId,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Générer les cotisations pour un adhérent (appel de la fonction SQL)
  Future<void> generateCotisationsForUser(String userId, int year) async {
    await _client.rpc('generate_cotisations', params: {
      'p_user_id': userId,
      'p_year': year,
    });
  }

  /// Résumé des cotisations d'un adhérent pour une année
  Future<Map<String, dynamic>> getUserYearlySummary(
    String userId,
    int year,
  ) async {
    final cotisations = await getCotisationsByUserAndYear(userId, year);
    final paid = cotisations.where((c) => c.isPaid).length;
    final exempted = cotisations.where((c) => c.isExempted).length;
    final unpaid = cotisations.where((c) => c.status == CotisationStatus.unpaid).length;
    final totalPaid = paid * CotisationModel.monthlyAmount;
    final totalDue = (CotisationModel.cotisableMonths.length - exempted) * CotisationModel.monthlyAmount;

    return {
      'paid': paid,
      'unpaid': unpaid,
      'exempted': exempted,
      'totalPaid': totalPaid,
      'totalDue': totalDue,
      'remaining': totalDue - totalPaid,
      'percentage': totalDue > 0 ? (totalPaid / totalDue) : 0.0,
    };
  }

  /// Résumé des paiements par mode pour une année donnée
  Future<Map<String, dynamic>> getPaymentSummaryByYear(int year) async {
    final data = await _client
        .from('cotisations')
        .select()
        .eq('year', year)
        .eq('status', 'paid');

    final paidCotisations = data.map<CotisationModel>(
      (json) => CotisationModel.fromJson(json),
    ).toList();

    return _computePaymentBreakdown(paidCotisations);
  }

  /// Résumé des paiements par mode pour une période donnée
  Future<Map<String, dynamic>> getPaymentSummaryForPeriod(
    int year,
    List<int> months,
  ) async {
    final data = await _client
        .from('cotisations')
        .select()
        .eq('year', year)
        .eq('status', 'paid')
        .inFilter('month', months);

    final paidCotisations = data.map<CotisationModel>(
      (json) => CotisationModel.fromJson(json),
    ).toList();

    return _computePaymentBreakdown(paidCotisations);
  }

  /// Résumé des paiements effectués entre deux dates (basé sur paidAt)
  Future<Map<String, dynamic>> getPaymentSummaryByDateRange(
    DateTime from,
    DateTime to,
  ) async {
    final data = await _client
        .from('cotisations')
        .select()
        .eq('status', 'paid')
        .not('paid_at', 'is', null)
        .gte('paid_at', from.toIso8601String())
        .lte('paid_at', to.add(const Duration(days: 1)).toIso8601String());

    final paidCotisations = data.map<CotisationModel>(
      (json) => CotisationModel.fromJson(json),
    ).toList();

    return _computePaymentBreakdown(paidCotisations);
  }

  /// Résumé global pour l'admin (tous les adhérents, année donnée)
  Future<List<Map<String, dynamic>>> getAllMembersSummary(int year) async {
    final data = await _client
        .from('cotisations')
        .select('user_id')
        .eq('year', year);

    final userIds = data.map<String>((row) => row['user_id'] as String).toSet();
    final summaries = <Map<String, dynamic>>[];

    for (final userId in userIds) {
      final summary = await getUserYearlySummary(userId, year);
      summary['userId'] = userId;
      summaries.add(summary);
    }

    return summaries;
  }

  Map<String, dynamic> _computePaymentBreakdown(List<CotisationModel> paidCotisations) {
    double totalEspece = 0;
    double totalVirement = 0;
    double totalCheque = 0;
    int countEspece = 0;
    int countVirement = 0;
    int countCheque = 0;

    for (final c in paidCotisations) {
      switch (c.paymentMethod) {
        case PaymentMethod.espece:
          totalEspece += c.amount;
          countEspece++;
          break;
        case PaymentMethod.virement:
          totalVirement += c.amount;
          countVirement++;
          break;
        case PaymentMethod.cheque:
          totalCheque += c.amount;
          countCheque++;
          break;
        case null:
          break;
      }
    }

    final totalPaid = totalEspece + totalVirement + totalCheque;

    return {
      'totalPaid': totalPaid,
      'totalEspece': totalEspece,
      'totalVirement': totalVirement,
      'totalCheque': totalCheque,
      'countEspece': countEspece,
      'countVirement': countVirement,
      'countCheque': countCheque,
      'countTotal': paidCotisations.length,
    };
  }
}
