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
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _toggleStatus(NewsAnnouncement item) async {
    try {
      await _repository.toggleActiveStatus(item.id, !item.isActive);
      _loadNews();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement?'),
        content: const Text('This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.deleteAnnouncement(id);
        _loadNews();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showAddEditDialog([NewsAnnouncement? item]) {
    final titleCtrl = TextEditingController(text: item?.title);
    final contentCtrl = TextEditingController(text: item?.content);
    List<File> pickedImages = [];
    List<String> currentImageUrls = List<String>.from(item?.imageUrls ?? []);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'إضافة خبر' : 'تعديل خبر'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'العنوان'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(labelText: 'المحتوى'),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                // Image Picker
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...currentImageUrls.map((url) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(url,
                                  height: 80, width: 80, fit: BoxFit.cover),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    currentImageUrls.remove(url);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )),
                    ...pickedImages.map((file) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(file,
                                  height: 80, width: 80, fit: BoxFit.cover),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    pickedImages.remove(file);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFiles = await picker.pickMultiImage();
                        if (pickedFiles.isNotEmpty) {
                          setDialogState(() {
                            pickedImages
                                .addAll(pickedFiles.map((f) => File(f.path)));
                          });
                        }
                      },
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: const Icon(Icons.add_a_photo,
                            size: 30, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final content = contentCtrl.text.trim();

                if (title.isEmpty || content.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('برجاء ملء جميع الحقول')),
                  );
                  return;
                }

                Navigator.pop(ctx); // Close dialog

                final messenger = ScaffoldMessenger.of(context);
                try {
                  if (item == null) {
                    // Add
                    final user = context.read<AuthProvider>().currentUser;
                    if (user == null) {
                      throw Exception('Admin user session not found');
                    }
                    await _repository.createAnnouncement(
                      title: title,
                      content: content,
                      createdBy: user.id,
                      imageFiles: pickedImages,
                    );
                  } else {
                    // Update
                    await _repository.updateAnnouncement(
                      id: item.id,
                      title: title,
                      content: content,
                      imageFiles: pickedImages,
                      existingImageUrls: currentImageUrls,
                    );
                  }
                  _loadNews();
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: Text(item == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage News')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? const Center(child: Text('No announcements found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _announcements.length,
                  itemBuilder: (context, index) {
                    final item = _announcements[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          if (item.imageUrls.isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: SizedBox(
                                height: 150,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: item.imageUrls.length,
                                  itemBuilder: (context, i) => Image.network(
                                    item.imageUrls[i],
                                    height: 150,
                                    width: MediaQuery.of(context).size.width -
                                        64, // Full width minus padding
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ),
                          ListTile(
                            title: Text(
                              item.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(
                              '${DateFormat('yyyy-MM-dd').format(item.createdAt)} • ${item.isActive ? "نشط" : "غير نشط"}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    item.isActive
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: item.isActive
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  onPressed: () => _toggleStatus(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () => _showAddEditDialog(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteItem(item.id),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
