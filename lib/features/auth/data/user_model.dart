class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String role; // 'user' or 'admin'
  final String subscriptionStatus; // 'active', 'expired', 'pending'
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    required this.subscriptionStatus,
    this.subscriptionStart,
    this.subscriptionEnd,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      role: json['role'] as String,
      subscriptionStatus: json['subscription_status'] as String,
      subscriptionStart: json['subscription_start'] != null
          ? DateTime.parse(json['subscription_start'] as String)
          : null,
      subscriptionEnd: json['subscription_end'] != null
          ? DateTime.parse(json['subscription_end'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'subscription_status': subscriptionStatus,
      'subscription_start': subscriptionStart?.toIso8601String(),
      'subscription_end': subscriptionEnd?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isSubscriptionActive => subscriptionStatus == 'active';
  bool get isSubscriptionExpired => subscriptionStatus == 'expired';
  bool get isSubscriptionPending => subscriptionStatus == 'pending';
}
