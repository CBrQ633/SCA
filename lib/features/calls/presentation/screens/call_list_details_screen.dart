import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
  
  String _searchQuery = '';
  String _selectedFilter = 'all'; 
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<CallListItemModel> get _filteredItems {
    return _items.where((item) {
      final matchesSearch = (item.name?.toLowerCase() ?? '').contains(_searchQuery.toLowerCase()) || 
                           item.phone.contains(_searchQuery);
      final matchesFilter = _selectedFilter == 'all' || item.status == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _exportToExcel() async {
    final itemsToExport = _filteredItems;
    if (itemsToExport.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      var excel = excel_lib.Excel.createExcel();
      excel_lib.Sheet sheetObject = excel['Call Report'];
      excel.delete('Sheet1');

      sheetObject.appendRow([
        excel_lib.TextCellValue('Index'),
        excel_lib.TextCellValue('Name'),
        excel_lib.TextCellValue('Phone'),
        excel_lib.TextCellValue('Status'),
        excel_lib.TextCellValue('Notes'),
        excel_lib.TextCellValue('Date'),
      ]);

      for (int i = 0; i < itemsToExport.length; i++) {
        final item = itemsToExport[i];
        sheetObject.appendRow([
          excel_lib.IntCellValue(i + 1),
          excel_lib.TextCellValue(item.name ?? 'Unknown'),
          excel_lib.TextCellValue(item.phone),
          excel_lib.TextCellValue(item.status),
          excel_lib.TextCellValue(item.notes ?? ''),
          excel_lib.TextCellValue(item.createdAt.toString().substring(0, 16)),
        ]);
      }

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/Call_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final fileBytes = excel.save();
      
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        await Share.shareXFiles([XFile(filePath)], text: 'SCA Call Report');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- NEW EXCEL IMPORT DIALOG ---
  Future<void> _showExcelPreview(List<List<dynamic>> rows) async {
    int nameCol = 0;
    int phoneCol = 0;
    
    // Heuristic: try to find phone column (contains digits)
    for (int i = 0; i < rows[0].length; i++) {
      String val = rows[0][i]?.toString() ?? '';
      if (RegExp(r'\d{8,}').hasMatch(val)) {
        phoneCol = i;
        break;
      }
    }
    nameCol = phoneCol == 0 ? 1 : 0;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Excel Preview / معاينة البيانات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select columns for Name and Phone:', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              _buildColumnSelector('Name Column / عمود الاسم', nameCol, rows[0], (val) => setDialogState(() => nameCol = val!)),
              const SizedBox(height: 12),
              _buildColumnSelector('Phone Column / عمود الرقم', phoneCol, rows[0], (val) => setDialogState(() => phoneCol = val!)),
              const Divider(height: 32),
              const Text('Data Preview (First 3 rows):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: rows.take(3).map((row) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(child: Text(row.length > nameCol ? row[nameCol].toString() : '-', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(row.length > phoneCol ? row[phoneCol].toString() : '-', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.red))),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final processed = _repository.processExcelData(rows, nameCol, phoneCol);
                if (processed.isNotEmpty) {
                  setState(() => _isLoading = true);
                  await _repository.addItemsToList(widget.listId, processed);
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${processed.length} contacts')));
                    _loadItems();
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
                child: Text('Column ${index + 1}: ${headers[index].toString().take(15)}', style: const TextStyle(fontSize: 13)),
              )),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _importExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'ods'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        setState(() => _isLoading = true);
        final rows = await _repository.readExcelRows(file);
        setState(() => _isLoading = false);
        
        if (rows.isNotEmpty) {
          await _showExcelPreview(rows);
        } else {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel file is empty')));
        }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredItems;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts / جهات الاتصال'),
        actions: [
          IconButton(
            tooltip: 'Export to Excel',
            icon: const Icon(Icons.download_for_offline_rounded, color: Colors.green),
            onPressed: filtered.isEmpty ? null : _exportToExcel,
          ),
          IconButton(
            tooltip: 'Import from Excel',
            icon: const Icon(Icons.upload_file_rounded),
            onPressed: _importExcel,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          }) 
                        : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      _buildFilterChip('Pending', 'pending'),
                      _buildFilterChip('Called', 'called'),
                      _buildFilterChip('No Answer', 'no_answer'),
                      _buildFilterChip('WhatsApp', 'whatsapp'),
                    ],
                  ),
                ),
                if (_items.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppLogo(size: 80, showText: false),
                          const SizedBox(height: 24),
                          const Text('No contacts yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Import Excel'),
                            onPressed: _importExcel,
                          ),
                        ],
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  const Expanded(child: Center(child: Text('No results match your search')))
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return FadeInUp(
                          duration: const Duration(milliseconds: 300),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                if (_items.isNotEmpty && _searchQuery.isEmpty && _selectedFilter == 'all')
                  FadeInUp(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          const Icon(Icons.flash_on_rounded, color: Colors.amber),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('Start session?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ElevatedButton(
                            onPressed: () async {
                              await context.push('/calls/${widget.listId}/process');
                              _loadItems();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary, foregroundColor: Colors.white),
                            child: const Text('START'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : theme.colorScheme.primary)),
        selected: isSelected,
        onSelected: (s) => setState(() => _selectedFilter = value),
        selectedColor: theme.colorScheme.primary,
        checkmarkColor: Colors.white,
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _getStatusBadge(String status, ThemeData theme) {
    Color color; IconData icon; String label;
    switch (status) {
      case 'called': color = theme.colorScheme.secondary; icon = Icons.check_circle_rounded; label = 'Done'; break;
      case 'no_answer': color = Colors.redAccent; icon = Icons.phone_missed_rounded; label = 'Missed'; break;
      case 'whatsapp': color = const Color(0xFF128C7E); icon = Icons.chat_rounded; label = 'WA'; break;
      default: color = Colors.grey; icon = Icons.hourglass_top_rounded; label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
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

extension StringExtension on String {
  String take(int n) => length <= n ? this : '${substring(0, n)}...';
}
