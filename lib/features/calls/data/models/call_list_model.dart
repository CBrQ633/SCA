class CallListModel {
  final String id;
  final String userId;
  final String name;
  final String status;
  final DateTime createdAt;
  final double progress; // Added
  final int totalItems; // Added

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
}

class CallListItemModel {
  final String id;
  final String listId;
  final String? name;
  final String phone;
  final String status; // 'pending', 'called', 'no_answer', 'whatsapp'
  final String? notes;
  final DateTime createdAt;

  CallListItemModel({
    required this.id,
    required this.listId,
    this.name,
    required this.phone,
    required this.status,
    this.notes,
    required this.createdAt,
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
    );
  }
}
