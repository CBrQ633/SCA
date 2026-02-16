import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/services/models.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'models/call_list_model.dart';

class CallsRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get user's call lists
  Future<List<CallList>> getUserCallLists(String userId) async {
    try {
      final response = await _supabase
          .from('call_lists')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => CallList.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch call lists: $e');
    }
  }

  // Create new call list
  Future<CallListModel> createList(String name, String userId) async {
    try {
      // Explicitly select columns to avoid stale cache issues with 'status'
      final response = await _supabase
          .from('call_lists')
          .insert({
            'user_id': userId,
            'name': name,
          })
          .select('id, user_id, name, created_at')
          .single();

      return CallListModel.fromJson(response);
    } catch (e) {
      // If select failed because we missed a column or schema is different
      if (e is PostgrestException) {
        // Try a broad select as last resort if explicit fails, or just rethrow
        rethrow;
      }
      throw Exception('Failed to create call list: $e');
    }
  }

  // Get entries for a list
  Future<List<CallEntry>> getCallEntries(String listId) async {
    try {
      final response = await _supabase
          .from('call_entries')
          .select()
          .eq('list_id', listId)
          .order('position', ascending: true);

      return (response as List)
          .map((json) => CallEntry.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch call entries: $e');
    }
  }

  // Add entry to list
  Future<void> addCallEntry({
    required String listId,
    required String phoneNumber,
    String? customerName,
    required int position,
  }) async {
    try {
      await _supabase.from('call_entries').insert({
        'list_id': listId,
        'phone_number': phoneNumber,
        'customer_name': customerName,
        'position': position,
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to add call entry: $e');
    }
  }

  // Update call status
  Future<void> updateCallStatus({
    required String entryId,
    required String status,
  }) async {
    try {
      await _supabase.from('call_entries').update({
        'status': status,
        'called_at': DateTime.now().toIso8601String(),
      }).eq('id', entryId);
    } catch (e) {
      throw Exception('Failed to update call status: $e');
    }
  }

  // Helper: Normalize phone numbers (e.g. add leading zero to Egyptian numbers)
  String _normalizePhoneNumber(String raw) {
    if (raw.trim().isEmpty) return '';

    // 1. Clean input: keep digits and '+' only
    // Handle scientific notation from Excel (e.g., 1.01E9) if it slipped through as string
    if (raw.toUpperCase().contains('E')) {
      try {
        final doubleVal = double.parse(raw);
        raw = doubleVal.toStringAsFixed(0);
      } catch (_) {}
    }

    // Remove decimals like .0
    if (raw.endsWith('.0')) {
      raw = raw.substring(0, raw.length - 2);
    }

    String clean = raw.replaceAll(RegExp(r'[^\d+]'), '');

    // 2. Handle International Egyptian format (+20 or 20 starting with 1)
    if (clean.startsWith('+20')) {
      clean = clean.substring(3); // Remove +20 -> 10xxxxxxxxx
      return '0$clean'; // Add 0 -> 010xxxxxxxxx
    } else if (clean.startsWith('20') && clean.length > 10) {
      // Catch 2010... but avoid 20... (short numbers)
      if (clean.startsWith('201')) {
        clean = clean.substring(2); // Remove 20 -> 10xxxxxxxxx
        return '0$clean'; // Add 0 -> 010xxxxxxxxx
      }
    }

    // 3. Handle Egyptian Numbers missing leading zero (common in Excel/OCR)
    // Case: "10xxxxxxxxx" (10 digits) -> "010xxxxxxxxx"
    if (clean.length == 10) {
      if (clean.startsWith('10') ||
          clean.startsWith('11') ||
          clean.startsWith('12') ||
          clean.startsWith('15')) {
        return '0$clean';
      }
    }

    // 4. Case: "010xxxxxxxxx" (11 digits) - already correct, just ensure it's clean
    if (clean.length == 11 &&
        (clean.startsWith('010') ||
            clean.startsWith('011') ||
            clean.startsWith('012') ||
            clean.startsWith('015'))) {
      return clean;
    }

    return clean;
  }

  // Import from Excel/CSV - Scans ENTIRE sheet for numbers using spreadsheet_decoder
  Future<List<Map<String, String>>> importFromExcel(File file) async {
    try {
      final bytes = file.readAsBytesSync();
      // Use SpreadsheetDecoder which is more robust than 'excel' package
      final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: true);

      final List<Map<String, String>> entries = [];
      // Regex allows digits and optional leading plus
      final RegExp phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');

      for (var table in decoder.tables.keys) {
        final sheet = decoder.tables[table];
        if (sheet == null || sheet.maxRows == 0) continue;

        for (var row in sheet.rows) {
          if (row.isEmpty) continue;

          String foundPhone = '';
          String foundName = 'Unknown';
          int longestTextLen = 0;
          bool foundStrictPhone = false;

          // Pass 1: Scan all cells in the row
          for (var cell in row) {
            if (cell == null) continue;
            String val = cell.toString().trim();

            if (val.isEmpty) continue;

            // Normalization attempt for this cell
            String processedPhone = _normalizePhoneNumber(val);

            // Check if it matches Egyptian pattern explicitly
            bool isEgyptian = false;
            // Check normalized version
            if (processedPhone.length == 11 &&
                (processedPhone.startsWith('010') ||
                    processedPhone.startsWith('011') ||
                    processedPhone.startsWith('012') ||
                    processedPhone.startsWith('015'))) {
              isEgyptian = true;
            }

            // Decision Logic
            if (isEgyptian) {
              // Priority 1: Found a strict Egyptian number
              foundPhone = processedPhone;
              foundStrictPhone = true;
            } else if (!foundStrictPhone) {
              // Priority 2: Generic number check (if we haven't found an Egyptian one yet)
              if (processedPhone.length >= 8 &&
                  phoneRegex.hasMatch(processedPhone)) {
                // If we found something that looks like a phone, keep it
                // But if we already have a candidate, we might want to be careful
                // For now, first valid phone wins if not Egyptian
                if (foundPhone.isEmpty) {
                  foundPhone = processedPhone;
                }
              }
            }

            // Name Logic:
            // If it's NOT a phone number and it's longer than what we have, treat as Name
            // (ignoring short codes or pure numbers that aren't phones)
            if (!isEgyptian &&
                !phoneRegex.hasMatch(processedPhone) &&
                val.length > longestTextLen &&
                val.length > 2) {
              // Avoid treating "123" or generic small numbers as names
              // check if val is just digits
              if (int.tryParse(val) == null) {
                longestTextLen = val.length;
                foundName = val;
              }
            }
          }

          // If we found a valid phone number in this row, add it
          if (foundPhone.isNotEmpty) {
            // Basic validation: must be at least 10 digits/characters
            if (foundPhone.length >= 10) {
              entries.add({
                'phone': foundPhone,
                'name': foundName,
              });
            }
          }
        }
      }

      return entries;
    } catch (e, stackTrace) {
      throw Exception(
          'Failed to import from Excel: $e. StackTrace: $stackTrace');
    }
  }

  // Extract numbers from image using OCR
  Future<List<String>> extractNumbersFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer();

      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      // Extract phone numbers: look for sequences of digits
      // Regex: 8 to 15 digits, allowing for spaces/dashes
      final phoneRegex = RegExp(r'(\+?\d[\d\s-]{7,15}\d)');
      final List<String> numbers = [];

      for (var block in recognizedText.blocks) {
        for (var line in block.lines) {
          final matches = phoneRegex.allMatches(line.text);

          for (var match in matches) {
            final raw = match.group(0);
            if (raw == null) continue;

            final normalized = _normalizePhoneNumber(raw);

            // Validation: 10-15 digits
            if (normalized.length >= 10 && normalized.length <= 15) {
              // Avoid duplicates if needed, or just add
              if (!numbers.contains(normalized)) {
                numbers.add(normalized);
              }
            }
          }
        }
      }

      textRecognizer.close();
      return numbers;
    } catch (e) {
      throw Exception('Failed to extract numbers from image: $e');
    }
  }

  // Delete call list
  Future<void> deleteCallList(String listId) async {
    try {
      await _supabase.from('call_lists').delete().eq('id', listId);
    } catch (e) {
      throw Exception('Failed to delete call list: $e');
    }
  }

  // --- COMPATIBILITY METHODS FOR CallRepository ---

  // Get items in a list
  Future<List<CallListItemModel>> getListItems(String listId) async {
    final response = await _supabase
        .from('call_list_items')
        .select()
        .eq('list_id', listId)
        .order('status', ascending: true) // pending -> called
        .order('created_at', ascending: true);

    return (response as List)
        .map((e) => CallListItemModel.fromJson(e))
        .toList();
  }

  // Add multiple items to list
  Future<void> addItemsToList(
      String listId, List<Map<String, String>> items) async {
    if (items.isEmpty) return;

    final data = items
        .map((item) => {
              'list_id': listId,
              'name': item['name'],
              'phone': item['phone'],
              'status': 'pending',
            })
        .toList();

    await _supabase.from('call_list_items').insert(data);
  }

  // ALIASES FOR COMPATIBILITY
  Future<List<CallListModel>> getMyLists() async {
    final response = await _supabase
        .from('call_lists')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((e) => CallListModel.fromJson(e)).toList();
  }

  // DEPRECATED: use unified createList instead
  // Future<CallListModel> createList(String name, String userId) ...

  Future<void> updateItemStatus(String itemId, String status,
      {String? notes}) async {
    final updates = {
      'status': status,
      if (notes != null) 'notes': notes,
    };
    await _supabase.from('call_list_items').update(updates).eq('id', itemId);
  }

  // --- STATS METHODS FOR DASHBOARD ---
  Future<int> getTotalCallsToday() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final response = await _supabase
        .from('call_list_items')
        .select('id')
        .not('status', 'eq', 'pending')
        .gte('updated_at',
            today); // Assuming updated_at exists or using another field
    return (response as List).length;
  }
}
