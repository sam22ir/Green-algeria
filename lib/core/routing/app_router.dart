import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// Placeholder screens for routing setup
import '../theme/app_colors.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/campaigns/presentation/campaigns_screen.dart';
import '../../features/campaigns/presentation/campaign_details_screen.dart';
import '../../models/campaign_model.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/profile/presentation/role_request_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../services/auth_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authService = AuthService();
      final isAuth = authService.firebaseUser != null;
      final isLoginRoute = state.uri.toString() == '/login' || state.uri.toString() == '/register';
      final isSplashRoute = state.uri.toString() == '/splash';

      if (isSplashRoute) return null; // Let splash screen handle the logic
      if (!isAuth && !isLoginRoute) return '/login';
      if (isAuth && isLoginRoute) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/role-request',
        builder: (context, state) => const RoleRequestScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: '/campaigns',
            builder: (context, state) => const CampaignsScreen(),
            routes: [
              GoRoute(
                path: 'details',
                builder: (context, state) {
                  final campaign = state.extra as CampaignModel;
                  return CampaignDetailsScreen(campaign: campaign);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/leaderboard',
            builder: (context, state) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.linenWhite,
          boxShadow: [
            BoxShadow(
              color: AppColors.mossForest.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.mossForest,
          unselectedItemColor: AppColors.oliveGrey.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          currentIndex: _calculateSelectedIndex(context),
          onTap: (int idx) => _onItemTapped(idx, context),
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: l10n.home),
            BottomNavigationBarItem(icon: const Icon(Icons.map_rounded), label: l10n.map),
            BottomNavigationBarItem(icon: const Icon(Icons.nature_people_rounded), label: l10n.campaigns),
            BottomNavigationBarItem(icon: const Icon(Icons.emoji_events_rounded), label: l10n.leaderboard),
            BottomNavigationBarItem(icon: const Icon(Icons.person_rounded), label: l10n.profile),
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
