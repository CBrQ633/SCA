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
    // Load lists only once on init
    Future.microtask(() => context.read<CallsProvider>().loadLists());
  }

  Future<void> _handleImport(String mode) async {
    final callsProvider = context.read<CallsProvider>();
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    try {
      if (mode == 'excel') {
        FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
        if (result != null) {
          await callsProvider.importFromExcel(File(result.files.single.path!), userId);
        }
      }
      if (callsProvider.errorMessage != null) {
        if (mounted) AppNotifications.showError(context, callsProvider.errorMessage!);
        callsProvider.clearError();
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
          IconButton(icon: const Icon(Icons.refresh_rounded, color: navy), onPressed: () => context.read<CallsProvider>().loadLists()),
        ],
      ),
      body: Consumer<CallsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.lists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.contact_phone_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No call lists yet / لا توجد قوائم', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            );
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
                  leading: CircleAvatar(backgroundColor: navy, child: const Icon(Icons.list_rounded, color: Colors.white)),
                  title: Text(list.name, style: const TextStyle(fontWeight: FontWeight.bold, color: navy)),
                  subtitle: Text(list.status, style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  onTap: () => context.push('${AppConstants.routeHome}/${list.id}'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add_rounded,
        activeIcon: Icons.close_rounded,
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        overlayColor: Colors.black,
        overlayOpacity: 0.4,
        children: [
          SpeedDialChild(child: const Icon(Icons.upload_file_rounded), label: 'Import Excel', onTap: () => _handleImport('excel')),
          SpeedDialChild(child: const Icon(Icons.camera_alt_rounded), label: 'OCR Import', onTap: () => _handleImport('image')),
        ],
      ),
    );
  }
}
