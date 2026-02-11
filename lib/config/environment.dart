import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static String get fileName => '.env';

  // Initialize environment
  static Future<void> init() async {
    await dotenv.load(fileName: fileName);
  }

  // API Configuration
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://assou.ebene.ci/api/v1/';
  static String get apiVersion => dotenv.env['API_VERSION'] ?? 'v1';
  static int get apiTimeout =>
      int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;

  // Authentication
  static String get jwtSecretKey => dotenv.env['JWT_SECRET_KEY'] ?? '';
  static int get tokenExpiry =>
      int.tryParse(dotenv.env['TOKEN_EXPIRY'] ?? '3600') ?? 3600;

  // Payment Configuration
  static String get waveApiKey => dotenv.env['WAVE_API_KEY'] ?? '';
  static String get waveSecretKey => dotenv.env['WAVE_SECRET_KEY'] ?? '';
  static String get waveBaseUrl =>
      dotenv.env['WAVE_BASE_URL'] ?? 'https://api.wave.com';

  // Application Settings
  static String get appName => dotenv.env['APP_NAME'] ?? 'ASSOU';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static bool get debugMode =>
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
  static String get logLevel => dotenv.env['LOG_LEVEL'] ?? 'info';

  // Feature Flags
  static bool get enableDarkMode =>
      dotenv.env['ENABLE_DARK_MODE']?.toLowerCase() == 'true';
  static bool get enableBiometricAuth =>
      dotenv.env['ENABLE_BIOMETRIC_AUTH']?.toLowerCase() == 'true';
  static bool get enablePushNotifications =>
      dotenv.env['ENABLE_PUSH_NOTIFICATIONS']?.toLowerCase() == 'true';
  static bool get enableAnalytics =>
      dotenv.env['ENABLE_ANALYTICS']?.toLowerCase() == 'true';

  // Storage Configuration
  static int get maxImageSize =>
      int.tryParse(dotenv.env['MAX_IMAGE_SIZE'] ?? '5242880') ?? 5242880;
  static int get cacheDuration =>
      int.tryParse(dotenv.env['CACHE_DURATION'] ?? '86400') ?? 86400;

  // Helper method to get full API URL
  static String getApiUrl(String endpoint) {
    // Remove leading slash if present to avoid double slashes
    final cleanEndpoint =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;

    // Si l'endpoint demande explicitement v2/
    if (cleanEndpoint.startsWith('v2/')) {
      // Si apiBaseUrl contient v1, on l'enlève pour pointer vers la racine /api/
      String base = apiBaseUrl;
      if (base.contains('/v1')) {
        base = base.replaceAll('/v1', '');
      }
      // Assurer qu'il n'y a pas de double slash
      if (base.endsWith('/')) {
        base = base.substring(0, base.length - 1);
      }
      return '$base/$cleanEndpoint';
    }

    return '$apiBaseUrl/$cleanEndpoint';
  }

  // Get the base URL without the /api/v1 part
  static String get rootUrl {
    try {
      final uri = Uri.parse(apiBaseUrl);
      String root =
          '${uri.scheme}://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}';
      return root;
    } catch (e) {
      return 'https://assou.ebene.ci';
    }
  }

  // Helper method to format image URLs
  static String? getImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http') || path.startsWith('data:')) return path;

    String cleanPath = path;

    if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }

    // URL encode the path to handle spaces and special characters
    return '$rootUrl${Uri.encodeFull(cleanPath)}';
  }

  // Helper method to check if we're in development mode
  static bool get isDevelopment => debugMode;
  static bool get isProduction => !debugMode;
}
