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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final callsProvider = context.watch<CallsProvider>();

    // ✅ Listen for import results to show the summary dialog
    if (callsProvider.lastImportSummary != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showImportSummary(context, callsProvider.lastImportSummary!);
      });
    }

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
            Tab(text: 'Active / الحالية', icon: Icon(Icons.list_alt_rounded, size: 20)),
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
    final theme = Theme.of(context);
    final filteredLists = provider.lists.where((l) => isArchived ? l.status == 'archived' : l.status == 'active').toList();

    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    if (filteredLists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isArchived ? Icons.inventory_2_outlined : Icons.contact_phone_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(isArchived ? 'No archived lists' : 'No active lists', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredLists.length,
      itemBuilder: (context, index) {
        final list = filteredLists[index];
        final bool isCompleted = list.progress >= 1.0;

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
              await context.read<CallsProvider>().toggleArchive(list.id, !isArchived);
              return true;
            } else {
              return await _confirmDelete(list.id, list.name);
            }
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: InkWell(
              onTap: () => context.push('${AppConstants.routeHome}/${list.id}'),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: (isCompleted ? Colors.green : theme.colorScheme.primary).withOpacity(0.1),
                          child: Icon(
                            isCompleted ? Icons.check_circle_rounded : Icons.list_alt_rounded, 
                            color: isCompleted ? Colors.green : theme.colorScheme.primary
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(list.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(
                                '${list.totalItems} contacts • ${list.createdAt.toString().substring(0, 10)}',
                                style: TextStyle(fontSize: 12, color: theme.hintColor),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: list.progress,
                              minHeight: 8,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCompleted ? Colors.green : theme.colorScheme.secondary
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(list.progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            color: isCompleted ? Colors.green : theme.colorScheme.secondary
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
      if (img != null) {
        await callsProvider.importFromImage(File(img.path), userId);
      }
    } else {
      FilePickerResult? res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
      if (res != null) {
        await callsProvider.importFromExcel(File(res.files.single.path!), userId);
      }
    }
  }
}
