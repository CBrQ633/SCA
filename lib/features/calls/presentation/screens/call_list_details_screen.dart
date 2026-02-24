import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:smart_call_assistant/features/calls/data/calls_repository.dart';
import 'package:smart_call_assistant/features/calls/data/models/call_list_model.dart';
import 'package:smart_call_assistant/core/components/app_logo.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        final importedItems = await _repository.importFromExcel(file);

        if (importedItems.isNotEmpty) {
          await _repository.addItemsToList(widget.listId, importedItems);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${importedItems.length} contacts')));
            _loadItems();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid contacts found')));
            setState(() => _isLoading = false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts / جهات الاتصال'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
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
                      const AppLogo(size: 80, showText: false),
                      const SizedBox(height: 24),
                      const Text('No contacts yet / لا توجد أسماء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Import Excel / استيراد اكسيل'),
                        onPressed: _importExcel,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Unified Action Banner
                    FadeInDown(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 28),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ready to start? / مستعد للبدء؟',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    '${_items.length} contacts loaded',
                                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await context.push('/calls/${widget.listId}/process');
                                if (mounted) _loadItems();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.secondary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('START'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return FadeInUp(
                            duration: const Duration(milliseconds: 400),
                            delay: Duration(milliseconds: 50 * index),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                  child: Text('${index + 1}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(item.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(item.phone),
                                trailing: _getStatusBadge(item.status, theme),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _getStatusBadge(String status, ThemeData theme) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'called':
        color = theme.colorScheme.secondary;
        icon = Icons.check_circle_rounded;
        label = 'Done';
        break;
      case 'no_answer':
        color = Colors.redAccent;
        icon = Icons.phone_missed_rounded;
        label = 'Missed';
        break;
      case 'whatsapp':
        color = const Color(0xFF128C7E);
        icon = Icons.chat_rounded;
        label = 'WA';
        break;
      default:
        color = Colors.grey;
        icon = Icons.hourglass_top_rounded;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
