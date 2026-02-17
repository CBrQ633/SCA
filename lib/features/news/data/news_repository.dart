import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/services/models.dart';

class NewsRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get all active announcements
  Future<List<NewsAnnouncement>> getActiveAnnouncements() async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('news_announcements')
          .select()
          .eq('is_active', true)
          .or('expiry_date.is.null,expiry_date.gt.$now')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NewsAnnouncement.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch announcements: $e');
    }
  }

  // Get all announcements (admin only)
  Future<List<NewsAnnouncement>> getAllAnnouncements() async {
    try {
      final response = await _supabase
          .from('news_announcements')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NewsAnnouncement.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all announcements: $e');
    }
  }

  // Create announcement (admin only)
  Future<void> createAnnouncement({
    required String title,
    required String content,
    required String createdBy,
    DateTime? expiryDate,
    List<File>? imageFiles,
  }) async {
    try {
      List<String> imageUrls = [];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (var imageFile in imageFiles) {
          final fileExt = imageFile.path.split('.').last;
          final fileName =
              'news_${DateTime.now().millisecondsSinceEpoch}_${imageFiles.indexOf(imageFile)}.$fileExt';

          try {
            await _supabase.storage.from('news_images').upload(
                  fileName,
                  imageFile,
                  fileOptions:
                      const FileOptions(cacheControl: '3600', upsert: false),
                );
            final url =
                _supabase.storage.from('news_images').getPublicUrl(fileName);
            imageUrls.add(url);
          } catch (storageError) {
            debugPrint('Storage error: $storageError');
            // If upload fails, we skip this image but continue with other images/record
          }
        }
      }

      await _supabase.from('news_announcements').insert({
        'title': title, // Unified field
        'title_ar': title, // Backward compatibility
        'content': content, // Unified field
        'content_ar': content, // Backward compatibility
        'created_by': createdBy,
        'is_active': true,
        'image_urls': imageUrls,
        'expiry_date': expiryDate?.toIso8601String(),
      });
    } catch (e) {
      if (e.toString().contains('404')) {
        throw Exception(
            'خطأ في مساحة التخزين: يرجى التأكد من وجود "Bucket" باسم "news_images" في Supabase Storage.\n(Storage Bucket "news_images" not found)');
      }
      throw Exception('Failed to create announcement: $e');
    }
  }

  // Update announcement (admin only)
  Future<void> updateAnnouncement({
    required String id,
    required String title,
    required String content,
    DateTime? expiryDate,
    List<File>? imageFiles,
    List<String>? existingImageUrls,
  }) async {
    try {
      List<String> imageUrls = existingImageUrls ?? [];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (var imageFile in imageFiles) {
          final fileExt = imageFile.path.split('.').last;
          final fileName =
              'news_upd_${DateTime.now().millisecondsSinceEpoch}_${imageFiles.indexOf(imageFile)}.$fileExt';

          try {
            await _supabase.storage.from('news_images').upload(
                  fileName,
                  imageFile,
                  fileOptions:
                      const FileOptions(cacheControl: '3600', upsert: false),
                );
            final url =
                _supabase.storage.from('news_images').getPublicUrl(fileName);
            imageUrls.add(url);
          } catch (storageError) {
            debugPrint('Storage update error: $storageError');
          }
        }
      }

      await _supabase.from('news_announcements').update({
        'title': title,
        'title_ar': title,
        'content': content,
        'content_ar': content,
        'image_urls': imageUrls,
        'expiry_date': expiryDate?.toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update announcement: $e');
    }
  }

  // Delete announcement (admin only)
  Future<void> deleteAnnouncement(String id) async {
    try {
      await _supabase.from('news_announcements').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete announcement: $e');
    }
  }

  // Toggle active status (admin only)
  Future<void> toggleActiveStatus(String id, bool isActive) async {
    try {
      await _supabase
          .from('news_announcements')
          .update({'is_active': isActive}).eq('id', id);
    } catch (e) {
      throw Exception('Failed to toggle active status: $e');
    }
  }
}
