import 'dart:convert';
import 'package:ASSOU/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../../config/api_endpoints.dart';
import '../../config/environment.dart';

// Import old User model for backward compatibility

/// Modern UserService that consolidates user management functionality
class UserService {
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';

  // ========================================
  // LOCAL STORAGE METHODS
  // ========================================

  /// Save user and token to local storage
  static Future<void> saveUser(dynamic user, String token) async {
    final prefs = await SharedPreferences.getInstance();

    // Handle user model - assume it has toJson method
    Map<String, dynamic> userJson = user.toJson();

    await prefs.setString(_userKey, json.encode(userJson));
    await ApiService.saveAuthToken(token);
    await prefs.setString("phone_number", userJson['phone_number']);
  }

  /// Get current user from local storage (returns old User model for backward compatibility)
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    print("userJson : $userJson");

    if (userJson != null) {
      try {
        final userMap = json.decode(userJson);
        // Return old User model for backward compatibility
        return User.fromJson(userMap);
      } catch (e) {
        if (Environment.debugMode) {
          print('Error retrieving user: $e');
        }
      }
    }
    return null;
  }

  /// Get authentication token
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Alternative method name for backward compatibility
  static Future<String?> getToken() async {
    return getAuthToken();
  }

  /// Update user data in local storage
  static Future<void> updateUser(dynamic user) async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> userJson = user.toJson();

    await prefs.setString(_userKey, json.encode(userJson));
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    final token = await getAuthToken();
    return user != null && token != null && token.isNotEmpty;
  }

  /// Clear all user data (logout)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await ApiService.clearAuthTokens();
  }

  /// Logout user
  static Future<void> logout() async {
    await clearAllData();
    await ApiService.clearAuthTokens();
  }

  // ========================================
  // API METHODS
  // ========================================

  /// Get user profile from server
  static Future<User?> getUserProfile() async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.userProfile,
      );

      if (response.isSuccess && response.data != null) {
        final userData = response.data!['user'] ?? response.data!['data'];
        final user = User.fromJson(userData);
        // Update local storage
        await updateUser(user);
        return user;
      } else {
        if (Environment.debugMode) {
          print('UserService.getUserProfile error: ${response.message}');
        }
        return null;
      }
    } catch (e) {
      if (Environment.debugMode) {
        print('UserService.getUserProfile exception: $e');
      }
      return null;
    }
  }

  /// Update user profile on server (returns Map for backward compatibility)
  static Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? country,
    String? address,
    String? photo,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (firstName != null) updateData['first_name'] = firstName;
      if (lastName != null) updateData['last_name'] = lastName;
      if (email != null) updateData['email'] = email;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (country != null) updateData['country'] = country;
      if (address != null) updateData['adresse'] = address;
      if (photo != null) updateData['photo'] = photo;

      final response = await ApiService.put<Map<String, dynamic>>(
        ApiEndpoints.updateProfile,
        updateData,
      );

      if (response.isSuccess && response.data != null) {
        final userData = response.data!['user'] ?? response.data!['data'];
        final updatedUser = User.fromJson(userData);
        await updateUser(updatedUser);

        return {
          'success': true,
          'message': response.message,
          'data': {
            'user': updatedUser.toJson(),
          },
        };
      } else {
        return {
          'success': false,
          'message': response.message,
        };
      }
    } catch (e) {
      if (Environment.debugMode) {
        print('UserService.rofile error: $e');
      }
      return {
        'success': false,
        'message': 'Error updating profile: $e',
      };
    }
  }

  /// Change user password (returns Map for backward compatibility)
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final body = {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      };

      final response = await ApiService.post<Map<String, dynamic>>(
        ApiEndpoints.changePassword,
        body,
      );

      return {
        'success': response.isSuccess,
        'message': response.message,
      };
    } catch (e) {
      if (Environment.debugMode) {
        print('UserService.changePassword error: $e');
      }
      return {
        'success': false,
        'message': 'Error changing password: $e',
      };
    }
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user'); // Supprime les données utilisateur
  }
}
