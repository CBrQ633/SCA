import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_call_assistant/features/calls/presentation/calls_provider.dart';
import 'package:smart_call_assistant/features/auth/presentation/auth_provider.dart';
import 'package:smart_call_assistant/features/calls/data/calls_repository.dart';
import 'package:smart_call_assistant/features/calls/data/models/call_list_model.dart';

class CallListsScreen extends StatefulWidget {
  const CallListsScreen({super.key});

  @override
  State<CallListsScreen> createState() => _CallListsScreenState();
}

class _CallListsScreenState extends State<CallListsScreen> {
  final CallsRepository _repository = CallsRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallsProvider>().loadLists();
    });
  }

  // Helper to get current User ID safely
  String _getUserId() => context.read<AuthProvider>().currentUser?.id ?? '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final callsProvider = context.watch<CallsProvider>();
    final userId = _getUserId();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Management', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded), 
            onPressed: () => callsProvider.loadLists()
          ),
        ],
      ),
      body: callsProvider.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildListContent(callsProvider, theme, userId),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context, userId),
        label: const Text('Add Contacts'),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddOptions(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add New Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildActionOption(
              icon: Icons.edit_note_rounded,
              title: 'Create Manual List',
              subtitle: 'Type name and start adding numbers',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(ctx);
                _showCreateListDialog(context, userId);
              },
            ),
            const SizedBox(height: 12),
            _buildActionOption(
              icon: Icons.upload_file_rounded,
              title: 'Import from Excel',
              subtitle: 'Support .xlsx and .xls files',
              color: Colors.green,
              onTap: () {
                Navigator.pop(ctx);
                _handleImport(false, userId);
              },
            ),
            const SizedBox(height: 12),
            _buildActionOption(
              icon: Icons.camera_alt_rounded,
              title: 'Scan from Image (OCR)',
              subtitle: 'Extract numbers from photos',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(ctx);
                _handleImport(true, userId);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOption({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
    );
  }

  Widget _buildListContent(CallsProvider provider, ThemeData theme, String userId) {
    if (provider.lists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(child: Icon(Icons.contact_phone_outlined, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.2))),
              const SizedBox(height: 24),
              const Text('No call lists yet / لا توجد قوائم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              const Text('Start by creating a manual list or importing contacts from Excel/Images.', textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _showAddOptions(context, userId), 
                icon: const Icon(Icons.add),
                label: const Text('Create your first list'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              )
            ],
          ),
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
                    decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
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
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleImport(bool isImage, String userId) async {
    if (userId.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: User session expired. Please login again.')));
       return;
    }

    if (isImage) {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.gallery);
      if (img != null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scanning image...')));
        final numbers = await _repository.extractNumbersFromImage(File(img.path));
        if (numbers.isNotEmpty) {
          await _showOCRPreview(numbers, userId);
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No numbers found!')));
        }
      }
    } else {
      FilePickerResult? res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
      if (res != null) {
        final file = File(res.files.single.path!);
        final fileName = res.files.single.name.split('.').first;
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reading Excel file...')));
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
                final success = await context.read<CallsProvider>().createList(controller.text, userId);
                if (mounted && context.mounted && success) {
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // ... (keeping _showOCRPreview and _showExcelImportPreview for brevity, ensuring they use userId passed from _handleImport)
  
  Future<void> _showOCRPreview(List<String> foundNumbers, String userId) async {
    List<String> numbers = List.from(foundNumbers);
    final listNameController = TextEditingController(
      text: 'Image OCR: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}'
    );
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                            onPressed: () => setDialogState(() => numbers.removeAt(i)),
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
                final provider = context.read<CallsProvider>();
                Navigator.pop(ctx);
                try {
                  final newList = await _repository.createList(name, userId);
                  final itemsToInsert = numbers.map((p) => {'name': 'Extracted', 'phone': p}).toList();
                  final result = await _repository.addItemsToList(newList.id, itemsToInsert);
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Success! Added ${result['added']} contacts.')));
                    provider.loadLists();
                  }
                } catch (e) {
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('SAVE LIST'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExcelImportPreview(List<List<dynamic>> rows, String fileName, String userId) async {
    int nameCol = 0;
    int phoneCol = 0;
    final listNameController = TextEditingController(text: 'Excel: $fileName');
    if (rows.isNotEmpty) {
      for (int i = 0; i < rows[0].length; i++) {
        String val = rows[0][i]?.toString() ?? '';
        if (RegExp(r'\d{8,}').hasMatch(val)) {
          phoneCol = i; break;
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
                _buildColumnSelector('Name Column', nameCol, rows[0], (val) => setDialogState(() => nameCol = val!)),
                const SizedBox(height: 12),
                _buildColumnSelector('Phone Column', phoneCol, rows[0], (val) => setDialogState(() => phoneCol = val!)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                final name = listNameController.text.trim();
                if (name.isEmpty) return;
                final provider = context.read<CallsProvider>();
                Navigator.pop(ctx);
                try {
                  final dataRows = rows.length > 1 ? rows.sublist(1) : rows;
                  final processed = _repository.processExcelData(dataRows, nameCol, phoneCol);
                  if (processed.isNotEmpty) {
                    final newList = await _repository.createList(name, userId);
                    final result = await _repository.addItemsToList(newList.id, processed);
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Created "$name" with ${result['added']} contacts.')));
                      provider.loadLists();
                    }
                  }
                } catch (e) {
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
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
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: current,
              isExpanded: true,
              items: List.generate(headers.length, (index) => DropdownMenuItem(
                value: index,
                child: Text('Col ${index + 1}: ${headers[index].toString()}', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
              )),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(CallListModel list, CallsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete List?'),
        content: Text('Are you sure you want to delete "${list.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () { provider.deleteList(list.id); Navigator.pop(ctx); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
