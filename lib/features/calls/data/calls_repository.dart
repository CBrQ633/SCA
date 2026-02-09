import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/services/models.dart';
import 'package:excel/excel.dart' as excel_lib;
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

  // Import from Excel/CSV - Scans ENTIRE sheet for numbers
  Future<List<Map<String, String>>> importFromExcel(File file) async {
    try {
      final bytes = file.readAsBytesSync();
      final excelFile = excel_lib.Excel.decodeBytes(bytes);

      final List<Map<String, String>> entries = [];
      // Regex allows digits and optional leading plus
      final RegExp phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');

      for (var table in excelFile.tables.keys) {
        final sheet = excelFile.tables[table];
        if (sheet == null || sheet.maxRows == 0) continue;

        for (var row in sheet.rows) {
          if (row.isEmpty) continue;

          String foundPhone = '';
          String foundName = 'Unknown';
          int longestTextLen = 0;
          bool foundStrictPhone = false;

          // Pass 1: Find the phone number in this row
          for (var cell in row) {
            if (cell == null || cell.value == null) continue;

            // Smart String Conversion: valid for both Text and Number cells
            String val = cell.value.toString().trim();

            // Fix: Excel might read 0101234 as 101234.0
            if (val.endsWith('.0')) {
              val = val.substring(0, val.length - 2);
            }

            if (val.isEmpty) continue;

            // Clean input: keep digits and '+' only
            // e.g., "+20-10-..." -> "+2010..."
            final cleanVal = val.replaceAll(RegExp(r'[^\d+]'), '');

            // --- SMART PARSING LOGIC ---
            String processedPhone = cleanVal;

            // Scenario 1: Egyptian number missing leading zero (Excel removed it)
            // e.g. "10xxxxxxxxx" (10 digits) -> needs to be "010xxxxxxxxx"
            if (processedPhone.length == 10) {
              if (processedPhone.startsWith('10') ||
                  processedPhone.startsWith('11') ||
                  processedPhone.startsWith('12') ||
                  processedPhone.startsWith('15')) {
                processedPhone = '0$processedPhone';
              }
            }

            // Scenario 2: Already correct Egyptian number
            // e.g. "010xxxxxxxxx" (11 digits)
            bool isEgyptian = false;
            if (processedPhone.length == 11 &&
                (processedPhone.startsWith('010') ||
                    processedPhone.startsWith('011') ||
                    processedPhone.startsWith('012') ||
                    processedPhone.startsWith('015'))) {
              isEgyptian = true;
            } else if (processedPhone.length >= 12 &&
                (processedPhone.startsWith('201') ||
                    processedPhone.startsWith('+201'))) {
              // International Egyptian format
              isEgyptian = true;
            }

            // Decision Logic
            if (isEgyptian) {
              foundPhone = processedPhone;
              foundStrictPhone = true;
            } else if (!foundStrictPhone &&
                foundPhone.isEmpty &&
                phoneRegex.hasMatch(processedPhone)) {
              // Generic number (International or other)
              foundPhone = processedPhone;
            } else {
              // If not a phone, check if it's a name (longest text)
              // Only consider it a name if it DOESN'T look like a phone number
              if (!phoneRegex.hasMatch(cleanVal) &&
                  val.length > longestTextLen) {
                longestTextLen = val.length;
                foundName = val;
              }
            }
          }

          // If we found a valid phone number in this row, add it
          if (foundPhone.isNotEmpty) {
            // Basic validation: must be at least 10 digits (01xxxxxxxxx)
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
    } catch (e) {
      throw Exception('Failed to import from Excel: $e');
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

      // Extract phone numbers using a more flexible regex (supports Egyptian & international)
      final phoneRegex = RegExp(
        r'(\+?\d{1,3}[\s-]?)?0?\d{2,3}[\s-]?\d{3,4}[\s-]?\d{3,4}',
      );
      final List<String> numbers = [];

      for (var block in recognizedText.blocks) {
        for (var line in block.lines) {
          final matches = phoneRegex.allMatches(line.text);
          for (var match in matches) {
            // Clean number: remove everything except digits and plus
            final number = match.group(0)?.replaceAll(RegExp(r'[^\d+]'), '');
            if (number != null && number.length >= 8 && number.length <= 15) {
              numbers.add(number);
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
