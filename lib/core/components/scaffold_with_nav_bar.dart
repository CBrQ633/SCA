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
          // Logic for inactive users to match the tabs they see
          if (!authProvider.isAdmin && !(authProvider.currentUser?.isSubscriptionActive ?? false)) {
            // If they only have 2 tabs (Plans, Settings), but router index might be different
            // This is a bit tricky with StatefulShellRoute, usually it's better to keep indices 1:1
            // But if we're filtering branches in router, currentIndex should be 0 or 1.
          }

          return NavigationBar(
            selectedIndex: selectedIdx,
            onDestinationSelected: _onItemTapped,
            destinations: destinations,
            // backgroundColor is now handled by the theme (navigationBarTheme)
            elevation: 10,
          );
        },
      ),
    );
  }
}
