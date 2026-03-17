import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final authService = AuthService();

    // Wait until AuthService finishes syncing the user record
    // so GoRouter redirect can correctly read hasProvince
    if (authService.isLoading) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return authService.isLoading;
      });
    }

    if (!mounted) return;

    final user = authService.firebaseUser;

    if (user != null) {
      if (authService.hasProvince) {
        context.go('/');
      } else {
        context.go('/select-province');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco_rounded,
              size: 100,
              color: colorScheme.onPrimary,
            ),
            const SizedBox(height: 24),
            Text(
              'app_name'.tr(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              color: colorScheme.onPrimary.withValues(alpha: 0.5),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
