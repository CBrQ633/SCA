import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_badge_provider.dart';
import '../../features/auth/presentation/auth_provider.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final List<NavigationDestination> tabs;

  const ScaffoldWithNavBar({
    required this.navigationShell,
    required this.tabs,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Consumer2<SubscriptionBadgeProvider, AuthProvider>(
        builder: (context, badgeProvider, authProvider, _) {
          final showBadge =
              authProvider.isAdmin && badgeProvider.pendingCount > 0;

          final destinations = tabs.asMap().entries.map((entry) {
            final idx = entry.key;
            final destination = entry.value;

            // Assuming "Sub Requests" is now the third tab (index 2) for Admin
            if (authProvider.isAdmin && idx == 2 && showBadge) {
              return NavigationDestination(
                icon: Badge(
                  label: Text(badgeProvider.pendingCount.toString()),
                  child: destination.icon,
                ),
                label: destination.label,
              );
            }
            return destination;
          }).toList();

          return NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _goBranch,
            destinations: destinations,
          );
        },
      ),
    );
  }
}
