class SubscriptionRequest {
  final String id;
  final String userId;
  final String planType; // 'monthly' or 'quarterly'
  final double amount;
  final String? paymentScreenshotUrl;
  final String status; // 'pending', 'approved', 'rejected'
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
      planType: json['plan_type'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentScreenshotUrl: json['payment_screenshot_url'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
      processedBy: json['processed_by'] as String?,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isMonthly => planType == 'monthly';
  bool get isQuarterly => planType == 'quarterly';

  int get durationDays => isMonthly ? 30 : 90;
}

class CallList {
  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;

  CallList({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
  });

  factory CallList.fromJson(Map<String, dynamic> json) {
    return CallList(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class CallEntry {
  final String id;
  final String listId;
  final String phoneNumber;
  final String? customerName;
  final String status; // 'pending', 'answered', 'not_answered'
  final DateTime? calledAt;
  final int position;

  CallEntry({
    required this.id,
    required this.listId,
    required this.phoneNumber,
    this.customerName,
    required this.status,
    this.calledAt,
    required this.position,
  });

  factory CallEntry.fromJson(Map<String, dynamic> json) {
    return CallEntry(
      id: json['id'] as String,
      listId: json['list_id'] as String,
      phoneNumber: json['phone_number'] as String,
      customerName: json['customer_name'] as String?,
      status: json['status'] as String,
      calledAt: json['called_at'] != null
          ? DateTime.parse(json['called_at'] as String)
          : null,
      position: json['position'] as int,
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

  NewsAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrls = const [],
    required this.createdBy,
    required this.createdAt,
    required this.isActive,
  });

  factory NewsAnnouncement.fromJson(Map<String, dynamic> json) {
    return NewsAnnouncement(
      id: json['id'] as String,
      title:
          json['title'] as String? ?? json['title_ar'] as String? ?? 'No Title',
      content: json['content'] as String? ??
          json['content_ar'] as String? ??
          'No Content',
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : (json['image_url'] != null ? [json['image_url'] as String] : []),
      createdBy: json['created_by'] as String? ?? 'unknown',
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  // Deprecated helper methods for compatibility during migration
  String getTitle(String _) => title;
  String getContent(String _) => content;
}
