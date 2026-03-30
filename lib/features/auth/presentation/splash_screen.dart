import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // ✅ بدل polling — نستمع مباشرة لـ AuthService
    // إذا انتهى التحميل فورياً نتنقل بعد الـ frame الأول
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryNavigate();
    });
  }

  void _tryNavigate() {
    if (!mounted || _navigated) return;
    final auth = context.read<AuthService>();

    if (!auth.isLoading) {
      _navigate(auth);
      return;
    }

    // ✅ استمع للتغيير بدل polling
    void listener() {
      if (!mounted || _navigated) return;
      final a = context.read<AuthService>();
      if (!a.isLoading) {
        a.removeListener(listener);
        _navigate(a);
      }
    }

    auth.addListener(listener);

    // ✅ Timeout أمان: إذا لم يتحرك خلال 5 ثواني → اذهب للـ login
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted || _navigated) return;
      final a = context.read<AuthService>();
      a.removeListener(listener);
      debugPrint('SplashScreen: auth timeout — forcing navigation');
      _navigate(a);
    });
  }

  void _navigate(AuthService auth) {
    if (!mounted || _navigated) return;
    _navigated = true;

    final user = auth.firebaseUser;
    if (user != null) {
      if (auth.hasProvince) {
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
