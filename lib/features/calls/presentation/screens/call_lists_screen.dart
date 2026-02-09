import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_call_assistant/features/auth/presentation/auth_provider.dart';
import 'package:smart_call_assistant/features/calls/data/calls_repository.dart';
import 'package:smart_call_assistant/features/calls/data/models/call_list_model.dart';
import 'package:smart_call_assistant/core/constants/app_constants.dart';
import '../../../../core/utils/app_notifications.dart';

class CallListsScreen extends StatefulWidget {
  const CallListsScreen({super.key});

  @override
  State<CallListsScreen> createState() => _CallListsScreenState();
}

class _CallListsScreenState extends State<CallListsScreen> {
  final CallsRepository _repository = CallsRepository();
  List<CallListModel> _lists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    try {
      final lists = await _repository.getMyLists();
      if (mounted) {
        setState(() {
          _lists = lists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppNotifications.showError(context, 'Error loading lists: $e');
      }
    }
  }

  Future<void> _importAndCreate(String mode) async {
    try {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId == null) return;

      List<Map<String, String>> importedItems = [];
      String listName =
          'New List ${DateTime.now().toString().substring(0, 16)}';

      if (mode == 'excel') {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx', 'xls'],
        );
        if (result == null) return;

        setState(() => _isLoading = true);
        final file = File(result.files.single.path!);
        importedItems = await _repository.importFromExcel(file);
        listName = 'Excel: ${result.files.single.name.split('.').first}';
      } else if (mode == 'image') {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile == null) return;

        setState(() => _isLoading = true);
        final file = File(pickedFile.path);
        final numbers = await _repository.extractNumbersFromImage(file);
        importedItems =
            numbers.map((n) => {'name': 'Scanned', 'phone': n}).toList();
        listName = 'Scanned: ${DateTime.now().hour}:${DateTime.now().minute}';
      }

      if (importedItems.isEmpty) {
        if (mounted) {
          AppNotifications.showError(
              context, 'No numbers found / لم يتم العثور على أرقام');
          setState(() => _isLoading = false);
        }
        return;
      }

      // 1. Create List
      final newList = await _repository.createList(listName, userId);

      // 2. Add Items (Convert to required format if needed)
      final itemsToInsert = importedItems
          .map((e) => {
                'name': e['customer_name'] ?? e['name'] ?? 'Unknown',
                'phone': e['phone_number'] ?? e['phone'] ?? '',
              })
          .toList();

      await _repository.addItemsToList(newList.id, itemsToInsert);

      if (mounted) {
        AppNotifications.showSuccess(context,
            'Imported ${itemsToInsert.length} numbers successfully!/ تم استيراد بنجاح');
        _loadLists();
      }
    } catch (e) {
      if (mounted) {
        AppNotifications.showError(context, 'Import Error: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showCreateListDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Call List / قائمة جديدة'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(hintText: 'List Name / اسم القائمة'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _createList(controller.text.trim());
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createList(String name) async {
    setState(() => _isLoading = true);
    try {
      final userId = context.read<AuthProvider>().currentUser!.id;
      await _repository.createList(name, userId);
      _loadLists();
    } catch (e) {
      if (mounted) {
        AppNotifications.showError(context, 'Error: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Call Lists / قوائم الاتصال')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lists.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No call lists yet / لا توجد قوائم بعد'),
                      SizedBox(height: 24),
                      Text(
                          'Try importing from Excel below/ جرب استيراد ملف اكسيل'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _lists.length,
                  itemBuilder: (context, index) {
                    final list = _lists[index];
                    return FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      delay: Duration(milliseconds: 100 * index),
                      child: Dismissible(
                        key: Key(list.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete List / حذف القائمة'),
                              content: Text(
                                  'Are you sure you want to delete "${list.name}"?\nهل أنت متأكد من حذف هذه القائمة؟'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel / إلغاء'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.red),
                                  child: const Text('Delete / حذف'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await _repository.deleteCallList(list.id);
                            if (!mounted) return;
                            setState(() => _lists.removeAt(index));
                            messenger.showSnackBar(const SnackBar(
                              content: Text('List deleted / تم حذف القائمة'),
                              backgroundColor: Colors.green,
                            ));
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(SnackBar(
                              content: Text('Delete failed: $e'),
                              backgroundColor: Colors.red,
                            ));
                            _loadLists();
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              child: Text(list.name.isNotEmpty
                                  ? list.name[0].toUpperCase()
                                  : '?'),
                            ),
                            title: Text(list.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                '${list.status} • ${list.createdAt.toLocal().toString().substring(0, 10)}'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => context
                                .push('${AppConstants.routeHome}/${list.id}'),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _isLoading
          ? null
          : SpeedDial(
              icon: Icons.add,
              activeIcon: Icons.close,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              overlayColor: Colors.black,
              overlayOpacity: 0.5,
              children: [
                SpeedDialChild(
                  child: const Icon(Icons.edit_note),
                  label: 'قائمة فارغة / Empty List',
                  onTap: _showCreateListDialog,
                ),
                SpeedDialChild(
                  child: const Icon(Icons.upload_file),
                  label: 'استيراد من اكسيل / Import Excel',
                  onTap: () => _importAndCreate('excel'),
                ),
                SpeedDialChild(
                  child: const Icon(Icons.camera_alt),
                  label: 'سحب من صورة / OCR Import',
                  onTap: () => _importAndCreate('image'),
                ),
              ],
            ),
    );
  }
}
