import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/subscription/data/subscription_repository.dart';

class SubscriptionBadgeProvider with ChangeNotifier {
  final SubscriptionRepository _repository = SubscriptionRepository();
  int _pendingCount = 0;
  Timer? _pollingTimer;

  int get pendingCount => _pendingCount;

  SubscriptionBadgeProvider() {
    refreshCount();
    // Poll every 1 minute to check for new requests
    _pollingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      refreshCount();
    });
  }

  Future<void> refreshCount() async {
    final count = await _repository.getPendingCount();
    if (_pendingCount != count) {
      _pendingCount = count;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
