import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/activity_history_model.dart';

class SupabaseProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<UserModel?> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (phone != null) updates['phone'] = phone;
      if (bio != null) updates['bio'] = bio;

      if (updates.isEmpty) return null;

      final data = await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      await _logActivity(
        userId: userId,
        actionType: 'profile_update',
        description: 'Profil mis à jour',
        metadata: updates,
      );

      return UserModel.fromJson(data);
    } catch (e) {
      debugPrint('updateProfile error: $e');
      return null;
    }
  }

  Future<String?> uploadProfilePhoto({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = 'profile-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      await _client.storage.from('profile-photos').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final publicUrl = _client.storage.from('profile-photos').getPublicUrl(filePath);

      await _client.from('profiles').update({
        'photo_url': publicUrl,
      }).eq('id', userId);

      await _logActivity(
        userId: userId,
        actionType: 'profile_update',
        description: 'Photo de profil mise à jour',
      );

      return publicUrl;
    } catch (e) {
      debugPrint('uploadProfilePhoto error: $e');
      return null;
    }
  }

  Future<bool> deleteProfilePhoto(String userId) async {
    try {
      final profile = await _client
          .from('profiles')
          .select('photo_url')
          .eq('id', userId)
          .single();

      final photoUrl = profile['photo_url'] as String?;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        final path = photoUrl.split('/profile-photos/').last;
        if (path.isNotEmpty) {
          await _client.storage.from('profile-photos').remove(['profile-photos/$path']);
        }
      }

      await _client.from('profiles').update({
        'photo_url': null,
      }).eq('id', userId);

      await _logActivity(
        userId: userId,
        actionType: 'profile_update',
        description: 'Photo de profil supprimée',
      );

      return true;
    } catch (e) {
      debugPrint('deleteProfilePhoto error: $e');
      return false;
    }
  }

  Future<List<ActivityHistoryModel>> getUserActivity({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final data = await _client
          .from('user_activity')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return data.map<ActivityHistoryModel>((json) => ActivityHistoryModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('getUserActivity error: $e');
      return [];
    }
  }

  Future<void> logLogin(String userId) async {
    await _logActivity(
      userId: userId,
      actionType: 'login',
      description: 'Connexion',
    );
  }

  Future<void> _logActivity({
    required String userId,
    required String actionType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.from('user_activity').insert({
        'user_id': userId,
        'action_type': actionType,
        'description': description,
        'metadata': metadata,
      });
    } catch (e) {
      debugPrint('_logActivity error: $e');
    }
  }

  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final cotisationsData = await _client
          .from('cotisations')
          .select('status')
          .eq('user_id', userId)
          .eq('status', 'paid');

      final activityData = await _client
          .from('user_activity')
          .select('id')
          .eq('user_id', userId);

      return {
        'cotisations_paid': cotisationsData.length,
        'total_activities': activityData.length,
      };
    } catch (e) {
      debugPrint('getUserStats error: $e');
      return {
        'cotisations_paid': 0,
        'total_activities': 0,
      };
    }
  }
}
