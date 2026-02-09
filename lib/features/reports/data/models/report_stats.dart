class CallStats {
  final int totalCalls;
  final int answered;
  final int noAnswer;
  final int pending;

  CallStats({
    required this.totalCalls,
    required this.answered,
    required this.noAnswer,
    required this.pending,
  });
}

class SubscriptionStats {
  final int totalUsers;
  final int active;
  final int pending;
  final int expired;

  SubscriptionStats({
    required this.totalUsers,
    required this.active,
    required this.pending,
    required this.expired,
  });
}
