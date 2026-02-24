import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_badge_provider.dart';
import '../../features/auth/presentation/auth_provider.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final List<NavigationDestination> tabs;
  final StatefulNavigationShell navigationShell;
  final Function(int)? onTap; // ✅ Added custom onTap

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

            // Admin: Sub Requests is the 2nd tab (Stats=0, Requests=1, Users=2, News=3, Settings=4)
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

          // Calculate correct selected index for inactive users
          int selectedIdx = navigationShell.currentIndex;
          if (!authProvider.isAdmin && !(authProvider.currentUser?.isSubscriptionActive ?? false)) {
            selectedIdx = navigationShell.currentIndex == 3 ? 0 : 1;
          }

          return NavigationBar(
            selectedIndex: selectedIdx,
            onDestinationSelected: _onItemTapped,
            destinations: destinations,
            backgroundColor: Colors.white,
            elevation: 10,
          );
        },
      ),
    );
  }
}
