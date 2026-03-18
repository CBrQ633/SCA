import 'package:hive/hive.dart';

part 'sync_task_model.g.dart';

@HiveType(typeId: 2)
class SyncTaskModel {
  @HiveField(0)
  final String id; // Unique ID for the task
  @HiveField(1)
  final String itemId; // The ID of the call item to update
  @HiveField(2)
  final String status;
  @HiveField(3)
  final String? notes;
  @HiveField(4)
  final DateTime createdAt;

  SyncTaskModel({
    required this.id,
    required this.itemId,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'item_id': itemId,
    'status': status,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };
}
