import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_call_assistant/features/auth/presentation/auth_provider.dart';
import 'package:smart_call_assistant/features/calls/presentation/calls_provider.dart';
import 'package:smart_call_assistant/core/constants/app_constants.dart';
import '../../../../core/utils/app_notifications.dart';

class CallListsScreen extends StatefulWidget {
  const CallListsScreen({super.key});

  @override
  State<CallListsScreen> createState() => _CallListsScreenState();
}

class _CallListsScreenState extends State<CallListsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallsProvider>().loadLists();
    });
  }

  Future<void> _handleImport(String mode) async {
    final callsProvider = context.read<CallsProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    try {
      if (mode == 'excel') {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx', 'xls'],
        );
        if (result == null) return;

        final file = File(result.files.single.path!);
        await callsProvider.importFromExcel(file, userId);
      } else if (mode == 'image') {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile == null) return;

        final file = File(pickedFile.path);
        // Note: You might want to move OCR logic to provider too if not already there
        // For now, let's assume the provider handles the main flow
        AppNotifications.showInfo(context, 'Processing image... / جاري معالجة الصورة');
        // implementation for image import can be added to CallsProvider similarly
      }

      if (callsProvider.errorMessage != null) {
        if (mounted) AppNotifications.showError(context, callsProvider.errorMessage!);
        callsProvider.clearError();
      } else {
        if (mounted) AppNotifications.showSuccess(context, 'Done! / تم بنجاح');
      }
    } catch (e) {
      if (mounted) AppNotifications.showError(context, 'Error: $e');
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
          decoration: const InputDecoration(hintText: 'List Name / اسم القائمة'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final name = controller.text.trim();
                Navigator.pop(context);
                final userId = context.read<AuthProvider>().currentUser?.id;
                if (userId != null) {
                  await context.read<CallsProvider>().createEmptyList(name, userId);
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Call Lists / قوائم الاتصال'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CallsProvider>().loadLists(),
          ),
        ],
      ),
      body: Consumer<CallsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.lists.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No call lists yet / لا توجد قوائم بعد'),
                  SizedBox(height: 24),
                  Text('Try importing from Excel below / جرب استيراد ملف اكسيل'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.lists.length,
            itemBuilder: (context, index) {
              final list = provider.lists[index];
              return FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: Duration(milliseconds: 100 * index),
                child: Dismissible(
                  key: Key(list.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        content: Text('Are you sure you want to delete "${list.name}"?\nهل أنت متأكد من حذف هذه القائمة؟'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel / إلغاء'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Delete / حذف'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    await provider.deleteList(list.id);
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(list.name.isNotEmpty ? list.name[0].toUpperCase() : '?'),
                      ),
                      title: Text(list.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${list.status} • ${list.createdAt.toLocal().toString().substring(0, 10)}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => context.push('${AppConstants.routeHome}/${list.id}'),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: SpeedDial(
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
            onTap: () => _handleImport('excel'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.camera_alt),
            label: 'سحب من صورة / OCR Import',
            onTap: () => _handleImport('image'),
          ),
        ],
      ),
    );
  }
}
