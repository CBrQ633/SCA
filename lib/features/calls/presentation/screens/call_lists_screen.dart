import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    Future.microtask(() => context.read<CallsProvider>().loadLists());
  }

  Future<void> _handleOCR(ImageSource source) async {
    final callsProvider = context.read<CallsProvider>();
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      if (mounted) {
        AppNotifications.showSuccess(context, 'Processing image... / جاري معالجة الصورة');
        await callsProvider.importFromImage(File(image.path), userId);
        if (callsProvider.errorMessage != null) {
          AppNotifications.showError(context, callsProvider.errorMessage!);
          callsProvider.clearError();
        } else {
          AppNotifications.showSuccess(context, 'Success! List created / تم إنشاء القائمة بنجاح');
        }
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('Select Source / اختر المصدر', style: TextStyle(fontWeight: FontWeight.bold))),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Camera / كاميرا'),
              onTap: () { Navigator.pop(context); _handleOCR(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Gallery (Screenshot) / الاستوديو'),
              onTap: () { Navigator.pop(context); _handleOCR(ImageSource.gallery); },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImport(String mode) async {
    if (mode == 'image') {
      _showImageSourceDialog();
      return;
    }

    final callsProvider = context.read<CallsProvider>();
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
      if (result != null) {
        await callsProvider.importFromExcel(File(result.files.single.path!), userId);
        if (callsProvider.errorMessage != null) {
          if (mounted) AppNotifications.showError(context, callsProvider.errorMessage!);
          callsProvider.clearError();
        }
      }
    } catch (e) {
      if (mounted) AppNotifications.showError(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Call Lists / قوائم الاتصال', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.sync_rounded), onPressed: () => context.read<CallsProvider>().loadLists()),
        ],
      ),
      body: Consumer<CallsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.lists.isEmpty) {
            return const Center(child: Text('No lists found / لا توجد قوائم', style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.lists.length,
            itemBuilder: (context, index) {
              final list = provider.lists[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: navy, child: Icon(Icons.list_alt_rounded, color: Colors.white)),
                  title: Text(list.name, style: const TextStyle(fontWeight: FontWeight.bold, color: navy)),
                  subtitle: Text(list.status, style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('${AppConstants.routeHome}/${list.id}'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add_rounded,
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        children: [
          SpeedDialChild(child: const Icon(Icons.upload_file_rounded), label: 'Excel Import', onTap: () => _handleImport('excel')),
          SpeedDialChild(child: const Icon(Icons.camera_alt_rounded), label: 'Image OCR', onTap: () => _handleImport('image')),
        ],
      ),
    );
  }
}
