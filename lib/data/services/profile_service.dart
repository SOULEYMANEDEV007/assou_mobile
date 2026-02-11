import 'dart:convert';
import 'dart:io';
import 'package:ASSOU/data/models/user_model.dart';

import 'api_service.dart';
import '../../config/api_endpoints.dart';
import '../../config/environment.dart';
import 'user_service.dart';

// Import old User model for backward compatibility

/// ProfileService handles user profile-specific operations
class ProfileService {
  // ========================================
  // PROFILE DATA METHODS
  // ========================================

  /// Get user profile from server
  static Future<User?> getUserProfile() async {
    return await UserService.getUserProfile();
  }

  /// Update user profile with new data (returns Map for backward compatibility)
  static Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
    String? country,
    String? photo,
  }) async {
    return await UserService.updateProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phone,
      country: country,
      address: address,
      photo: photo,
    );
  }

  /// Legacy method for getting profile data (returns Map)
  static Future<Map<String, dynamic>?> getProfilData() async {
    try {
      final user = await getUserProfile();
      if (user != null) {
        return {
          'success': true,
          'user': user.toJson(),
        };
      }
      return {
        'success': false,
        'message': 'Unable to retrieve profile',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ========================================
  // PASSWORD MANAGEMENT
  // ========================================

  /// Change user password (returns Map for backward compatibility)
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await UserService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  // ========================================
  // IMAGE UPLOAD
  // ========================================

  /// Upload profile image (returns Map for backward compatibility)
  static Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    try {
      // Convert image to base64 for now
      // TODO: Implement proper multipart file upload
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await ApiService.post<Map<String, dynamic>>(
        ApiEndpoints.uploadImage,
        {
          'image': base64Image,
          'type': 'profile',
        },
      );

      if (response.isSuccess && response.data != null) {
        final imageUrl = response.data!['image_url'] ?? response.data!['url'];
        return {
          'success': true,
          'message': response.message,
          'data': {
            'image_url': imageUrl,
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
        print('ProfileService.uploadProfileImage error: $e');
      }
      return {
        'success': false,
        'message': 'Error uploading image: $e',
      };
    }
  }

  // ========================================
  // ACCOUNT MANAGEMENT
  // ========================================

  /// Delete user account (returns Map for backward compatibility)
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await ApiService.delete<Map<String, dynamic>>(
        ApiEndpoints.deleteAccount,
      );

      if (response.isSuccess) {
        // Clear local data
        await UserService.clearAllData();
        return {
          'success': true,
          'message': response.message,
        };
      } else {
        return {
          'success': false,
          'message': response.message,
        };
      }
    } catch (e) {
      if (Environment.debugMode) {
        print('ProfileService.deleteAccount error: $e');
      }
      return {
        'success': false,
        'message': 'Error deleting account: $e',
      };
    }
  }

  // ========================================
  // SETTINGS MANAGEMENT
  // ========================================

  /// Update user preferences/settings (returns Map for backward compatibility)
  static Future<Map<String, dynamic>> updateSettings({
    String? language,
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    Map<String, dynamic>? customSettings,
  }) async {
    try {
      final settingsData = <String, dynamic>{};
      if (language != null) settingsData['language'] = language;
      if (notificationsEnabled != null)
        settingsData['notifications_enabled'] = notificationsEnabled;
      if (darkModeEnabled != null)
        settingsData['dark_mode_enabled'] = darkModeEnabled;
      if (customSettings != null) settingsData.addAll(customSettings);

      final response = await ApiService.post<Map<String, dynamic>>(
        ApiEndpoints.updateUserSettings,
        settingsData,
      );

      if (response.isSuccess) {
        return {
          'success': true,
          'message': response.message,
          'data': response.data ?? {},
        };
      } else {
        return {
          'success': false,
          'message': response.message,
        };
      }
    } catch (e) {
      if (Environment.debugMode) {
        print('ProfileService.updateSettings error: $e');
      }
      return {
        'success': false,
        'message': 'Error updating settings: $e',
      };
    }
  }
}
