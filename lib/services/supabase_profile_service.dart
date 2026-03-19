import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class SupabaseProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<UserModel?> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
    DateTime? dateOfBirth,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (phone != null) updates['phone'] = phone;
      if (bio != null) updates['bio'] = bio;
      if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth.toIso8601String();

      if (updates.isEmpty) return null;

      final data = await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadProfilePhoto({
    required String userId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final filePath = '$userId/$fileName';

      await _client.storage.from('profile-photos').uploadBinary(
            filePath,
            imageBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: _getContentType(fileName),
            ),
          );

      final publicUrl = _client.storage.from('profile-photos').getPublicUrl(filePath);

      await _client.from('profiles').update({
        'photo_url': publicUrl,
      }).eq('id', userId);

      return publicUrl;
    } catch (e) {
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

      return true;
    } catch (e) {
      return false;
    }
  }

  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final cotisationsData = await _client
          .from('cotisations')
          .select('status')
          .eq('user_id', userId)
          .eq('status', 'paid');

      return {
        'cotisations_paid': cotisationsData.length,
      };
    } catch (e) {
      return {
        'cotisations_paid': 0,
      };
    }
  }
}
