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

class _CallListsScreenState extends State<CallListsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => context.read<CallsProvider>().loadLists());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final callsProvider = context.watch<CallsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Management', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.sync_rounded), onPressed: () => callsProvider.loadLists()),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.secondary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Active / الحالية', icon: Icon(Icons.宅_rounded, size: 20)),
            Tab(text: 'Archived / الأرشيف', icon: Icon(Icons.archive_outlined, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(callsProvider, isArchived: false),
          _buildList(callsProvider, isArchived: true),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildList(CallsProvider provider, {required bool isArchived}) {
    // Note: Provider might need updating to handle active/archived separation
    // For now, let's assume we filter local lists if they have a status
    final filteredLists = provider.lists.where((l) => isArchived ? l.status == 'archived' : l.status == 'active').toList();

    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    if (filteredLists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isArchived ? Icons.inventory_2_outlined : Icons.contact_phone_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(isArchived ? 'No archived lists' : 'No active lists'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredLists.length,
      itemBuilder: (context, index) {
        final list = filteredLists[index];
        return Dismissible(
          key: Key(list.id),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(16)),
            child: Icon(isArchived ? Icons.unarchive : Icons.archive, color: Colors.white),
          ),
          confirmDismiss: (dir) async {
            if (dir == DismissDirection.startToEnd) {
              // Archive action
              await context.read<CallsProvider>().toggleArchive(list.id, !isArchived);
              return true;
            } else {
              // Delete action
              return await _confirmDelete(list.id, list.name);
            }
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: theme.colorScheme.primary.withOpacity(0.1), child: Icon(Icons.list_alt_rounded, color: theme.colorScheme.primary)),
              title: Text(list.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${list.createdAt.toString().substring(0, 10)} • ${list.status}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('${AppConstants.routeHome}/${list.id}'),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(String id, String name) async {
    return await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('Delete list "$name" permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      )) ?? false;
  }

  Widget _buildFab(BuildContext context) {
    return SpeedDial(
      icon: Icons.add_rounded,
      backgroundColor: const Color(0xFF10B981),
      foregroundColor: Colors.white,
      children: [
        SpeedDialChild(child: const Icon(Icons.upload_file), label: 'Excel', onTap: () => _handleImport('excel')),
        SpeedDialChild(child: const Icon(Icons.camera_alt), label: 'OCR', onTap: () => _handleImport('image')),
      ],
    );
  }

  Future<void> _handleImport(String mode) async {
    final callsProvider = context.read<CallsProvider>();
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    if (mode == 'image') {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.gallery);
      if (img != null) await callsProvider.importFromImage(File(img.path), userId);
    } else {
      FilePickerResult? res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
      if (res != null) await callsProvider.importFromExcel(File(res.files.single.path!), userId);
    }
  }
}
