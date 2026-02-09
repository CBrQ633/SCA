import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_call_assistant/features/calls/data/calls_repository.dart';
import 'package:smart_call_assistant/features/calls/data/models/call_list_model.dart';

// Assuming CallListItemModel is in call_list_model.dart or separate.
// If separate, need import 'package:smart_call_assistant/features/calls/data/models/call_list_item_model.dart';
// Based on previous step, it was in call_list_model.dart file content (actually I put two classes in one file in previous step 606? No, I put them in call_list_model.dart).
// Let's re-read call_list_model.dart to be sure.
// Actually I see in step 606 I put both classes in `d:\Smart Call Assistant - SCA\smart_call_assistant\lib\features\calls\data\models\call_list_model.dart`
// So the import above is correct.

class CallListDetailsScreen extends StatefulWidget {
  final String listId;
  const CallListDetailsScreen({super.key, required this.listId});

  @override
  State<CallListDetailsScreen> createState() => _CallListDetailsScreenState();
}

class _CallListDetailsScreenState extends State<CallListDetailsScreen> {
  final CallsRepository _repository = CallsRepository();
  List<CallListItemModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await _repository.getListItems(widget.listId);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _importExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        setState(() => _isLoading = true);

        final file = File(result.files.single.path!);
        final bytes = file.readAsBytesSync();
        final excel = Excel.decodeBytes(bytes);

        List<Map<String, String>> importedItems = [];

        // Regex for Egyptian phone numbers:
        // +20 followed by 10 digits, OR 01[0125] followed by 8 digits
        final egyptPhoneRegex = RegExp(r'(\+20\d{10}|0?1[0125]\d{8})');

        for (var table in excel.tables.keys) {
          for (var row in excel.tables[table]!.rows) {
            if (row.isEmpty) continue;

            // Scan ALL cells in the row for phone numbers
            for (var cell in row) {
              if (cell == null) continue;
              final cellValue = cell.value?.toString().trim() ?? '';
              if (cellValue.isEmpty) continue;

              // Clean the cell value (remove spaces, dashes, etc.)
              final cleanedValue =
                  cellValue.replaceAll(RegExp(r'[\s\-\(\)]'), '');

              // Find all Egyptian phone numbers in this cell
              final matches = egyptPhoneRegex.allMatches(cleanedValue);
              for (var match in matches) {
                String phone = match.group(0)!;

                // Normalize: ensure +20 prefix
                if (phone.startsWith('01')) {
                  phone = '+20$phone';
                } else if (phone.startsWith('1') && phone.length == 10) {
                  phone = '+20$phone';
                }

                // Avoid duplicates
                if (!importedItems.any((item) => item['phone'] == phone)) {
                  importedItems.add({'name': 'Imported', 'phone': phone});
                }
              }
            }
          }
        }

        if (importedItems.isNotEmpty) {
          await _repository.addItemsToList(widget.listId, importedItems);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Imported ${importedItems.length} contacts')));
            _loadItems();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('No valid contacts found in Excel')));
            setState(() => _isLoading = false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Import Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import Excel',
            onPressed: _importExcel,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.contacts, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No contacts in this list.'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Import from Excel'),
                        onPressed: _importExcel,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Start Calling Button (Sticky Top)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[100],
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('START CALLING'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          // Navigate to Calling Mode
                          context.push('/calls/${widget.listId}/process');
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}'),
                            ),
                            title: Text(item.name ?? 'Unknown'),
                            subtitle: Text(item.phone),
                            trailing: _getStatusIcon(item.status),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'called':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'no_answer':
        return const Icon(Icons.phone_missed, color: Colors.red);
      case 'whatsapp':
        return const Icon(Icons.chat, color: Colors.green);
      default:
        return const Icon(Icons.hourglass_empty, color: Colors.grey);
    }
  }
}
