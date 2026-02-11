// lib/utils/session_manager.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';
import '../data/services/api_service.dart';
import '../config/environment.dart';

class SessionManager {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _lastLoginKey = 'last_login';

  // Save user session
  static Future<void> saveSession(String token, User user, {String? refreshToken}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
      
      if (refreshToken != null) {
        await prefs.setString(_refreshTokenKey, refreshToken);
      }
      
      // Set token in API service
      await ApiService.saveAuthToken(token);
      
      if (Environment.debugMode) {
        print('Session saved for user: ${user.fullName}');
      }
    } catch (e) {
      if (Environment.debugMode) {
        print('Error saving session: $e');
      }
      throw Exception('Failed to save session');
    }
  }

  // Get current session
  static Future<SessionData?> getSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);

      if (token != null && userJson != null) {
        final user = User.fromJson(jsonDecode(userJson));
        await ApiService.saveAuthToken(token);
        
        return SessionData(
          token: token,
          user: user,
          refreshToken: prefs.getString(_refreshTokenKey),
          lastLogin: prefs.getString(_lastLoginKey) != null
              ? DateTime.tryParse(prefs.getString(_lastLoginKey)!)
              : null,
        );
      }
      return null;
    } catch (e) {
      if (Environment.debugMode) {
        print('Error getting session: $e');
      }
      return null;
    }
  }

  // Clear session (logout)
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_lastLoginKey);
      
      await ApiService.clearAuthTokens();
      
      if (Environment.debugMode) {
        print('Session cleared successfully');
      }
    } catch (e) {
      if (Environment.debugMode) {
        print('Error clearing session: $e');
      }
    }
  }

  // Update user data in session
  static Future<void> updateUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      
      if (Environment.debugMode) {
        print('User data updated in session');
      }
    } catch (e) {
      if (Environment.debugMode) {
        print('Error updating user in session: $e');
      }
    }
  }

  // Check if session is valid
  static Future<bool> isSessionValid() async {
    try {
      final session = await getSession();
      if (session == null) return false;

      // Check if token exists
      if (session.token.isEmpty) return false;

      // Check if session is too old (optional - implement based on your needs)
      if (session.lastLogin != null) {
        final daysSinceLogin = DateTime.now().difference(session.lastLogin!).inDays;
        if (daysSinceLogin > 30) { // Session expires after 30 days
          await clearSession();
          return false;
        }
      }

      return true;
    } catch (e) {
      if (Environment.debugMode) {
        print('Error checking session validity: $e');
      }
      return false;
    }
  }

  // Get current user
  static Future<User?> getCurrentUser() async {
    final session = await getSession();
    return session?.user;
  }

  // Get current token
  static Future<String?> getCurrentToken() async {
    final session = await getSession();
    return session?.token;
  }

  // Refresh session (if your backend supports refresh tokens)
  static Future<bool> refreshSession() async {
    try {
      final session = await getSession();
      if (session?.refreshToken == null) return false;

      // Implement refresh token logic here based on your backend
      // This is a placeholder - adjust according to your API
      final response = await ApiService.post<Map<String, dynamic>>(
        '${Environment.apiBaseUrl}/refresh',
        {'refresh_token': session!.refreshToken},
        requiresAuth: false,
      );

      if (response.isSuccess && response.data != null) {
        final newToken = response.data!['token'];
        final userData = response.data!['user'];
        
        if (newToken != null && userData != null) {
          final user = User.fromJson(userData);
          await saveSession(
            newToken, 
            user, 
            refreshToken: response.data!['refresh_token'],
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      if (Environment.debugMode) {
        print('Error refreshing session: $e');
      }
      return false;
    }
  }
}

// Session data model
class SessionData {
  final String token;
  final User user;
  final String? refreshToken;
  final DateTime? lastLogin;

  SessionData({
    required this.token,
    required this.user,
    this.refreshToken,
    this.lastLogin,
  });

  bool get hasRefreshToken => refreshToken != null && refreshToken!.isNotEmpty;
  
  Duration? get timeSinceLogin {
    if (lastLogin == null) return null;
    return DateTime.now().difference(lastLogin!);
  }

  @override
  String toString() {
    return 'SessionData{user: ${user.fullName}, hasToken: ${token.isNotEmpty}, lastLogin: $lastLogin}';
  }
}

