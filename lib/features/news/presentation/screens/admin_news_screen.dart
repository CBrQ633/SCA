import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/services/models.dart';
import '../../data/news_repository.dart';
import '../../../auth/presentation/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  final NewsRepository _repository = NewsRepository();
  List<NewsAnnouncement> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final news = await _repository.getAllAnnouncements();
      if (mounted) {
        setState(() {
          _announcements = news;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(NewsAnnouncement item) async {
    try {
      await _repository.toggleActiveStatus(item.id, !item.isActive);
      _loadNews();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete? / حذف', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this news?\nهل أنت متأكد من حذف هذا الخبر؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.deleteAnnouncement(id);
        _loadNews();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showAddEditDialog([NewsAnnouncement? item]) {
    final titleCtrl = TextEditingController(text: item?.title);
    final contentCtrl = TextEditingController(text: item?.content);
    DateTime? selectedExpiryDate = item?.expiryDate;
    List<File> pickedImages = [];
    List<String> currentImageUrls = List<String>.from(item?.imageUrls ?? []);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(item == null ? 'New News / خبر جديد' : 'Edit News / تعديل خبر'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title / العنوان', filled: true, fillColor: Color(0xFFF1F5F9)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentCtrl,
                    decoration: const InputDecoration(labelText: 'Content / المحتوى', filled: true, fillColor: Color(0xFFF1F5F9)),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  // Expiry
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(selectedExpiryDate == null ? 'Set Expiry (Optional)' : 'Expires: ${DateFormat('yyyy-MM-dd').format(selectedExpiryDate!)}', style: const TextStyle(fontSize: 13)),
                    trailing: const Icon(Icons.calendar_month_rounded, color: Color(0xFF0F172A)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setDialogState(() => selectedExpiryDate = date);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Image Picker
                  const Align(alignment: Alignment.centerLeft, child: Text('Images / الصور', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...currentImageUrls.map((url) => _buildThumb(url: url, onRemove: () => setDialogState(() => currentImageUrls.remove(url)))),
                      ...pickedImages.map((file) => _buildThumb(file: file, onRemove: () => setDialogState(() => pickedImages.remove(file)))),
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final pickedFiles = await picker.pickMultiImage();
                          if (pickedFiles.isNotEmpty) {
                            setDialogState(() => pickedImages.addAll(pickedFiles.map((f) => File(f.path))));
                          }
                        },
                        child: Container(height: 70, width: 70, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.add_a_photo_rounded, color: Colors.blueGrey)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
              onPressed: () async {
                if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  if (item == null) {
                    final user = context.read<AuthProvider>().currentUser;
                    await _repository.createAnnouncement(title: titleCtrl.text, content: contentCtrl.text, createdBy: user!.id, expiryDate: selectedExpiryDate, imageFiles: pickedImages);
                  } else {
                    await _repository.updateAnnouncement(id: item.id, title: titleCtrl.text, content: contentCtrl.text, expiryDate: selectedExpiryDate, imageFiles: pickedImages, existingImageUrls: currentImageUrls);
                  }
                  if (mounted && context.mounted) {
                    _loadNews();
                  }
                } catch (e) {
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Publish / نشر'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumb({String? url, File? file, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(10), child: url != null ? Image.network(url, height: 70, width: 70, fit: BoxFit.cover) : Image.file(file!, height: 70, width: 70, fit: BoxFit.cover)),
        Positioned(right: 0, top: 0, child: GestureDetector(onTap: onRemove, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 12, color: Colors.white)))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0F172A);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Manage News / إدارة الأخبار', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0),
      floatingActionButton: FloatingActionButton(backgroundColor: navy, onPressed: () => _showAddEditDialog(), child: const Icon(Icons.add_rounded, color: Colors.white)),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNews,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _announcements.length,
                itemBuilder: (context, index) {
                  final item = _announcements[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        if (item.imageUrls.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: Image.network(item.imageUrls.first, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c,e,s) => const SizedBox.shrink()),
                          ),
                        ListTile(
                          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, color: navy)),
                          subtitle: Text('${DateFormat('MMMd').format(item.createdAt)} • ${item.isActive ? "Active" : "Hidden"}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: Icon(item.isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: item.isActive ? Colors.green : Colors.grey), onPressed: () => _toggleStatus(item)),
                              IconButton(icon: const Icon(Icons.edit_rounded, color: Colors.blue), onPressed: () => _showAddEditDialog(item)),
                              IconButton(icon: const Icon(Icons.delete_rounded, color: Colors.redAccent), onPressed: () => _deleteItem(item.id)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
