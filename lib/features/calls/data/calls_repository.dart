import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/services/models.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'models/call_list_model.dart';

class CallsRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get user's call lists with error handling
  Future<List<CallListModel>> getMyLists() async {
    try {
      final response = await _supabase
          .from('call_lists')
          .select()
          .order('created_at', ascending: false);
      return (response as List).map((e) => CallListModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch call lists: $e');
    }
  }

  // Unified Create List
  Future<CallListModel> createList(String name, String userId) async {
    try {
      final response = await _supabase
          .from('call_lists')
          .insert({'user_id': userId, 'name': name})
          .select()
          .single();
      return CallListModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create call list: $e');
    }
  }

  // Get items for a list
  Future<List<CallListItemModel>> getListItems(String listId) async {
    try {
      final response = await _supabase
          .from('call_list_items')
          .select()
          .eq('list_id', listId)
          .order('status', ascending: true)
          .order('created_at', ascending: true);
      return (response as List).map((e) => CallListItemModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch list items: $e');
    }
  }

  // Add multiple items to list (Batch Insert)
  Future<void> addItemsToList(String listId, List<Map<String, String>> items) async {
    if (items.isEmpty) return;
    try {
      final data = items.map((item) => {
        'list_id': listId,
        'name': item['name'] ?? 'Unknown',
        'phone': _normalizePhoneNumber(item['phone'] ?? ''),
        'status': 'pending',
      }).where((element) => element['phone']!.isNotEmpty).toList();

      if (data.isNotEmpty) {
        await _supabase.from('call_list_items').insert(data);
      }
    } catch (e) {
      throw Exception('Failed to add items: $e');
    }
  }

  // Update item status with notes
  Future<void> updateItemStatus(String itemId, String status, {String? notes}) async {
    try {
      await _supabase.from('call_list_items').update({
        'status': status,
        if (notes != null) 'notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', itemId);
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }

  // Enhanced Phone Normalization (Specially for Egypt)
  String _normalizePhoneNumber(String raw) {
    if (raw.trim().isEmpty) return '';

    // Clean input
    String clean = raw.replaceAll(RegExp(r'[^\d+]'), '');

    // Handle Excel Scientific Notation
    if (raw.toUpperCase().contains('E')) {
      try { clean = double.parse(raw).toStringAsFixed(0); } catch (_) {}
    }
    if (clean.endsWith('.0')) clean = clean.substring(0, clean.length - 2);

    // Egypt Logic
    if (clean.startsWith('+20')) clean = clean.substring(3);
    else if (clean.startsWith('201')) clean = clean.substring(2);

    if (clean.length == 10 && RegExp(r'^(10|11|12|15)').hasMatch(clean)) {
      return '0$clean';
    }

    return (clean.length == 11 && clean.startsWith('01')) ? clean : clean;
  }

  // Robust Excel/CSV Import
  Future<List<Map<String, String>>> importFromExcel(File file) async {
    try {
      final bytes = file.readAsBytesSync();
      final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: true);
      final List<Map<String, String>> entries = [];

      for (var table in decoder.tables.keys) {
        final sheet = decoder.tables[table];
        if (sheet == null) continue;

        for (var row in sheet.rows) {
          String phone = '';
          String name = 'Unknown';

          for (var cell in row) {
            if (cell == null) continue;
            String val = cell.toString().trim();
            String norm = _normalizePhoneNumber(val);

            if (norm.length >= 10 && RegExp(r'^01[0125]').hasMatch(norm)) {
              phone = norm;
            } else if (val.length > 2 && int.tryParse(val) == null) {
              name = val;
            }
          }
          if (phone.isNotEmpty) entries.add({'phone': phone, 'name': name});
        }
      }
      return entries;
    } catch (e) {
      throw Exception('Excel Import Error: $e');
    }
  }

  // Smart OCR Extraction
  Future<List<String>> extractNumbersFromImage(File imageFile) async {
    final textRecognizer = TextRecognizer();
    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(InputImage.fromFile(imageFile));
      final phoneRegex = RegExp(r'(\+?\d[\d\s-]{7,15}\d)');
      final Set<String> numbers = {};

      for (var block in recognizedText.blocks) {
        for (var line in block.lines) {
          for (var match in phoneRegex.allMatches(line.text)) {
            final norm = _normalizePhoneNumber(match.group(0)!);
            if (norm.length >= 10) numbers.add(norm);
          }
        }
      }
      return numbers.toList();
    } finally {
      textRecognizer.close();
    }
  }

  // Delete List
  Future<void> deleteCallList(String listId) async {
    try {
      await _supabase.from('call_lists').delete().eq('id', listId);
    } catch (e) {
      throw Exception('Delete failed: $e');
    }
  }

  // Added missing method for Admin Dashboard
  Future<int> getTotalCallsToday() async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final response = await _supabase
          .from('call_list_items')
          .select('id')
          .not('status', 'eq', 'pending')
          .gte('updated_at', today);
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}
