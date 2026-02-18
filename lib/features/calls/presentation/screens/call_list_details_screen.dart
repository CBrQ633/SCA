import 'dart:io';

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
        allowedExtensions: ['xlsx', 'xls', 'ods'],
      );

      if (result != null) {
        setState(() => _isLoading = true);

        final file = File(result.files.single.path!);

        // Use repository to import (it now uses spreadsheet_decoder which is safer)
        final importedItems = await _repository.importFromExcel(file);

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
                        onPressed: () async {
                          // Navigate to Calling Mode and refresh on return
                          await context.push('/calls/${widget.listId}/process');
                          if (mounted) _loadItems();
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
