import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/calls/data/models/sync_task_model.dart';
import '../config/supabase_config.dart';
import 'notification_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final Box<SyncTaskModel> _syncBox = Hive.box<SyncTaskModel>('sync_queue');
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  bool _isSyncing = false;
  Timer? _timer;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      syncNow();
    });
    syncNow();
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> syncNow() async {
    if (_isSyncing || _syncBox.isEmpty) return;
    
    _isSyncing = true;
    int initialTasks = _syncBox.length;
    int syncedCount = 0;

    debugPrint('🔄 Syncing $initialTasks tasks...');

    final tasks = _syncBox.values.toList();
    for (var task in tasks) {
      try {
        await _supabase.from('call_list_items').update({
          'status': task.status,
          if (task.notes != null) 'notes': task.notes,
          'updated_at': DateTime.now().toIso8601String()
        }).eq('id', task.itemId);

        await _syncBox.delete(task.id);
        syncedCount++;
      } catch (e) {
        if (e.toString().contains('SocketException')) break; 
      }
    }

    if (syncedCount > 0) {
      // Notify the user that background tasks are synced
      NotificationService().showNotification(
        id: 999,
        title: 'Sync Complete / تم التحديث',
        body: 'Successfully synced $syncedCount offline updates.',
      );
    }

    _isSyncing = false;
  }
}
