import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_badge_provider.dart';
import '../../features/auth/presentation/auth_provider.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final List<NavigationDestination> tabs;
  final StatefulNavigationShell navigationShell;
  final Function(int)? onTap;

  const ScaffoldWithNavBar({
    required this.navigationShell,
    required this.tabs,
    this.onTap,
    super.key,
  });

  void _onItemTapped(int index) {
    if (onTap != null) {
      onTap!(index);
    } else {
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Consumer2<SubscriptionBadgeProvider, AuthProvider>(
        builder: (context, badgeProvider, authProvider, _) {
          final showBadge = authProvider.isAdmin && badgeProvider.pendingCount > 0;

          final destinations = tabs.asMap().entries.map((entry) {
            final idx = entry.key;
            final destination = entry.value;

            if (authProvider.isAdmin && idx == 1 && showBadge) {
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

          int selectedIdx = navigationShell.currentIndex;

          return NavigationBar(
            selectedIndex: selectedIdx,
            onDestinationSelected: _onItemTapped,
            destinations: destinations,
            // ✅ Fixed: Removed hardcoded Colors.white to support Dark Mode
            backgroundColor: theme.navigationBarTheme.backgroundColor,
            elevation: 10,
          );
        },
      ),
    );
  }
}
