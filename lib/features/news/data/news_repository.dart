import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/services/models.dart';

class NewsRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  Future<List<NewsAnnouncement>> getActiveAnnouncements() async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('news_announcements')
          .select()
          .eq('is_active', true)
          .or('expiry_date.is.null,expiry_date.gt.$now')
          .order('created_at', ascending: false);

      return (response as List).map((json) => NewsAnnouncement.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch announcements: $e');
    }
  }

  Future<List<NewsAnnouncement>> getAllAnnouncements() async {
    try {
      final response = await _supabase
          .from('news_announcements')
          .select()
          .order('created_at', ascending: false);
      return (response as List).map((json) => NewsAnnouncement.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all announcements: $e');
    }
  }

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
          final fileName = 'news_${DateTime.now().millisecondsSinceEpoch}_${imageFiles.indexOf(imageFile)}';
          try {
            await _supabase.storage.from('news_images').upload(fileName, imageFile);
            imageUrls.add(_supabase.storage.from('news_images').getPublicUrl(fileName));
          } catch (e) {
            debugPrint('Image upload skipped due to error: $e');
          }
        }
      }

      await _supabase.from('news_announcements').insert({
        'title': title,
        'title_ar': title,
        'content': content,
        'content_ar': content,
        'created_by': createdBy,
        'is_active': true,
        'image_urls': imageUrls,
        'expiry_date': expiryDate?.toIso8601String(),
      });
    } catch (e) {
      throw Exception('خطأ في إنشاء الخبر: $e');
    }
  }

  Future<void> toggleActiveStatus(String id, bool isActive) async {
    await _supabase.from('news_announcements').update({'is_active': isActive}).eq('id', id);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _supabase.from('news_announcements').delete().eq('id', id);
  }
}
