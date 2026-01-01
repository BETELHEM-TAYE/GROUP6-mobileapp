import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_auth show User;
import '../models/user.dart';

// Get the global Supabase client
final supabase = Supabase.instance.client;

class AuthService {
  /// --- SIGN UP ---
  /// Creates a new user in `auth.users` and (thanks to our trigger)
  /// a new row in `public.profiles`.
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
    String userRole = 'buyer',
  }) async {
    try {
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        // 'data' is where we pass the extra fields for our 'profiles' table.
        // Our SQL trigger (handle_new_user) will use this.
        data: {
          'email': email,
          'name': name,
          'phone_number': phone ?? '',
          'user_role': userRole,
        },
      );

      // Note: By default, Supabase sends a confirmation email.
      // You can disable this in your Supabase project settings if you want.
      // Go to: Authentication -> Providers -> Email -> Enable email confirmation (toggle off)
      if (authResponse.user == null) {
        throw const AuthException('Sign up failed: User is null');
      }
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint("Auth Exception: ${e.message}");
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("An unknown error occurred: $e");
      }
      rethrow;
    }
  }

  /// --- SIGN IN ---
  /// Signs in an existing user with email and password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint("=== AUTH SERVICE SIGN IN ===");
        debugPrint("Attempting to sign in with email: $email");
      }

      final authResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        debugPrint("Auth response received");
        debugPrint("User ID: ${authResponse.user?.id}");
        debugPrint("User email: ${authResponse.user?.email}");
      }

      if (authResponse.user == null) {
        if (kDebugMode) {
          debugPrint("❌ User is null in auth response");
        }
        throw const AuthException('Sign in failed: User is null');
      }

      if (kDebugMode) {
        debugPrint("✅ Sign in successful in AuthService");
      }
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Auth Exception during sign in:");
        debugPrint("   Message: ${e.message}");
        debugPrint("   Status code: ${e.statusCode}");
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Unknown error during sign in: $e");
      }
      rethrow;
    }
  }

  /// --- SIGN IN WITH GOOGLE ---
  /// Signs in or signs up a user using Google OAuth.
  Future<void> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        debugPrint("=== AUTH SERVICE GOOGLE SIGN IN ===");
      }

      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb
            ? null
            : 'io.supabase.flutter://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (kDebugMode) {
        debugPrint("✅ Google OAuth initiated");
      }
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Auth Exception during Google sign in:");
        debugPrint("   Message: ${e.message}");
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Unknown error during Google sign in: $e");
      }
      rethrow;
    }
  }

  /// --- SIGN OUT ---
  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
      if (kDebugMode) {
        debugPrint("✅ Sign out successful");
      }
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint("Auth Exception: ${e.message}");
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("An unknown error occurred: $e");
      }
      rethrow;
    }
  }

  /// --- GET CURRENT AUTH USER ---
  /// A handy helper to get the currently logged-in user from Supabase.
  supabase_auth.User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  /// --- GET CURRENT USER PROFILE ---
  /// Fetches the full profile details of the currently logged-in user.
  Future<User?> getCurrentUserProfile() async {
    try {
      final user = getCurrentUser();
      if (user == null) {
        return null; // No user logged in
      }

      final response = await supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

      return User.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error getting current user profile: $e");
      }
      return null;
    }
  }
}

