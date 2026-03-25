import 'dart:io';
import 'package:flutter/material.dart';
import '../data/calls_repository.dart';
import '../data/models/call_list_model.dart';

class CallsProvider extends ChangeNotifier {
  final CallsRepository _repository = CallsRepository();

  List<CallListModel> _lists = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _lastImportSummary;

  List<CallListModel> get lists => _lists;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get lastImportSummary => _lastImportSummary;

  Future<void> loadLists() async {
    _setLoading(true);
    try {
      final activeLists = await _repository.getMyLists(archived: false);
      final archivedLists = await _repository.getMyLists(archived: true);
      _lists = [...activeLists, ...archivedLists];
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createList(String name, String userId) async {
    if (userId.isEmpty) {
      _errorMessage = "User ID is missing. Please re-login.";
      notifyListeners();
      return false;
    }
    _setLoading(true);
    try {
      await _repository.createList(name, userId);
      await loadLists();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleArchive(String listId, bool shouldArchive) async {
    try {
      await _repository.toggleArchive(listId, shouldArchive);
      await loadLists();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteList(String listId) async {
    try {
      await _repository.deleteCallList(listId);
      _lists.removeWhere((l) => l.id == listId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete list: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> importFromExcel(File file, String userId) async {
    _setLoading(true);
    _lastImportSummary = null;
    try {
      final importedItems = await _repository.importFromExcel(file);
      if (importedItems.isNotEmpty) {
        final fileName = file.path.split(Platform.pathSeparator).last.split('.').first;
        final listName = 'Excel: $fileName';
        final newList = await _repository.createList(listName, userId);

        final itemsToInsert = importedItems.map((e) => {
          'name': e['name'] ?? 'Unknown',
          'phone': e['phone'] ?? '',
        }).toList();

        final result = await _repository.addItemsToList(newList.id, itemsToInsert);
        _lastImportSummary = {
          'added': result['added'],
          'duplicates': result['duplicates'],
          'total': importedItems.length,
          'listName': listName,
        };
        await loadLists();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> importFromImage(File file, String userId) async {
    _setLoading(true);
    _lastImportSummary = null;
    try {
      final numbers = await _repository.extractNumbersFromImage(file);
      if (numbers.isNotEmpty) {
        final listName = 'Image OCR: ${DateTime.now().hour}:${DateTime.now().minute}';
        final newList = await _repository.createList(listName, userId);

        final itemsToInsert = numbers.map((phone) => {
          'name': 'Extracted Contact',
          'phone': phone,
        }).toList();

        final result = await _repository.addItemsToList(newList.id, itemsToInsert);
        _lastImportSummary = {
          'added': result['added'],
          'duplicates': result['duplicates'],
          'total': numbers.length,
          'listName': listName,
        };
        await loadLists();
      } else {
        _errorMessage = 'No phone numbers found in image';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearSummary() {
    _lastImportSummary = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
