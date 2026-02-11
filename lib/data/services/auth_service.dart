import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_endpoints.dart';
import 'package:ASSOU/pages/feature/notification/service/notification_service.dart';
import '../models/user_model.dart';
import '../models/api_response_model.dart';
import '../../utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  /// Register new user account
  static Future<ApiResponse> register({
    required String firstName,
    required String phoneNumber,
    required String country,
    required String password,
    String? lastName,
    String? email,
    String? address,
  }) async {
    AppLogger.info('Attempting user registration', 'AUTH_SERVICE');
    AppLogger.debug(
        'Registration data: firstName=$firstName, phoneNumber=$phoneNumber, country=$country',
        'AUTH_SERVICE');

    try {
      final body = {
        'first_name': firstName,
        'last_name': lastName ?? 'N/A',
        'phone_number': phoneNumber,
        'country': country,
        'password': password,
        'password_confirmation': password,
        'email': email ?? 'inconnu@exemple.com',
        'adresse': address ?? '',
      };

      final uri = Uri.parse(ApiEndpoints.register);
      AppLogger.apiCall('POST', uri.toString(), body: body);

      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      final apiResponse = ApiResponse.fromResponse(response);

      if (apiResponse.success) {
        AppLogger.auth('Registration successful',
            userId: apiResponse.data?.toString());
      } else {
        AppLogger.error(
            'Registration failed: ${apiResponse.message}', 'AUTH_SERVICE');
      }

      return apiResponse;
    } catch (e) {
      AppLogger.error('Registration exception', 'AUTH_SERVICE', e);
      return ApiResponse.error('Registration failed: ${e.toString()}');
    }
  }

  /// Login user with phone number or email and password
  static Future<ApiResponse> login(
      {required String login, // email or phone
      required String password,
      required String token}) async {
    AppLogger.info('Attempting user login', 'AUTH_SERVICE');
    AppLogger.debug('Login with: $login', 'AUTH_SERVICE');

    try {
      final body = {
        'phone_number': login,
        'password': password,
        'token': token
      };

      final uri = Uri.parse(ApiEndpoints.login);
      AppLogger.apiCall('POST', uri.toString(),
          body: {'login': login, 'password': '[REDACTED]', 'token': token});

      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      final apiResponse = ApiResponse.fromResponse(response);

      if (apiResponse.success) {
        AppLogger.auth('Login successful', userId: login);
      } else {
        AppLogger.error('Login failed: ${apiResponse.message}', 'AUTH_SERVICE');
      }

      return apiResponse;
    } catch (e) {
      AppLogger.error('Login exception', 'AUTH_SERVICE', e);
      return ApiResponse(
        success: false,
        message: 'Login failed: $e',
      );
    }
  }

  /// Get current authenticated user profile
  static Future<User?> getCurrentUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.userProfile),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update user profile
  static Future<ResponseUpdateProfil> updateProfile({
    required String token,
    required int userId,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? country,
    String? address,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (email != null) body['email'] = email;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (country != null) body['country'] = country;
      if (address != null) body['adresse'] = address;

      final response = await http.post(
        Uri.parse(ApiEndpoints.updateProfile),
        headers: _getAuthHeaders(token),
        body: jsonEncode(body),
      );

      // Vérifie si le code HTTP est OK
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ResponseUpdateProfil.fromJson(json);
      } else {
        // Retourne un objet avec success=false si le serveur répond mal
        return ResponseUpdateProfil(
          success: false,
          message: 'Erreur serveur: ${response.statusCode}',
        );
      }
    } catch (e) {
      print("Erreur : $e");
      // Retourne un objet indiquant l'échec
      return ResponseUpdateProfil(
        success: false,
        message: 'Une erreur est survenue: $e',
      );
    }
  }

  /// Change user password
  static Future<ApiResponse<void>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.changePassword),
        headers: _getAuthHeaders(token),
        body: jsonEncode({
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPassword,
        }),
      );
      return ApiResponse.fromResponse(response);
    } catch (e) {
      return ApiResponse.error('Password change failed: $e');
    }
  }

  /// Enhanced logout with proper error handling
  static Future<LogoutResponse> logout() async {
    try {
      final token = await _getStoredToken();
      if (token == null) {
        AppLogger.error(
            'No authentication token found for logout', 'AUTH_SERVICE');
        return LogoutResponse(
          success: false,
          message: 'Aucun token d\'authentification trouvé',
        );
      }

      AppLogger.auth('Enhanced logout requested', userId: 'token-***');
      AppLogger.apiCall('POST', ApiEndpoints.logout);

      final response = await http.post(
        Uri.parse(ApiEndpoints.logout),
        headers: _getAuthHeaders(token),
      );

      AppLogger.apiResponse(response.statusCode, ApiEndpoints.logout,
          response: response.body);

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        // Clear stored token
        await clearToken();
        AppLogger.auth('Logout successful');

        return LogoutResponse(
          success: true,
          message: data['message'],
          loggedOutAt: data['data']?['logged_out_at'] != null
              ? DateTime.parse(data['data']['logged_out_at'])
              : DateTime.now(),
        );
      } else {
        AppLogger.error('Logout failed: ${data['message']}', 'AUTH_SERVICE');
        return LogoutResponse(
          success: false,
          message: data['message'] ?? 'Erreur lors de la déconnexion',
        );
      }
    } catch (e) {
      AppLogger.error('Logout exception', 'AUTH_SERVICE', e);
      return LogoutResponse(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  /// Legacy logout method for backward compatibility
  static Future<ApiResponse<void>> logoutLegacy(String token) async {
    try {
      AppLogger.auth('Legacy logout requested', userId: token);
      final response = await http.post(
        Uri.parse(ApiEndpoints.logout),
        headers: _getAuthHeaders(token),
      );
      AppLogger.apiResponse(response.statusCode, ApiEndpoints.logout,
          response: response.body);
      return ApiResponse.fromResponse(response);
    } catch (e) {
      AppLogger.error('Legacy logout failed', 'AUTH', e);
      return ApiResponse.error('Logout failed: $e');
    }
  }

  /// Enhanced password reset request with rate limiting support
  static Future<PasswordResetResponse> requestPasswordReset(
      String phoneNumber) async {
    try {
      AppLogger.auth('Enhanced password reset requested', userId: phoneNumber);

      final uri = Uri.parse(ApiEndpoints.forgotPassword);
      final body = json.encode({'phone_number': phoneNumber});

      AppLogger.apiCall('POST', uri.toString(),
          body: {'phone_number': phoneNumber});

      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: body,
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        AppLogger.auth('Password reset request successful',
            userId: phoneNumber);
        return PasswordResetResponse(
          success: true,
          message: data['message'],
          expiresAt: data['data']?['expires_at'] != null
              ? DateTime.parse(data['data']['expires_at'])
              : null,
          expiresInMinutes: data['data']?['expires_in_minutes'],
        );
      } else if (response.statusCode == 429) {
        AppLogger.error('Password reset rate limited', 'AUTH_SERVICE');
        return PasswordResetResponse(
          success: false,
          message: data['message'],
          rateLimited: true,
        );
      } else {
        AppLogger.error('Password reset request failed: ${data['message']}',
            'AUTH_SERVICE');
        return PasswordResetResponse(
          success: false,
          message: data['message'] ?? 'Erreur lors de la demande',
        );
      }
    } catch (e) {
      AppLogger.error('Password reset request exception', 'AUTH_SERVICE', e);
      return PasswordResetResponse(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  /// Enhanced password reset with proper validation
  static Future<PasswordResetResponse> resetPassword({
    required String phoneNumber,
    required String resetCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      AppLogger.auth('Password reset with code', userId: phoneNumber);

      final uri = Uri.parse(ApiEndpoints.resetPassword);
      final body = json.encode({
        'phone_number': phoneNumber,
        'code': resetCode,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      });

      AppLogger.apiCall('POST', uri.toString(), body: {
        'phone_number': phoneNumber,
        'code': resetCode,
        'password': '[REDACTED]',
        'password_confirmation': '[REDACTED]'
      });

      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: body,
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        AppLogger.auth('Password reset successful', userId: phoneNumber);
        return PasswordResetResponse(
          success: true,
          message: data['message'],
          resetAt: data['data']?['reset_at'] != null
              ? DateTime.parse(data['data']['reset_at'])
              : DateTime.now(),
          requiresReLogin: true,
        );
      } else {
        AppLogger.error(
            'Password reset failed: ${data['message']}', 'AUTH_SERVICE');
        return PasswordResetResponse(
          success: false,
          message: data['message'] ?? 'Erreur lors de la réinitialisation',
        );
      }
    } catch (e) {
      AppLogger.error('Password reset exception', 'AUTH_SERVICE', e);
      return PasswordResetResponse(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  /// Legacy password reset methods for backward compatibility
  static Future<ApiResponse<void>> forgotPassword({
    required String phone_number,
  }) async {
    try {
      AppLogger.auth('Legacy password reset requested', userId: phone_number);
      final response = await http.post(
        Uri.parse(ApiEndpoints.forgotPassword),
        headers: _getHeaders(),
        body: jsonEncode({
          'phone_number': phone_number,
        }),
      );
      AppLogger.apiResponse(response.statusCode, ApiEndpoints.forgotPassword,
          response: response.body);
      return ApiResponse.fromResponse(response);
    } catch (e) {
      AppLogger.error('Password reset request failed', 'AUTH', e);
      return ApiResponse.error('Password reset request failed: $e');
    }
  }

  static Future<ApiResponse<void>> resetPasswordLegacy({
    required String phone_number,
    required String password,
    required String passwordConfirmation,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.resetPassword),
        headers: _getHeaders(),
        body: jsonEncode({
          'phone_number': phone_number,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'code': code,
        }),
      );

      return ApiResponse.fromResponse(response);
    } catch (e) {
      return ApiResponse.error('Password reset failed: $e');
    }
  }

  /// Helper method to get basic headers
  static Map<String, String> _getHeaders() {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  /// Helper method to get auth headers
  static Map<String, String> _getAuthHeaders(String token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Get stored token from SharedPreferences
  static Future<String?> _getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      AppLogger.error('Failed to get stored token', 'AUTH_SERVICE', e);
      return null;
    }
  }

  static Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      AppLogger.error('Failed to get stored token', 'AUTH_SERVICE', e);
      return null;
    }
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token'); // Supprime le token
    await prefs.remove('phone_number'); // Supprime le token
    await prefs.remove('notifications');

    NotificationService.notificationCount.value = 0;
  }
}

// Response models for enhanced authentication
class LogoutResponse {
  final bool success;
  final String message;
  final DateTime? loggedOutAt;

  LogoutResponse({
    required this.success,
    required this.message,
    this.loggedOutAt,
  });

  @override
  String toString() {
    return 'LogoutResponse(success: $success, message: $message, loggedOutAt: $loggedOutAt)';
  }
}

class PasswordResetResponse {
  final bool success;
  final String message;
  final DateTime? expiresAt;
  final int? expiresInMinutes;
  final DateTime? resetAt;
  final bool rateLimited;
  final bool requiresReLogin;

  PasswordResetResponse({
    required this.success,
    required this.message,
    this.expiresAt,
    this.expiresInMinutes,
    this.resetAt,
    this.rateLimited = false,
    this.requiresReLogin = false,
  });

  @override
  String toString() {
    return 'PasswordResetResponse(success: $success, message: $message, rateLimited: $rateLimited)';
  }
}
