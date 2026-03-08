import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Web Client ID from google-services.json (client_type: 3)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '177139315328-qljfie32tb1291kv6fpe56o5fcscbfcs.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User canceled
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw 'Missing Google Auth Token';
      }

      final AuthResponse res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      return res;
    } catch (e) {
      throw Exception('Google Sign-In Failed: $e');
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _supabase.auth.signOut();
  }

  /// Get Current User
  User? get currentUser => _supabase.auth.currentUser;
  
  /// Stream to listen to Auth State Changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
