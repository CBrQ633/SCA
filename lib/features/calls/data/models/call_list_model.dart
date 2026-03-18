import 'package:hive/hive.dart';

part 'call_list_model.g.dart';

@HiveType(typeId: 0)
class CallListModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final String status;
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
  final double progress;
  @HiveField(6)
  final int totalItems;

  CallListModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.status,
    required this.createdAt,
    this.progress = 0.0,
    this.totalItems = 0,
  });

  factory CallListModel.fromJson(Map<String, dynamic> json) {
    return CallListModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      status: (json['status'] as String?) ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      totalItems: json['total_items'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'progress': progress,
    'total_items': totalItems,
  };
}

@HiveType(typeId: 1)
class CallListItemModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String listId;
  @HiveField(2)
  final String? name;
  @HiveField(3)
  final String phone;
  @HiveField(4)
  final String status; // 'pending', 'called', 'no_answer', 'whatsapp'
  @HiveField(5)
  final String? notes;
  @HiveField(6)
  final DateTime createdAt;
  @HiveField(7)
  final DateTime? updatedAt;

  CallListItemModel({
    required this.id,
    required this.listId,
    this.name,
    required this.phone,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory CallListItemModel.fromJson(Map<String, dynamic> json) {
    return CallListItemModel(
      id: json['id'] as String,
      listId: json['list_id'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'list_id': listId,
    'name': name,
    'phone': phone,
    'status': status,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
