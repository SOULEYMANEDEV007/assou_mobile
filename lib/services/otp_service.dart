import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_endpoints.dart';
import '../utils/logger.dart';
import '../data/models/user_model.dart' as UserData;

class OtpService {
  // Send OTP to phone number
  static Future<OtpResponse> sendOtp(String phoneNumber,
      {String action = 'registration'}) async {
    try {
      AppLogger.info('Sending OTP to $phoneNumber for $action', 'OTP_SERVICE');

      final uri = Uri.parse('${ApiEndpoints.baseUrl}/otp/send');
      final body = json.encode({
        'phone_number': phoneNumber,
        'action': action,
      });

      AppLogger.apiCall('POST', uri.toString());

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        AppLogger.info('OTP sent successfully to $phoneNumber', 'OTP_SERVICE');
        return OtpResponse(
          success: true,
          message: data['message'],
          userId: data['data']['user_id'],
          expiresAt: DateTime.parse(data['data']['expires_at']),
          expiresInMinutes: data['data']['expires_in_minutes'],
        );
      } else {
        AppLogger.error(
            'Failed to send OTP: ${data['message']}', 'OTP_SERVICE');
        return OtpResponse(
          success: false,
          message: data['message'] ?? 'Erreur lors de l\'envoi de l\'OTP',
        );
      }
    } catch (e) {
      AppLogger.error(
          'Exception sending OTP to $phoneNumber', 'OTP_SERVICE', e);
      return OtpResponse(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  // Verify OTP code
  static Future<OtpResponse> verifyOtp(String phoneNumber, String otpCode,
      {String action = 'registration'}) async {
    try {
      AppLogger.info('Verifying OTP for $phoneNumber', 'OTP_SERVICE');

      final uri = Uri.parse('${ApiEndpoints.baseUrl}/otp/verify');
      final body = json.encode({
        'phone_number': phoneNumber,
        'otp_code': otpCode,
        'action': action,
      });

      AppLogger.apiCall('POST', uri.toString());

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        AppLogger.info(
            'OTP verified successfully for $phoneNumber', 'OTP_SERVICE');
        return OtpResponse(
          success: true,
          message: data['message'],
          isPhoneVerified: data['data']['is_phone_verified'],
          verifiedAt: data['data']['verified_at'] != null
              ? DateTime.parse(data['data']['verified_at'])
              : null,
        );
      } else {
        AppLogger.error(
            'Failed to verify OTP: ${data['message']}', 'OTP_SERVICE');
        return OtpResponse(
          success: false,
          message: data['message'] ?? 'Code OTP invalide',
        );
      }
    } catch (e) {
      AppLogger.error(
          'Exception verifying OTP for $phoneNumber', 'OTP_SERVICE', e);
      return OtpResponse(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  // Complete registration after OTP verification
  static Future<RegistrationResponse> completeRegistration({
    required String phoneNumber,
    required String firstName,
    required String lastName,
    required String password,
    required String passwordConfirmation,
    String? email,
  }) async {
    try {
      AppLogger.info('Completing registration for $phoneNumber', 'OTP_SERVICE');

      final uri =
          Uri.parse('${ApiEndpoints.baseUrl}/otp/complete-registration');
      final body = json.encode({
        'phone_number': phoneNumber,
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (email != null) 'email': email,
      });

      AppLogger.apiCall('POST', uri.toString());

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success']) {
        AppLogger.info('Registration completed successfully for $phoneNumber',
            'OTP_SERVICE');
        return RegistrationResponse(
          success: true,
          message: data['message'],
          user: UserData.User.fromJson(data['data']['user']),
          token: data['data']['token'],
        );
      } else {
        AppLogger.error('Failed to complete registration: ${data['message']}',
            'OTP_SERVICE');
        return RegistrationResponse(
          success: false,
          message: data['message'] ?? 'Erreur lors de l\'inscription',
        );
      }
    } catch (e) {
      AppLogger.error('Exception completing registration for $phoneNumber',
          'OTP_SERVICE', e);
      return RegistrationResponse(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  // Resend OTP
  static Future<OtpResponse> resendOtp(String phoneNumber,
      {String action = 'registration'}) async {
    AppLogger.info('Resending OTP to $phoneNumber', 'OTP_SERVICE');
    return await sendOtp(phoneNumber, action: action);
  }

  // Get OTP status
  static Future<OtpStatusResponse> getOtpStatus(String phoneNumber) async {
    try {
      AppLogger.info('Getting OTP status for $phoneNumber', 'OTP_SERVICE');

      final uri = Uri.parse(
          '${ApiEndpoints.baseUrl}/otp/status?phone_number=$phoneNumber');
      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final otpStatus = data['data']['otp_status'];
        AppLogger.info('Retrieved OTP status for $phoneNumber', 'OTP_SERVICE');
        return OtpStatusResponse(
          success: true,
          hasPendingOtp: otpStatus['has_pending_otp'] ?? false,
          isExpired: otpStatus['is_expired'] ?? true,
          expiresAt: otpStatus['expires_at'] != null
              ? DateTime.parse(otpStatus['expires_at'])
              : null,
          remainingMinutes: otpStatus['remaining_minutes'] ?? 0,
          isPhoneVerified: otpStatus['is_phone_verified'] ?? false,
        );
      } else {
        AppLogger.error('Failed to get OTP status: HTTP ${response.statusCode}',
            'OTP_SERVICE');
        return OtpStatusResponse(success: false);
      }
    } catch (e) {
      AppLogger.error(
          'Exception getting OTP status for $phoneNumber', 'OTP_SERVICE', e);
      return OtpStatusResponse(success: false);
    }
  }
}

// Response models
class OtpResponse {
  final bool success;
  final String message;
  final int? userId;
  final DateTime? expiresAt;
  final int? expiresInMinutes;
  final bool? isPhoneVerified;
  final DateTime? verifiedAt;

  OtpResponse({
    required this.success,
    required this.message,
    this.userId,
    this.expiresAt,
    this.expiresInMinutes,
    this.isPhoneVerified,
    this.verifiedAt,
  });

  @override
  String toString() {
    return 'OtpResponse(success: $success, message: $message, userId: $userId)';
  }
}

class OtpStatusResponse {
  final bool success;
  final bool hasPendingOtp;
  final bool isExpired;
  final DateTime? expiresAt;
  final int remainingMinutes;
  final bool isPhoneVerified;

  OtpStatusResponse({
    required this.success,
    this.hasPendingOtp = false,
    this.isExpired = true,
    this.expiresAt,
    this.remainingMinutes = 0,
    this.isPhoneVerified = false,
  });

  @override
  String toString() {
    return 'OtpStatusResponse(success: $success, hasPendingOtp: $hasPendingOtp, isExpired: $isExpired)';
  }
}

class RegistrationResponse {
  final bool success;
  final String message;
  final UserData.User? user;
  final String? token;

  RegistrationResponse({
    required this.success,
    required this.message,
    this.user,
    this.token,
  });

  @override
  String toString() {
    return 'RegistrationResponse(success: $success, message: $message, user: ${user?.phoneNumber})';
  }
}
