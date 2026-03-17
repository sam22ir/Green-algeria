import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';


import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'services/sync_engine.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'services/settings_provider.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'core/theme_controller.dart';

late final SettingsProvider settingsProvider;

/// Top-level background message handler — MUST be registered in main() before runApp.
/// When the app is killed, Flutter isolate restarts and only calls this top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in the background isolate
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Background FCM message received: ${message.messageId}');

  // ✅ Bug 7 Fix: Show a local notification in background/killed state.
  // On Android, FCM auto-displays notification-type messages when app is in background/killed.
  // But for data-only messages (no notification payload), we must show it manually.
  if (message.notification == null && message.data.isNotEmpty) {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(const InitializationSettings(android: androidInit));

    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );
    await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await plugin.show(
      message.hashCode,
      message.data['title'] ?? 'الجزائر خضراء',
      message.data['body'] ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // CRITICAL: Must be called before runApp and before any await that could delay registration.
  // When the app is killed, the system spawns a new Dart isolate and calls only this handler.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    await dotenv.load(fileName: ".env");

    // Guard: only initialize Firebase if not already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    await SupabaseService.initialize();
    await ConnectivityService().init(); // v2.1 Reachability Service
    await NotificationService().init();
    SyncEngine().initialize();
    
    settingsProvider = SettingsProvider();
    await settingsProvider.loadInitialPrefs();
    await ThemeController().init(); // Initialize the new theme controller

    // FIX: Ensure Arabic is the default language on first install.
    // EasyLocalization falls back to device locale if nothing is saved.
    // We pre-seed 'ar' so the first run always shows Arabic.
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('language_code')) {
      await prefs.setString('language_code', 'ar');
    }
  } catch (e, stackTrace) {
    // Print real error so it appears in `flutter logs`
    debugPrint('INITIALIZATION ERROR: $e');
    debugPrint('STACK TRACE: $stackTrace');
    // Show error on screen instead of freezing silently on splash
    runApp(InitializationErrorApp(error: e.toString()));
    return;
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      useOnlyLangCode: true,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsProvider),
          ChangeNotifierProvider(create: (_) => AuthService()),
        ],
        child: const GreenAlgeriaApp(),
      ),
    ),
  );
}

class GreenAlgeriaApp extends StatelessWidget {
  const GreenAlgeriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController(),
      builder: (context, _) {
        final themeController = ThemeController();
        return MaterialApp.router(
          title: 'app_name'.tr(),
          debugShowCheckedModeBanner: false,
          themeMode: themeController.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          routerConfig: AppRouter.router,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          // Global Scroll Physics Fix (§12)
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
          ),
        );
      },
    );
  }
}

/// Temporary error screen — shows the real init error on device instead of
/// freezing silently on the splash screen. Remove once root cause is resolved.
class InitializationErrorApp extends StatelessWidget {
  final String error;
  const InitializationErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'خطأ في التهيئة:\n$error',
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
}
