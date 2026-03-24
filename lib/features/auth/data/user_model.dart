class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String role; // 'sales_user', 'team_leader', or 'admin'
  final String subscriptionStatus;
  final String? subscriptionRejectReason;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final DateTime createdAt;
  final String? currentDeviceId;
  final String? leaderId; // ID of the Team Leader if member
  final String? scaId;    // Unique Short ID (e.g., SCA-X1Y2Z3)

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    required this.subscriptionStatus,
    this.subscriptionRejectReason,
    this.subscriptionStart,
    this.subscriptionEnd,
    required this.createdAt,
    this.currentDeviceId,
    this.leaderId,
    this.scaId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      role: json['role'] as String,
      subscriptionStatus: json['subscription_status'] as String,
      subscriptionRejectReason: json['subscription_reject_reason'] as String?,
      subscriptionStart: json['subscription_start'] != null ? DateTime.parse(json['subscription_start'] as String) : null,
      subscriptionEnd: json['subscription_end'] != null ? DateTime.parse(json['subscription_end'] as String) : null,
      currentDeviceId: json['current_device_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      leaderId: json['leader_id'] as String?,
      scaId: json['sca_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'subscription_status': subscriptionStatus,
      'subscription_reject_reason': subscriptionRejectReason,
      'subscription_start': subscriptionStart?.toIso8601String(),
      'subscription_end': subscriptionEnd?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'current_device_id': currentDeviceId,
      'leader_id': leaderId,
      'sca_id': scaId,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isTeamLeader => role == 'team_leader';
  bool get isSalesUser => role == 'sales_user';
  bool get isSubscriptionActive => subscriptionStatus == 'active';
  bool get hasLeader => leaderId != null;
}
