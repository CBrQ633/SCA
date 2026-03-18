import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:animate_do/animate_do.dart';
import '../calls_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/components/scaffold_with_nav_bar.dart';
import 'package:go_router/go_router.dart';
import '../../calls/data/calls_repository.dart';

class CallListsScreen extends StatefulWidget {
  const CallListsScreen({super.key});

  @override
  State<CallListsScreen> createState() => _CallListsScreenState();
}

class _CallListsScreenState extends State<CallListsScreen> with SingleTickerProviderStateMixin {
  final CallsRepository _repository = CallsRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallsProvider>().loadLists();
    });
  }

  void _showImportSummary(BuildContext context, Map<String, dynamic> summary) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 12),
            const Text('Import Complete', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('List: ${summary['listName']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            _buildSummaryRow(Icons.person_add_alt_1_rounded, 'New Contacts Added:', '${summary['added']}', Colors.green),
            const SizedBox(height: 12),
            _buildSummaryRow(Icons.copy_rounded, 'Duplicates Skipped:', '${summary['duplicates']}', Colors.orange),
            const Divider(height: 32),
            Text('Total processed: ${summary['total']}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CallsProvider>().clearSummary();
            },
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  // --- OCR PREVIEW ---
  Future<void> _showOCRPreview(List<String> foundNumbers, String userId) async {
    List<String> numbers = List.from(foundNumbers);
    final listNameController = TextEditingController(
      text: 'Image OCR: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}'
    );
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Review OCR / مراجعة الأرقام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: listNameController,
                    decoration: InputDecoration(
                      labelText: 'List Name / اسم القائمة',
                      prefixIcon: const Icon(Icons.edit_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('We found ${numbers.length} numbers.', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: numbers.length,
                      itemBuilder: (c, i) => Card(
                        child: ListTile(
                          dense: true,
                          title: Text(numbers[i], style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                            onPressed: () => setState(() => numbers.removeAt(i)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: numbers.isEmpty ? null : () async {
                final name = listNameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                final newList = await _repository.createList(name, userId);
                final itemsToInsert = numbers.map((p) => {'name': 'Extracted', 'phone': p}).toList();
                await _repository.addItemsToList(newList.id, itemsToInsert);
                context.read<CallsProvider>().loadLists();
              },
              child: const Text('SAVE LIST'),
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW: EXCEL IMPORT PREVIEW WITH NAME EDITING ---
  Future<void> _showExcelImportPreview(List<List<dynamic>> rows, String fileName, String userId) async {
    int nameCol = 0;
    int phoneCol = 0;
    final listNameController = TextEditingController(text: 'Excel: $fileName');
    
    // Heuristic for default columns
    if (rows.isNotEmpty) {
      for (int i = 0; i < rows[0].length; i++) {
        String val = rows[0][i]?.toString() ?? '';
        if (RegExp(r'\d{8,}').hasMatch(val)) {
          phoneCol = i;
          break;
        }
      }
      nameCol = phoneCol == 0 ? 1 : 0;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Excel Import / استيراد إكسيل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: listNameController,
                  decoration: InputDecoration(
                    labelText: 'List Name / اسم القائمة',
                    prefixIcon: const Icon(Icons.edit_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                _buildColumnSelector('Name Column / عمود الاسم', nameCol, rows[0], (val) => setDialogState(() => nameCol = val!)),
                const SizedBox(height: 12),
                _buildColumnSelector('Phone Column / عمود الرقم', phoneCol, rows[0], (val) => setDialogState(() => phoneCol = val!)),
                const Divider(height: 32),
                const Text('Preview:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: rows.take(3).map((row) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text(row.length > nameCol ? row[nameCol].toString() : '-', style: const TextStyle(fontSize: 11))),
                          const SizedBox(width: 8),
                          Expanded(child: Text(row.length > phoneCol ? row[phoneCol].toString() : '-', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                final name = listNameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                
                final provider = context.read<CallsProvider>();
                final processed = _repository.processExcelData(rows, nameCol, phoneCol);
                
                if (processed.isNotEmpty) {
                  final newList = await _repository.createList(name, userId);
                  final result = await _repository.addItemsToList(newList.id, processed);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Created "$name" with ${result['added']} contacts')));
                  provider.loadLists();
                }
              },
              child: const Text('IMPORT NOW'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnSelector(String label, int current, List<dynamic> headers, ValueChanged<int?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: current,
              isExpanded: true,
              items: List.generate(headers.length, (index) => DropdownMenuItem(
                value: index,
                child: Text('Col ${index + 1}: ${headers[index].toString().substring(0, headers[index].toString().length > 15 ? 15 : headers[index].toString().length)}', style: const TextStyle(fontSize: 13)),
              )),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final callsProvider = context.watch<CallsProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Management', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => callsProvider.loadLists()),
        ],
      ),
      body: callsProvider.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildListContent(callsProvider, theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateListDialog(context, userId),
        label: const Text('New List'),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildListContent(CallsProvider provider, ThemeData theme) {
    if (provider.lists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contact_phone_outlined, size: 80, color: theme.colorScheme.primary.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text('No call lists yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateListDialog(context, provider.lists.firstOrNull?.userId ?? ''), 
              icon: const Icon(Icons.add),
              label: const Text('Create your first list'),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.lists.length,
      itemBuilder: (context, index) {
        final list = provider.lists[index];
        return FadeInLeft(
          delay: Duration(milliseconds: index * 50),
          child: _buildListCard(list, theme, provider),
        );
      },
    );
  }

  Widget _buildListCard(CallListModel list, ThemeData theme, CallsProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/calls/${list.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.list_alt_rounded, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(list.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${list.totalItems} contacts', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (ctx) => [
                      PopupMenuItem(value: 'archive', child: Text(list.status == 'active' ? 'Archive' : 'Activate')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                    onSelected: (val) {
                      if (val == 'archive') provider.toggleArchive(list.id, list.status == 'active');
                      if (val == 'delete') _confirmDelete(list, provider);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: list.progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(list.progress * 100).toInt()}% Completed', style: TextStyle(fontSize: 12, color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                  _buildImportButtons(list.id, provider.lists.isEmpty ? '' : provider.lists.first.userId),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportButtons(String listId, String userId) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.blueGrey),
          onPressed: () => _handleImport(true, userId),
          tooltip: 'OCR from Image',
        ),
        IconButton(
          icon: const Icon(Icons.upload_file_rounded, size: 20, color: Colors.blueGrey),
          onPressed: () => _handleImport(false, userId),
          tooltip: 'Import Excel',
        ),
      ],
    );
  }

  Future<void> _handleImport(bool isImage, String userId) async {
    if (isImage) {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.gallery);
      if (img != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scanning image...')));
        final numbers = await _repository.extractNumbersFromImage(File(img.path));
        if (numbers.isNotEmpty) {
          await _showOCRPreview(numbers, userId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No numbers found!')));
        }
      }
    } else {
      FilePickerResult? res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
      if (res != null) {
        final file = File(res.files.single.path!);
        final fileName = res.files.single.name.split('.').first;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reading Excel file...')));
        final rows = await _repository.readExcelRows(file);
        if (rows.isNotEmpty) {
          await _showExcelImportPreview(rows, fileName, userId);
        }
      }
    }
  }

  void _showCreateListDialog(BuildContext context, String userId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Call List'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Enter list name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _repository.createList(controller.text, userId);
                Navigator.pop(ctx);
                context.read<CallsProvider>().loadLists();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(CallListModel list, CallsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete List?'),
        content: Text('Are you sure you want to delete "${list.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteList(list.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
