import 'package:hive/hive.dart';

class TemplateService {
  static final TemplateService _instance = TemplateService._internal();
  factory TemplateService() => _instance;
  TemplateService._internal();

  final Box<String> _templateBox = Hive.box<String>('whatsapp_templates');

  List<String> getTemplates() {
    return _templateBox.values.toList();
  }

  Future<void> addTemplate(String text) async {
    if (text.trim().isNotEmpty) {
      await _templateBox.add(text.trim());
    }
  }

  Future<void> deleteTemplate(int index) async {
    await _templateBox.deleteAt(index);
  }

  Future<void> updateTemplate(int index, String text) async {
    await _templateBox.putAt(index, text.trim());
  }

  // Pre-seed default templates if empty
  Future<void> seedDefaults() async {
    if (_templateBox.isEmpty) {
      await addTemplate("تشرفت بالاتصال بك، بخصوص العرض الذي تكلمنا عنه.");
      await addTemplate("حاولت الاتصال بك ولم نتمكن من الوصول إليك، يرجى التواصل معنا.");
      await addTemplate("شكراً لاهتمامك، إليك تفاصيل المنتج والكتالوج.");
    }
  }
}
