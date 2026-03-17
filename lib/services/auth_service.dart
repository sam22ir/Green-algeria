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
    _supabase.auth.onAuthStateChange.listen((data) {
      _syncUserRecord(data.session?.user);
    });
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
    } else {
      _currentUserModel = await _supabaseService.getUserRecord(user.id);
      
      if (_currentUserModel == null) {
        final randomAvatar = AppAvatars.getRandom();
        final newUser = UserModel(
          id: user.id,
          fullName: user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? 'unspecified'.tr(),
          email: user.email ?? '',
          role: user.userMetadata?['role'] ?? 'volunteer',
          provinceId: user.userMetadata?['province_id'] as int?,
          avatarAsset: user.userMetadata?['avatar_asset'] ?? randomAvatar,
        );
        await _supabaseService.createUserRecord(newUser);
        
        // Also update auth metadata if it was missing the avatar_asset
        if (user.userMetadata?['avatar_asset'] == null) {
          await _supabase.auth.updateUser(UserAttributes(data: {'avatar_asset': randomAvatar}));
        }
        
        _currentUserModel = newUser;
      }

      // Handle FCM Subscriptions on successful sync — fire-and-forget so they
      // don't delay navigation to the home screen.
      Future(() async {
        try {
          final notifications = NotificationService();
          notifications.subscribeToTopic('national-notifications');
          notifications.subscribeToTopic('national-campaigns');

          final pId = _currentUserModel?.provinceId ?? user.userMetadata?['province_id'];
          if (pId != null) {
            notifications.subscribeToTopic('province-$pId');
            notifications.subscribeToTopic('province-$pId-campaigns');
          }
        } catch (e) {
          debugPrint('Failed to subscribe to FCM topics: $e');
        }
      });
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Public helper — force-re-syncs the user model from supabase.
  /// Call this after writing to the DB outside of an onAuthStateChange event.
  Future<void> syncCurrentUser() async {
    _isLoading = true;
    notifyListeners();
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
        }
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

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.user != null) {
        // Database sync is handled by _syncUserRecord via onAuthStateChange
        debugPrint('Google Sign-In successful for: ${response.user!.email}');
      }
    } on AuthException catch (e) {
      debugPrint('Error with Google SignIn: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error with Google SignIn: $e');
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

  Future<void> logout() async {
    // Unsubscribe from topics before logging out
    try {
      final notifications = NotificationService();
      await notifications.unsubscribeFromTopic('national-notifications');
      await notifications.unsubscribeFromTopic('national-campaigns');
      
      if (_currentUserModel?.provinceId != null) {
        final pId = _currentUserModel!.provinceId;
        await notifications.unsubscribeFromTopic('province-$pId');
        await notifications.unsubscribeFromTopic('province-$pId-campaigns');
      }
    } catch (e) {
      debugPrint('Failed to unsubscribe from FCM topics: $e');
    }

    // Clear FCM token from database so no push is delivered after logout
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _supabase
            .from('users')
            .update({'fcm_token': null})
            .eq('id', userId);
      }
    } catch (e) {
      debugPrint('Failed to clear FCM token: $e');
    }

    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Ignore if google sign in fails to sign out
    }
    await _supabase.auth.signOut();
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
