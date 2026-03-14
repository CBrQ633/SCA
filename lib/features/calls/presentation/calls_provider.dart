import 'dart:io';
import 'package:flutter/material.dart';
import '../data/calls_repository.dart';
import '../data/models/call_list_model.dart';

class CallsProvider extends ChangeNotifier {
  final CallsRepository _repository = CallsRepository();

  List<CallListModel> _lists = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CallListModel> get lists => _lists;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadLists() async {
    _setLoading(true);
    try {
      _lists = await _repository.getMyLists();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> importFromExcel(File file, String userId) async {
    _setLoading(true);
    try {
      final importedItems = await _repository.importFromExcel(file);
      if (importedItems.isNotEmpty) {
        final listName = 'Excel: ${file.path.split('/').last.split('.').first}';
        final newList = await _repository.createList(listName, userId);

        final itemsToInsert = importedItems.map((e) => {
          'name': e['name'] ?? 'Unknown',
          'phone': e['phone'] ?? '',
        }).toList();

        await _repository.addItemsToList(newList.id, itemsToInsert);
        await loadLists();
      }
    } catch (e) {
      _errorMessage = 'Excel Error: $e';
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Added missing OCR Image Import
  Future<void> importFromImage(File file, String userId) async {
    _setLoading(true);
    try {
      final numbers = await _repository.extractNumbersFromImage(file);
      if (numbers.isNotEmpty) {
        final listName = 'Image OCR: ${DateTime.now().hour}:${DateTime.now().minute}';
        final newList = await _repository.createList(listName, userId);

        final itemsToInsert = numbers.map((phone) => {
          'name': 'Extracted Contact',
          'phone': phone,
        }).toList();

        await _repository.addItemsToList(newList.id, itemsToInsert);
        await loadLists();
      } else {
        _errorMessage = 'No phone numbers found in image / لم يتم العثور على أرقام في الصورة';
      }
    } catch (e) {
      _errorMessage = 'OCR Error: $e';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
