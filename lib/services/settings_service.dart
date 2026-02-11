import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_endpoints.dart';
import '../utils/logger.dart';

class Setting {
  final String key;
  final String value;
  final String? type;
  final String? description;
  final bool? isPublic;

  Setting({
    required this.key,
    required this.value,
    this.type,
    this.description,
    this.isPublic,
  });

  factory Setting.fromJson(Map<String, dynamic> json) {
    return Setting(
      key: json['key'] as String,
      value: json['value']?.toString() ?? '',
      type: json['type']?.toString(),
      description: json['description']?.toString(),
      isPublic: json['is_public'] is bool
          ? json['is_public']
          : (json['is_public']?.toString().toLowerCase() == 'true'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'type': type,
      'description': description,
      'is_public': isPublic,
    };
  }
}

class SettingsService {
  static Map<String, dynamic>? _cachedSettings;

  static Future<Map<String, dynamic>> getPublicSettings(
      {bool forceRefresh = false}) async {
    if (_cachedSettings != null && !forceRefresh) {
      AppLogger.info('Using cached settings', 'SETTINGS_SERVICE');
      return _cachedSettings!;
    }

    try {
      AppLogger.info('Fetching public settings from API', 'SETTINGS_SERVICE');
      AppLogger.apiCall('GET', '${ApiEndpoints.baseUrl}/settings/public');

      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/settings/public'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      AppLogger.apiResponse(
          response.statusCode, '${ApiEndpoints.baseUrl}/settings/public',
          response: response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _cachedSettings = data['data'];
          AppLogger.info('Settings cached successfully', 'SETTINGS_SERVICE');
          return _cachedSettings!;
        }
      }

      AppLogger.error(
          'Failed to load settings from API: HTTP ${response.statusCode}',
          'SETTINGS_SERVICE');
      throw Exception('Failed to load settings');
    } catch (e) {
      AppLogger.error(
          'Exception loading settings from API', 'SETTINGS_SERVICE', e);
      // Return default values if API fails
      return _getDefaultSettings();
    }
  }

  static Map<String, dynamic> _getDefaultSettings() {
    AppLogger.info('Using default settings fallback', 'SETTINGS_SERVICE');
    return {
      'company_name': 'Assou',
      'app_version': '1.0.0',
      'support_email': 'support@assou.ci',
      'support_phone': '+225 XX XX XX XX',
      'company_logo': 'https://assou.ci/logo.png',
      'company_website': 'https://assou.ci',
      'app_store_url': 'https://apps.apple.com/app/assou',
      'play_store_url':
          'https://play.google.com/store/apps/details?id=com.assou.app',
      'primary_color': '#2E7D4A',
      'secondary_color': '#F8991D',
      'accent_color': '#10B981',
      'universel_bon': 'true',
      'percent_fees': '5',
      'otp_enabled': 'true',
      'otp_length': '6',
      'otp_expiry_minutes': '5',
      'cgu_link': 'https://assou.app/cgu',
      'tutorial_link': 'https://assou.app/#FAQ',
      'business_link': 'https://assou.app/business',
      'privacy_link': 'https://assou.app/politique-de-confidentialite/'
    };
  }

  // Helper methods for type-safe access
  static Future<String> getString(String key,
      {String defaultValue = ''}) async {
    try {
      final settings = await getPublicSettings();
      final settingData = settings[key];

      if (settingData == null) return defaultValue;

      String value = defaultValue;
      if (settingData is Map) {
        value = settingData['value']?.toString() ?? defaultValue;
      } else if (settingData is Setting) {
        value = settingData.value;
      } else {
        value = settingData.toString();
      }

      AppLogger.info('Retrieved setting $key: $value', 'SETTINGS_SERVICE');
      return value;
    } catch (e) {
      AppLogger.error('Failed to get setting $key', 'SETTINGS_SERVICE', e);
      return defaultValue;
    }
  }

  /// Returns the value of a setting as a String, or null if not found.
  static Future<String?> getSettingValue(String key,
      {String defaultValue = ''}) async {
    try {
      final settings = await getPublicSettings();
      final value = settings[key];
      if (value == null) {
        AppLogger.info('Setting $key not found', 'SETTINGS_SERVICE');
        return null;
      }

      // Handle different API response formats
      if (value is Map<String, dynamic>) {
        // If the API returns an object like {key: tutorial_link, value: https://..., type: string}
        if (value.containsKey('value')) {
          return value['value']?.toString();
        }
      }

      // If the value is a Setting object, extract its value property
      if (value is Setting) {
        return value.value.toString();
      }

      // Otherwise, just return its string representation
      return value.toString();
    } catch (e) {
      AppLogger.error(
          'Failed to get setting value for $key', 'SETTINGS_SERVICE', e);
      return null;
    }
  }

  static Future<int> getInt(String key, {int defaultValue = 0}) async {
    try {
      final settings = await getPublicSettings();
      final settingData = settings[key];

      if (settingData == null) return defaultValue;

      String rawValue = '0';
      if (settingData is Map) {
        rawValue = settingData['value']?.toString() ?? '0';
      } else if (settingData is Setting) {
        rawValue = settingData.value;
      } else {
        rawValue = settingData.toString();
      }

      final value = int.tryParse(rawValue) ?? defaultValue;
      AppLogger.info('Retrieved int setting $key: $value', 'SETTINGS_SERVICE');
      return value;
    } catch (e) {
      AppLogger.error('Failed to get int setting $key', 'SETTINGS_SERVICE', e);
      return defaultValue;
    }
  }

  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    try {
      final settings = await getPublicSettings();
      final settingData = settings[key];

      if (settingData == null) return defaultValue;

      String? rawValue;
      if (settingData is Map) {
        rawValue = settingData['value']?.toString().toLowerCase();
      } else if (settingData is Setting) {
        rawValue = settingData.value.toLowerCase();
      } else {
        rawValue = settingData.toString().toLowerCase();
      }

      final result = rawValue == 'true' || rawValue == '1';
      AppLogger.info(
          'Retrieved bool setting $key: $result', 'SETTINGS_SERVICE');
      return result;
    } catch (e) {
      AppLogger.error('Failed to get bool setting $key', 'SETTINGS_SERVICE', e);
      return defaultValue;
    }
  }

  static Future<Color> getColor(String key, {Color? defaultColor}) async {
    try {
      final settings = await getPublicSettings();
      final settingData = settings[key];

      String? colorString;
      if (settingData is Map) {
        colorString = settingData['value']?.toString();
      } else if (settingData is Setting) {
        colorString = settingData.value;
      } else {
        colorString = settingData?.toString();
      }

      if (colorString != null && colorString.startsWith('#')) {
        final color =
            Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
        AppLogger.info(
            'Retrieved color setting $key: $colorString', 'SETTINGS_SERVICE');
        return color;
      }
      return defaultColor ?? const Color(0xFF2E7D4A); // Default green
    } catch (e) {
      AppLogger.error(
          'Failed to get color setting $key', 'SETTINGS_SERVICE', e);
      return defaultColor ?? const Color(0xFF2E7D4A);
    }
  }

  static void clearCache() {
    _cachedSettings = null;
    AppLogger.info('Settings cache cleared', 'SETTINGS_SERVICE');
  }

  // Refresh settings when app comes back online
  static Future<void> refreshSettings() async {
    AppLogger.info('Refreshing settings from API', 'SETTINGS_SERVICE');
    await getPublicSettings(forceRefresh: true);
  }
}
