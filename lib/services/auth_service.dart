import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final SupabaseService _supabaseService = SupabaseService();

  UserModel? _currentUserModel;
  UserModel? get currentUserModel => _currentUserModel;

  User? get firebaseUser => _auth.currentUser;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _syncUserRecord(user);
    });
  }

  Future<void> _syncUserRecord(User? user) async {
    if (user == null) {
      _currentUserModel = null;
    } else {
      _currentUserModel = await _supabaseService.getUserRecord(user.uid);
      
      if (_currentUserModel == null) {
        final newUser = UserModel(
          id: user.uid,
          fullName: user.displayName ?? 'New Volunteer',
          email: user.email ?? '',
          role: 'volunteer',
        );
        await _supabaseService.createUserRecord(newUser);
        _currentUserModel = newUser;
      }

      // Handle FCM Subscriptions on successful sync
      try {
        await NotificationService().subscribeToTopic('national-notifications');
        if (_currentUserModel!.provinceId != null) {
          await NotificationService().subscribeToTopic('province-${_currentUserModel!.provinceId}');
        }
      } catch (e) {
        debugPrint('Failed to subscribe to FCM topics: $e');
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
    int? provinceId,
  }) async {
    try {
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (cred.user != null) {
        await cred.user!.updateDisplayName(fullName);
        final newUser = UserModel(
          id: cred.user!.uid,
          fullName: fullName,
          email: email,
          provinceId: provinceId,
          role: 'volunteer',
        );
        await _supabaseService.createUserRecord(newUser);
        _currentUserModel = newUser;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error registering user: $e');
      rethrow;
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
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

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential cred = await _auth.signInWithCredential(credential);
      if (cred.user != null) {
        // Handled via listener
      }
    } catch (e) {
      debugPrint('Error with Google SignIn: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    // Unsubscribe from topics before logging out
    try {
      await NotificationService().unsubscribeFromTopic('national-notifications');
      if (_currentUserModel?.provinceId != null) {
        await NotificationService().unsubscribeFromTopic('province-${_currentUserModel!.provinceId}');
      }
    } catch (e) {
      debugPrint('Failed to unsubscribe from FCM topics: $e');
    }

    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
