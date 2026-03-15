import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'models/call_list_model.dart';

class CallsRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  Future<List<CallListModel>> getMyLists({bool archived = false}) async {
    try {
      final status = archived ? 'archived' : 'active';
      final response = await _supabase
          .from('call_lists')
          .select('*, call_list_items(status)')
          .eq('status', status)
          .order('created_at', ascending: false);
      
      return (response as List).map((e) {
        final items = e['call_list_items'] as List;
        final total = items.length;
        final completed = items.where((i) => i['status'] != 'pending').length;
        final progress = total == 0 ? 0.0 : completed / total;
        
        var map = Map<String, dynamic>.from(e);
        map['progress'] = progress;
        map['total_items'] = total;
        return CallListModel.fromJson(map);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch call lists: $e');
    }
  }

  Future<CallListModel> createList(String name, String userId) async {
    final response = await _supabase
        .from('call_lists')
        .insert({'user_id': userId, 'name': name, 'status': 'active'})
        .select()
        .single();
    return CallListModel.fromJson(response);
  }

  Future<void> toggleArchive(String listId, bool shouldArchive) async {
    await _supabase
        .from('call_lists')
        .update({'status': shouldArchive ? 'archived' : 'active'})
        .eq('id', listId);
  }

  Future<List<CallListItemModel>> getListItems(String listId) async {
    final response = await _supabase
        .from('call_list_items')
        .select()
        .eq('list_id', listId)
        .order('status', ascending: true)
        .order('created_at', ascending: true);
    return (response as List).map((e) => CallListItemModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> addItemsToList(String listId, List<Map<String, String>> items) async {
    if (items.isEmpty) return {'added': 0, 'duplicates': 0};
    
    final userResponse = await _supabase.from('call_lists').select('user_id').eq('id', listId).single();
    final userId = userResponse['user_id'];
    
    final existingItems = await _supabase
        .from('call_list_items')
        .select('phone')
        .filter('list_id', 'in', 
          _supabase.from('call_lists').select('id').eq('user_id', userId)
        );
    
    final Set<String> globalPhones = (existingItems as List).map((e) => e['phone'] as String).toSet();
    
    List<Map<String, dynamic>> toInsert = [];
    int duplicateCount = 0;
    Set<String> localPhones = {};

    for (var item in items) {
      String phone = _normalizePhoneNumber(item['phone'] ?? '');
      if (phone.isEmpty) continue;

      if (globalPhones.contains(phone) || localPhones.contains(phone)) {
        duplicateCount++;
        continue;
      }

      localPhones.add(phone);
      toInsert.add({
        'list_id': listId,
        'name': item['name'] ?? 'Unknown',
        'phone': phone,
        'status': 'pending',
      });
    }

    if (toInsert.isNotEmpty) {
      await _supabase.from('call_list_items').insert(toInsert);
    }
    
    return {'added': toInsert.length, 'duplicates': duplicateCount};
  }

  Future<void> updateItemStatus(String itemId, String status, {String? notes}) async {
    await _supabase.from('call_list_items').update({
      'status': status,
      if (notes != null) 'notes': notes,
      'updated_at': DateTime.now().toIso8601String()
    }).eq('id', itemId);
  }

  String _normalizePhoneNumber(String raw) {
    if (raw.trim().isEmpty) return '';
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    final egyptianPattern = RegExp(r'(01[0125]\d{8})');
    final match = egyptianPattern.firstMatch(digits);
    if (match != null) return match.group(0)!;
    final missingZeroPattern = RegExp(r'(1[0125]\d{8})');
    final matchMissingZero = missingZeroPattern.firstMatch(digits);
    if (matchMissingZero != null) return '0${matchMissingZero.group(0)}';
    return '';
  }

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
            if (norm.isNotEmpty) {
              phone = norm;
            } else if (val.length > 2 && val.length < 30 && int.tryParse(val) == null) {
              name = val;
            }
          }
          if (phone.isNotEmpty) entries.add({'phone': phone, 'name': name});
        }
      }
      return entries;
    } catch (e) { throw Exception('Excel Import Error: $e'); }
  }

  Future<List<String>> extractNumbersFromImage(File imageFile) async {
    final textRecognizer = TextRecognizer();
    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(InputImage.fromFile(imageFile));
      final Set<String> numbers = {};
      for (var block in recognizedText.blocks) {
        for (var line in block.lines) {
          String cleanLine = line.text.replaceAll(RegExp(r'\D'), '');
          String norm = _normalizePhoneNumber(cleanLine);
          if (norm.isNotEmpty) numbers.add(norm);
        }
      }
      return numbers.toList();
    } finally {
      textRecognizer.close();
    }
  }

  Future<void> deleteCallList(String listId) async {
    await _supabase.from('call_lists').delete().eq('id', listId);
  }

  Future<int> getTotalCallsToday() async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final response = await _supabase.from('call_list_items').select('id').not('status', 'eq', 'pending').gte('updated_at', today);
      return (response as List).length;
    } catch (e) { return 0; }
  }
}
