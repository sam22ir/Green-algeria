import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

import 'package:easy_localization/easy_localization.dart';
import '../constants/avatars.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal() {
    // استمع لتغييرات Auth
    _supabase.auth.onAuthStateChange.listen((data) {
      _syncUserRecord(data.session?.user);
    });

    // ✅ إصلاح رئيسي: إذا كانت هناك جلسة محفوظة مسبقاً (restart / update)
    // onAuthStateChange لا يُطلق فوراً — نُزامن يدوياً بدون انتظار
    final existingUser = _supabase.auth.currentUser;
    if (existingUser != null) {
      // لا ننتظر — نبدأ الجلسة المحفوظة في الخلفية
      _syncUserRecord(existingUser);
    } else {
      // لا يوجد مستخدم — انتهى التحميل فوراً
      _isLoading = false;
    }
  }

  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final SupabaseService _supabaseService = SupabaseService();

  UserModel? _currentUserModel;
  UserModel? get currentUserModel => _currentUserModel;

  User? get firebaseUser => _supabase.auth.currentUser;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool get hasProvince => _currentUserModel?.provinceId != null;

  Future<void> _syncUserRecord(User? user) async {
    if (user == null) {
      _currentUserModel = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // ✅ لا نضع isLoading=true هنا لأن ذلك يُجمّد الـ splash
    // فقط نُزامن البيانات بصمت
    try {
      _currentUserModel = await _supabaseService.getUserRecord(user.id);

      if (_currentUserModel == null) {
        // مستخدم جديد — إنشاء سجل
        final randomAvatar = AppAvatars.getRandom();
        final newUser = UserModel(
          id: user.id,
          fullName: user.userMetadata?['full_name'] ??
              user.userMetadata?['name'] ??
              'unspecified'.tr(),
          email: user.email ?? '',
          role: user.userMetadata?['role'] ?? 'volunteer',
          provinceId: user.userMetadata?['province_id'] as int?,
          avatarAsset:
              user.userMetadata?['avatar_asset'] ?? randomAvatar,
        );
        await _supabaseService.createUserRecord(newUser);

        if (user.userMetadata?['avatar_asset'] == null) {
          await _supabase.auth.updateUser(
              UserAttributes(data: {'avatar_asset': randomAvatar}));
        }
        _currentUserModel = newUser;
      }

      // ✅ FCM في الخلفية الكاملة — لا تؤخر التنقل أبداً
      _subscribeFcmAsync(user);
    } catch (e) {
      debugPrint('_syncUserRecord error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// FCM subscriptions — fire-and-forget في isolate منفصل
  void _subscribeFcmAsync(User user) {
    Future.microtask(() async {
      try {
        final notifications = NotificationService();
        unawaited(notifications.subscribeToTopic('national-notifications'));
        unawaited(notifications.subscribeToTopic('national-campaigns'));

        final pId = _currentUserModel?.provinceId ??
            user.userMetadata?['province_id'];
        if (pId != null) {
          unawaited(notifications.subscribeToTopic('province-$pId'));
          unawaited(notifications.subscribeToTopic('province-$pId-campaigns'));
        }
      } catch (e) {
        debugPrint('FCM subscribe error: $e');
      }
    });
  }

  /// Public helper — force-re-syncs the user model from supabase.
  Future<void> syncCurrentUser() async {
    await _syncUserRecord(_supabase.auth.currentUser);
  }

  Future<void> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
    int? provinceId,
    String? avatarAsset,
  }) async {
    try {
      final selectedAvatar = avatarAsset ?? AppAvatars.getRandom();
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'province_id': provinceId,
          'role': 'volunteer',
          'avatar_asset': selectedAvatar,
        },
      );
    } catch (e) {
      debugPrint('Error registering user: $e');
      rethrow;
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      debugPrint('Error logging in user: $e');
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.user != null) {
        debugPrint('Google Sign-In successful: ${response.user!.email}');
      }
    } on AuthException catch (e) {
      debugPrint('Google SignIn AuthException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Google SignIn error: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.greenalgeria://reset-password/',
      );
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }

  /// ✅ logout محسّن: لا ينتظر FCM — ينفّذ كل شيء بالتوازي
  Future<void> logout() async {
    // إلغاء الاشتراكات + مسح FCM token بالتوازي (fire-and-forget)
    _unsubscribeFcmAsync();

    // signOut مباشرة — لا ننتظر FCM
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await _supabase.auth.signOut();
  }

  void _unsubscribeFcmAsync() {
    final userId = _supabase.auth.currentUser?.id;
    final pId = _currentUserModel?.provinceId;

    Future.microtask(() async {
      try {
        final notifications = NotificationService();
        unawaited(notifications.unsubscribeFromTopic('national-notifications'));
        unawaited(notifications.unsubscribeFromTopic('national-campaigns'));
        if (pId != null) {
          unawaited(notifications.unsubscribeFromTopic('province-$pId'));
          unawaited(notifications.unsubscribeFromTopic('province-$pId-campaigns'));
        }
      } catch (e) {
        debugPrint('FCM unsubscribe error: $e');
      }
    });

    // مسح FCM token بالتوازي
    if (userId != null) {
      Future.microtask(() async {
        try {
          await _supabase
              .from('users')
              .update({'fcm_token': null}).eq('id', userId);
        } catch (e) {
          debugPrint('FCM token clear error: $e');
        }
      });
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      debugPrint('Error updating password: $e');
      rethrow;
    }
  }
}

// ignore: unused_element
void unawaited(Future<void> future) {
  future.catchError((e) => debugPrint('unawaited error: $e'));
}
