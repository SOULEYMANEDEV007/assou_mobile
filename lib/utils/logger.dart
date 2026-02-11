import 'package:flutter/foundation.dart';
import '../config/environment.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';

  static void debug(String message, [String? tag]) {
    _log(LogLevel.debug, message, tag);
  }

  static void info(String message, [String? tag]) {
    _log(LogLevel.info, message, tag);
  }

  static void warning(String message, [String? tag]) {
    _log(LogLevel.warning, message, tag);
  }

  static void error(String message, [String? tag, dynamic error]) {
    _log(LogLevel.error, message, tag);
    if (error != null) {
      _log(LogLevel.error, 'Error details: $error', tag);
    }
  }

  static void apiCall(String method, String url, {Map<String, dynamic>? body}) {
    if (!Environment.debugMode) return;
    
    info('🌐 API $method: $url', 'API');
    if (body != null && body.isNotEmpty) {
      debug('📤 Request body: $body', 'API');
    }
  }

  static void apiResponse(int statusCode, String url, {dynamic response}) {
    if (!Environment.debugMode) return;
    
    if (statusCode >= 200 && statusCode < 300) {
      info('✅ API Success ($statusCode): $url', 'API');
    } else {
      error('❌ API Error ($statusCode): $url', 'API');
    }
    
    if (response != null) {
      debug('📥 Response: $response', 'API');
    }
  }

  static void userAction(String action, {Map<String, dynamic>? data}) {
    info('👤 User: $action', 'USER');
    if (data != null && data.isNotEmpty) {
      debug('📊 Data: $data', 'USER');
    }
  }

  static void _log(LogLevel level, String message, String? tag) {
    if (!Environment.debugMode && level == LogLevel.debug) return;

    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final levelStr = level.name.toUpperCase().padRight(7);
    final tagStr = tag != null ? '[$tag] ' : '';
    final color = _getColor(level);
    
    if (kDebugMode) {
      print('$color$timestamp $levelStr $tagStr$message$_reset');
    }
  }

  static String _getColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return _cyan;
      case LogLevel.info:
        return _green;
      case LogLevel.warning:
        return _yellow;
      case LogLevel.error:
        return _red;
    }
  }

  // Log app lifecycle events
  static void appLifecycle(String event) {
    info('🔄 App: $event', 'LIFECYCLE');
  }

  // Log navigation events
  static void navigation(String from, String to) {
    info('🧭 Navigation: $from → $to', 'NAV');
  }

  // Log authentication events
  static void auth(String event, {String? userId}) {
    info('🔐 Auth: $event${userId != null ? ' (User: $userId)' : ''}', 'AUTH');
  }
}
