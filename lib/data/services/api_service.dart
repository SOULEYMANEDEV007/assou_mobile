// lib/data/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_response_model.dart';

class ApiService {
  static const String _tokenKey = 'auth_token';
  static String? _cachedToken;

  // Save auth token
  static Future<void> saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      _cachedToken = token;
    } catch (e) {
      throw Exception('Failed to save auth token: $e');
    }
  }

  // Get auth token
  static Future<String?> getAuthToken() async {
    if (_cachedToken != null) return _cachedToken;

    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString(_tokenKey);
      return _cachedToken;
    } catch (e) {
      return null;
    }
  }

  // Clear auth tokens
  static Future<void> clearAuthTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      _cachedToken = null;
    } catch (e) {
      throw Exception('Failed to clear auth tokens: $e');
    }
  }

  // Get auth headers
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // POST method
  static Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = requiresAuth
          ? await getAuthHeaders()
          : {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(body),
      );

      return ApiResponse<T>.fromResponse(response);
    } catch (e) {
      return ApiResponse<T>.error(
        'Network error: $e',
        statusCode: 500,
      );
    }
  }

  // GET method
  static Future<ApiResponse<T>> get<T>(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = requiresAuth
          ? await getAuthHeaders()
          : {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            };

      final response = await http.get(
        Uri.parse(endpoint),
        headers: headers,
      );

      return ApiResponse<T>.fromResponse(response);
    } catch (e) {
      return ApiResponse<T>.error(
        'Network error: $e',
        statusCode: 500,
      );
    }
  }

  // PUT method
  static Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = requiresAuth
          ? await getAuthHeaders()
          : {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            };

      final response = await http.put(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(body),
      );

      return ApiResponse<T>.fromResponse(response);
    } catch (e) {
      return ApiResponse<T>.error(
        'Network error: $e',
        statusCode: 500,
      );
    }
  }

  // DELETE method
  static Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = requiresAuth
          ? await getAuthHeaders()
          : {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            };

      final response = await http.delete(
        Uri.parse(endpoint),
        headers: headers,
      );

      return ApiResponse<T>.fromResponse(response);
    } catch (e) {
      return ApiResponse<T>.error(
        'Network error: $e',
        statusCode: 500,
      );
    }
  }
}
