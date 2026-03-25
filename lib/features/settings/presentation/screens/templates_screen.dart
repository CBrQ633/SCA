import 'package:flutter/material.dart';
import '../../../../core/services/template_service.dart';
import 'package:animate_do/animate_do.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final TemplateService _service = TemplateService();
  List<String> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  void _loadTemplates() async {
    await _service.seedDefaults(); // Seed if empty
    setState(() {
      _templates = _service.getTemplates();
    });
  }

  void _showAddEditDialog({int? index, String? initialText}) {
    final controller = TextEditingController(text: initialText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(index == null ? 'Add Template' : 'Edit Template'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter template text...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                if (index == null) {
                  await _service.addTemplate(controller.text);
                } else {
                  await _service.updateTemplate(index, controller.text);
                }
                if (mounted && context.mounted) {
                  Navigator.pop(ctx);
                  _loadTemplates();
                }
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Templates', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _templates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final text = _templates[index];
                return FadeInUp(
                  delay: Duration(milliseconds: index * 50),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(text, style: const TextStyle(fontSize: 14)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 20),
                            onPressed: () => _showAddEditDialog(index: index, initialText: text),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () async {
                              await _service.deleteTemplate(index);
                              _loadTemplates();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add_comment_rounded),
      ),
    );
  }
}
