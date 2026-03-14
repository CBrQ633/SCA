class SubscriptionRequest {
  final String id;
  final String userId;
  final String planType; 
  final double amount;
  final String? paymentScreenshotUrl;
  final String status; 
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? processedBy;

  SubscriptionRequest({
    required this.id,
    required this.userId,
    required this.planType,
    required this.amount,
    this.paymentScreenshotUrl,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.processedBy,
  });

  factory SubscriptionRequest.fromJson(Map<String, dynamic> json) {
    return SubscriptionRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      planType: json['plan_type'] as String? ?? 'monthly',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentScreenshotUrl: json['payment_screenshot_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      processedAt: json['processed_at'] != null ? DateTime.parse(json['processed_at'] as String) : null,
      processedBy: json['processed_by'] as String?,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
}

class CallList {
  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;

  CallList({required this.id, required this.userId, required this.name, required this.createdAt});

  factory CallList.fromJson(Map<String, dynamic> json) {
    return CallList(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String? ?? 'Unnamed List',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }
}

class CallEntry {
  final String id;
  final String listId;
  final String? listName; 
  final String phoneNumber;
  final String? customerName;
  final String status; 
  final DateTime? calledAt;
  final int position;

  CallEntry({
    required this.id,
    required this.listId,
    this.listName,
    required this.phoneNumber,
    this.customerName,
    required this.status,
    this.calledAt,
    required this.position,
  });

  factory CallEntry.fromJson(Map<String, dynamic> json) {
    String rawStatus = json['status'] as String? ?? 'pending';
    if (rawStatus == 'called') rawStatus = 'answered';
    if (rawStatus == 'no_answer') rawStatus = 'not_answered';

    return CallEntry(
      id: json['id'] as String? ?? '',
      listId: json['list_id'] as String? ?? '',
      listName: json['list_name'] as String?,
      phoneNumber: (json['phone_number'] ?? json['phone']) as String? ?? '',
      customerName: (json['customer_name'] ?? json['name']) as String?,
      status: rawStatus,
      calledAt: json['called_at'] != null ? DateTime.parse(json['called_at'] as String) : null,
      position: json['position'] as int? ?? 0,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAnswered => status == 'answered';
  bool get isNotAnswered => status == 'not_answered';
}

class NewsAnnouncement {
  final String id;
  final String title;
  final String content;
  final List<String> imageUrls;
  final String createdBy;
  final DateTime createdAt;
  final bool isActive;
  final DateTime? expiryDate;

  NewsAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrls = const [],
    required this.createdBy,
    required this.createdAt,
    required this.isActive,
    this.expiryDate,
  });

  factory NewsAnnouncement.fromJson(Map<String, dynamic> json) {
    return NewsAnnouncement(
      id: json['id'] as String,
      title: json['title'] as String? ?? json['title_ar'] as String? ?? 'No Title',
      content: json['content'] as String? ?? json['content_ar'] as String? ?? 'No Content',
      imageUrls: json['image_urls'] != null 
          ? List<String>.from(json['image_urls'] as List) 
          : (json['image_url'] != null ? [json['image_url'] as String] : []),
      createdBy: json['created_by'] as String? ?? 'unknown',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      isActive: json['is_active'] as bool? ?? true,
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date'] as String) : null,
    );
  }
}
