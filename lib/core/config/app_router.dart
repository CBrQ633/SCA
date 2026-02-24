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
  static GoRouter? _router;

  static GoRouter getRouter(AuthProvider authProvider) {
    _router ??= GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppConstants.routeLogin,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthRoute = state.matchedLocation == AppConstants.routeLogin ||
            state.matchedLocation == AppConstants.routeRegister;

        if (!isAuthenticated) return isAuthRoute ? null : AppConstants.routeLogin;
        if (authProvider.currentUser == null) return null;

        if (isAuthRoute) {
          return authProvider.isAdmin ? AppConstants.routeAdminDashboard : AppConstants.routeHome;
        }

        return null;
      },
      routes: [
        GoRoute(path: AppConstants.routeLogin, builder: (context, state) => const LoginScreen()),
        GoRoute(path: AppConstants.routeRegister, builder: (context, state) => const RegisterScreen()),
        
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            final isAdmin = authProvider.isAdmin;
            
            // ✅ Fix: Clear separation of tabs
            final tabs = isAdmin 
              ? const [
                  NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'Stats'),
                  NavigationDestination(icon: Icon(Icons.subscriptions_outlined), label: 'Requests'),
                  NavigationDestination(icon: Icon(Icons.people_outline), label: 'Users'),
                  NavigationDestination(icon: Icon(Icons.newspaper_outlined), label: 'News'),
                  NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
                ]
              : const [
                  NavigationDestination(icon: Icon(Icons.call_outlined), label: 'Calls'),
                  NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Reports'),
                  NavigationDestination(icon: Icon(Icons.star_outline), label: 'Subscription'),
                  NavigationDestination(icon: Icon(Icons.newspaper_outlined), label: 'News'),
                  NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
                ];

            return ScaffoldWithNavBar(navigationShell: navigationShell, tabs: tabs);
          },
          branches: authProvider.isAdmin
              ? [
                  // ADMIN ONLY BRANCHES
                  StatefulShellBranch(routes: [GoRoute(path: AppConstants.routeAdminDashboard, builder: (context, state) => const AdminDashboardScreen())]),
                  StatefulShellBranch(routes: [GoRoute(path: AppConstants.routeAdminSubscriptions, builder: (context, state) => const AdminSubscriptionRequestsScreen())]),
                  StatefulShellBranch(routes: [GoRoute(path: AppConstants.routeAdminUsers, builder: (context, state) => const AdminUserManagementScreen())]),
                  StatefulShellBranch(routes: [GoRoute(path: '/admin/news', builder: (context, state) => const AdminNewsScreen())]),
                  StatefulShellBranch(routes: [
                    GoRoute(path: AppConstants.routeSettings, builder: (context, state) => const SettingsScreen(), routes: [
                      GoRoute(path: 'how-to-use', builder: (context, state) => const HowToUseScreen()),
                      GoRoute(path: 'about', builder: (context, state) => const AboutScreen()),
                    ]),
                  ]),
                ]
              : [
                  // USER ONLY BRANCHES
                  StatefulShellBranch(routes: [
                    GoRoute(path: AppConstants.routeHome, builder: (context, state) => const CallListsScreen(), routes: [
                      GoRoute(path: ':listId', builder: (context, state) => CallListDetailsScreen(listId: state.pathParameters['listId']!)),
                      GoRoute(path: ':listId/process', builder: (context, state) => CallProcessScreen(listId: state.pathParameters['listId']!)),
                    ]),
                  ]),
                  StatefulShellBranch(routes: [GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen())]),
                  StatefulShellBranch(routes: [GoRoute(path: AppConstants.routeSubscription, builder: (context, state) => const SubscriptionScreen())]),
                  StatefulShellBranch(routes: [GoRoute(path: '/news', builder: (context, state) => const NewsScreen())]),
                  StatefulShellBranch(routes: [
                    GoRoute(path: AppConstants.routeSettings, builder: (context, state) => const SettingsScreen(), routes: [
                      GoRoute(path: 'how-to-use', builder: (context, state) => const HowToUseScreen()),
                      GoRoute(path: 'about', builder: (context, state) => const AboutScreen()),
                    ]),
                  ]),
                ],
        ),
      ],
    );
    return _router!;
  }
}
