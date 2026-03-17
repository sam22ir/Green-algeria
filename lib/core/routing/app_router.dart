import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// Placeholder screens for routing setup
import '../../features/home/presentation/home_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/campaigns/presentation/campaigns_screen.dart';
import '../../features/campaigns/presentation/campaign_details_screen.dart';
import '../../models/campaign_model.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/profile/presentation/role_request_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/province_selection_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/settings/report_problem_screen.dart';
import '../../features/settings/technical_support_screen.dart';
import '../../features/settings/about_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/campaigns/presentation/past_campaigns_screen.dart';
import '../../services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';

class AppRouter {
  static Page _fadeRoute(Widget child, GoRouterState state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: AuthService(),
    redirect: (context, state) {
      final authService = AuthService();
      final isAuth = authService.firebaseUser != null;
      final path = state.uri.toString();
      final isLoginRoute = path == '/login' || path == '/register';
      final isSplashRoute = path == '/splash';
      final isProvinceRoute = path == '/select-province';
      // ✅ إصلاح: هذه الشاشات عامة ولا تحتاج مصادقة
      final isPublicRoute = isLoginRoute
          || isSplashRoute
          || path == '/forgot-password'
          || path.startsWith('/reset-password');

      if (isSplashRoute) return null;

      // غير مسجّل + مسار محمي → /login
      if (!isAuth && !isPublicRoute) {
        return '/login';
      }

      if (isAuth) {
        if (authService.isLoading) return null;

        // لا ولاية → /select-province (لكن لا نُعيد توجيه forgot/reset)
        if (!authService.hasProvince && !isProvinceRoute && !isPublicRoute) {
          return '/select-province';
        }

        // مسجّل + له ولاية + على شاشة login/register/province → /
        if (authService.hasProvince && (isLoginRoute || isProvinceRoute)) {
          return '/';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _fadeRoute(const SplashScreen(), state),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fadeRoute(const SignInScreen(), state),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _fadeRoute(const RegisterScreen(), state),
      ),
      GoRoute(
        path: '/select-province',
        pageBuilder: (context, state) => _fadeRoute(const ProvinceSelectionScreen(), state),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _fadeRoute(const SettingsScreen(), state),
      ),
      GoRoute(
        path: '/role-request',
        pageBuilder: (context, state) => _fadeRoute(const RoleRequestScreen(), state),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _fadeRoute(const ForgotPasswordScreen(), state),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) => _fadeRoute(const ResetPasswordScreen(), state),
      ),
      GoRoute(
        path: '/report-problem',
        pageBuilder: (context, state) => _fadeRoute(const ReportProblemScreen(), state),
      ),
      GoRoute(
        path: '/technical-support',
        pageBuilder: (context, state) => _fadeRoute(const TechnicalSupportScreen(), state),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) => _fadeRoute(const DashboardScreen(), state),
      ),
      GoRoute(
        path: '/about',
        pageBuilder: (context, state) => _fadeRoute(const AboutScreen(), state),
      ),
      GoRoute(
        path: '/past-campaigns',
        pageBuilder: (context, state) => _fadeRoute(const PastCampaignsScreen(), state),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _fadeRoute(const HomeScreen(), state),
          ),
          GoRoute(
            path: '/map',
            pageBuilder: (context, state) => _fadeRoute(const MapScreen(), state),
          ),
          GoRoute(
            path: '/campaigns',
            pageBuilder: (context, state) => _fadeRoute(const CampaignsScreen(), state),
            routes: [
              GoRoute(
                path: 'details',
                pageBuilder: (context, state) {
                  final campaign = state.extra as CampaignModel;
                  return _fadeRoute(CampaignDetailsScreen(campaign: campaign), state);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/leaderboard',
            pageBuilder: (context, state) => _fadeRoute(const LeaderboardScreen(), state),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => _fadeRoute(const ProfileScreen(), state),
          ),
        ],
      ),
    ],
  );
}

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1))),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.4),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          currentIndex: _calculateSelectedIndex(context),
          onTap: (int idx) => _onItemTapped(idx, context),
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: 'home'.tr()),
            BottomNavigationBarItem(
              icon: const Icon(Icons.explore_outlined),
              activeIcon: const Icon(Icons.explore),
              label: 'map'.tr(),
            ),
            BottomNavigationBarItem(icon: const Icon(Icons.nature_people_rounded), label: 'campaigns'.tr()),
            BottomNavigationBarItem(icon: const Icon(Icons.emoji_events_rounded), label: 'leaderboard'.tr()),
            BottomNavigationBarItem(icon: const Icon(Icons.person_rounded), label: 'profile'.tr()),
          ],
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/map')) return 1;
    if (location.startsWith('/campaigns')) return 2;
    if (location.startsWith('/leaderboard')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/map');
        break;
      case 2:
        context.go('/campaigns');
        break;
      case 3:
        context.go('/leaderboard');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}
