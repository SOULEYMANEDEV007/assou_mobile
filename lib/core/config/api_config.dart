import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://40b5cb2e29ce.ngrok-free.app/api/v1';
  static String get waveBaseUrl => dotenv.env['WAVE_BASE_URL'] ?? 'https://api.wave.com';
  
  static const Map<String, String> headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
  
  static int get timeout => int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static bool get debugMode => dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
}

/// Helper function to get auth headers
Map<String, String> getAuthHeaders(String token) {
  return {
    ...ApiConfig.headers,
    'Authorization': 'Bearer $token',
  };
}
