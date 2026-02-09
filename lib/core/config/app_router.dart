import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_call_assistant/features/auth/presentation/auth_provider.dart';
import 'package:smart_call_assistant/features/auth/presentation/screens/login_screen.dart';
import 'package:smart_call_assistant/features/auth/presentation/screens/register_screen.dart';
import 'package:smart_call_assistant/features/calls/presentation/screens/call_lists_screen.dart';
import 'package:smart_call_assistant/features/calls/presentation/screens/call_list_details_screen.dart';
import 'package:smart_call_assistant/features/calls/presentation/screens/call_process_screen.dart';
import 'package:smart_call_assistant/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:smart_call_assistant/features/settings/presentation/screens/settings_screen.dart';
import 'package:smart_call_assistant/features/admin/presentation/screens/admin_subscription_requests_screen.dart';
import 'package:smart_call_assistant/features/news/presentation/screens/news_screen.dart';
import 'package:smart_call_assistant/features/news/presentation/screens/admin_news_screen.dart';
import 'package:smart_call_assistant/features/admin/presentation/screens/admin_user_management_screen.dart';
import 'package:smart_call_assistant/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:smart_call_assistant/features/reports/presentation/screens/reports_screen.dart';

import 'package:smart_call_assistant/features/about/presentation/screens/about_screen.dart';
import 'package:smart_call_assistant/features/settings/presentation/screens/how_to_use_screen.dart';
import 'package:smart_call_assistant/core/components/scaffold_with_nav_bar.dart';
import 'package:smart_call_assistant/core/constants/app_constants.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppConstants.routeLogin,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthRoute = state.matchedLocation == AppConstants.routeLogin ||
            state.matchedLocation == AppConstants.routeRegister;

        // Not authenticated → Login
        if (!isAuthenticated && !isAuthRoute) {
          return AppConstants.routeLogin;
        }

        // Authenticated on auth route → Home
        if (isAuthenticated && isAuthRoute) {
          final isAdmin = authProvider.isAdmin;
          if (isAdmin) {
            return AppConstants.routeAdminDashboard; // Admin home
          } else {
            // Check subscription for users
            final hasActiveSubscription =
                authProvider.currentUser?.isSubscriptionActive ?? false;
            if (!hasActiveSubscription) {
              return AppConstants.routeSubscription;
            }
            return AppConstants.routeHome;
          }
        }

        // SUBSCRIPTION GATE: Lock only Calls and Reports (allow News, Subscription, Settings)
        final isAdmin = authProvider.isAdmin;
        if (isAuthenticated && !isAdmin) {
          final hasActiveSubscription =
              authProvider.currentUser?.isSubscriptionActive ?? false;
          final currentPath = state.matchedLocation;

          // Allow these paths without subscription: News, Subscription, Settings (for logout)
          final allowedPaths = [
            '/subscription',
            '/news',
            '/settings',
            '/settings/how-to-use',
            '/settings/about'
          ];
          final isAllowedPath =
              allowedPaths.any((path) => currentPath.contains(path));

          if (!hasActiveSubscription && !isAllowedPath) {
            // Lock Calls and Reports only
            return AppConstants.routeSubscription;
          }
        }

        return null;
      },
      refreshListenable: authProvider,
      routes: [
        GoRoute(
          path: AppConstants.routeLogin,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppConstants.routeRegister,
          builder: (context, state) => const RegisterScreen(),
        ),
        // RBAC Shell
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            // Define Tabs based on Role
            final isAdmin = authProvider.isAdmin;

            final tabs = isAdmin
                ? const [
                    NavigationDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: 'Dashboard'),
                    NavigationDestination(
                        icon: Icon(Icons.newspaper_outlined),
                        selectedIcon: Icon(Icons.newspaper),
                        label: 'News'),
                    NavigationDestination(
                        icon: Icon(Icons.subscriptions_outlined),
                        selectedIcon: Icon(Icons.subscriptions),
                        label: 'Sub Requests'),
                    NavigationDestination(
                        icon: Icon(Icons.people_outlined),
                        selectedIcon: Icon(Icons.people),
                        label: 'Users'),
                    NavigationDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings),
                        label: 'Settings'),
                  ]
                : const [
                    NavigationDestination(
                        icon: Icon(Icons.list_alt), label: 'Calls'),
                    NavigationDestination(
                        icon: Icon(Icons.newspaper), label: 'News'),
                    NavigationDestination(
                        icon: Icon(Icons.analytics), label: 'Reports'),
                    NavigationDestination(
                        icon: Icon(Icons.star), label: 'Subscription'),
                    NavigationDestination(
                        icon: Icon(Icons.settings), label: 'Settings'),
                  ];

            return ScaffoldWithNavBar(
              navigationShell: navigationShell,
              tabs: tabs,
            );
          },
          branches: authProvider.isAdmin
              ? [
                  // ADMIN BRANCHES
                  StatefulShellBranch(routes: [
                    GoRoute(
                      path: AppConstants.routeAdminDashboard,
                      builder: (context, state) => const AdminDashboardScreen(),
                    ),
                  ]),
                  StatefulShellBranch(routes: [
                    GoRoute(
                      path: '/admin/news',
                      builder: (context, state) => const AdminNewsScreen(),
                    ),
                  ]),
                  StatefulShellBranch(routes: [
                    GoRoute(
                      path: AppConstants.routeAdminSubscriptions,
                      builder: (context, state) =>
                          const AdminSubscriptionRequestsScreen(),
                    ),
                  ]),
                  StatefulShellBranch(routes: [
                    GoRoute(
                      path: AppConstants.routeAdminUsers,
                      builder: (context, state) =>
                          const AdminUserManagementScreen(),
                    ),
                  ]),
                  StatefulShellBranch(routes: [
                    GoRoute(
                        path: AppConstants.routeSettings,
                        builder: (context, state) => const SettingsScreen(),
                        routes: [
                          GoRoute(
                              path: 'how-to-use',
                              builder: (context, state) =>
                                  const HowToUseScreen()),
                          GoRoute(
                              path: 'about',
                              builder: (context, state) => const AboutScreen()),
                        ]),
                  ]),
                ]
              : [
                  // USER BRANCHES
                  StatefulShellBranch(routes: [
                    GoRoute(
                      path: AppConstants.routeHome,
                      builder: (context, state) => const CallListsScreen(),
                      routes: [
                        GoRoute(
                          path: ':listId',
                          builder: (context, state) => CallListDetailsScreen(
                              listId: state.pathParameters['listId']!),
                        ),
                        GoRoute(
                          path: ':listId/process',
                          builder: (context, state) => CallProcessScreen(
                              listId: state.pathParameters['listId']!),
                        ),
                      ],
                    ),
                  ]),
                  StatefulShellBranch(routes: [
                    GoRoute(
                      path: '/news',
                      builder: (context, state) => const NewsScreen(),
                    ),
                  ]),
                  StatefulShellBranch(routes: [
                    GoRoute(
                      path: '/reports',
                      builder: (context, state) => const ReportsScreen(),
                    ),
                  ]),
                  StatefulShellBranch(routes: [
                    GoRoute(
                      path: AppConstants.routeSubscription,
                      builder: (context, state) => const SubscriptionScreen(),
                    ),
                  ]),
                  StatefulShellBranch(routes: [
                    GoRoute(
                        path: AppConstants.routeSettings,
                        builder: (context, state) => const SettingsScreen(),
                        routes: [
                          GoRoute(
                              path: 'how-to-use',
                              builder: (context, state) =>
                                  const HowToUseScreen()),
                          GoRoute(
                              path: 'about',
                              builder: (context, state) => const AboutScreen()),
                        ]),
                  ]),
                ],
        ),
      ],
    );
  }
}
