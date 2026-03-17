import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../core/theme/app_colors.dart';

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 2. Background handler is registered in main.dart before runApp() — do not re-register here.
    // (Re-registering here caused it to silently fail in killed-app scenarios)

    // 3. v3.4.1 Fix: Ensure notifications appear when app is in foreground on iOS
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Configure local notifications for foreground display
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: darwinInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create high importance android channel
    const channel = AndroidNotificationChannel(
      'high_importance_channel', 
      'High Importance Notifications', 
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 5. Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message, channel);
      }
    });

    // 6. Save FCM token to Supabase for direct user targeting
    await _refreshAndSaveToken();

    // Token refresh listener (token can change)
    _fcm.onTokenRefresh.listen(_saveTokenToSupabase);

    _isInitialized = true;
  }

  /// Save FCM token to the users table in Supabase
  Future<void> _refreshAndSaveToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToSupabase(token);
      }
    } catch (e) {
      debugPrint('Error refreshing FCM token: $e');
    }
  }

  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': token})
          .eq('id', uid);
      debugPrint('FCM token saved to Supabase for user $uid');
    } catch (e) {
      // Non-critical: if column doesn't exist yet, log and continue
      debugPrint('Could not save FCM token (column may not exist yet): $e');
    }
  }

  void _showLocalNotification(RemoteMessage message, AndroidNotificationChannel channel) {
    final notification = message.notification;
    // v3.4.1 Fix: Removed strict `android != null` check.
    // Previously, FCM messages without an explicit android block (data-only or iOS)
    // were silently dropped. Now we show the notification regardless.
    if (notification != null) {
      final android = message.notification?.android;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            color: AppColors.oliveGrove,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      debugPrint('Notification tapped with payload: ${response.payload}');
      // Handle navigation or custom action based on payload
    }
  }

  // Topic Management
  Future<void> subscribeToTopic(String topic) async {
    debugPrint('Subscribing to topic: $topic');
    await _fcm.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    debugPrint('Unsubscribing from topic: $topic');
    await _fcm.unsubscribeFromTopic(topic);
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  static Future<void> sendToTopic({
    required String topic,
    required String title,
    required String body,
  }) async {
    try {
      await Supabase.instance.client.functions.invoke(
        'send-fcm',
        body: {
          'topic': topic,
          'title': title,
          'body': body,
        },
      );
    } catch (e) {
      debugPrint('Error sending topic notification: $e');
    }
  }

  static Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      await Supabase.instance.client.functions.invoke(
        'send-fcm',
        body: {
          'user_id': userId,
          'title': title,
          'body': body,
        },
      );
    } catch (e) {
      debugPrint('Error sending user notification: $e');
    }
  }
}
