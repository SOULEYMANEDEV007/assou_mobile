import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_endpoints.dart';
import '../models/notification_model.dart';
import '../models/api_response_model.dart';

class NotificationService {
  /// Get user notifications with filtering
  static Future<List<AppNotification>> getNotifications({
    required String token,
    String? search,
    String? readStatus, // 'read', 'unread'
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (readStatus != null) queryParams['read_status'] = readStatus;

      final uri = Uri.parse(ApiEndpoints.notifications)
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _getAuthHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data']['data'] as List)
            .map((json) => AppNotification.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get unread notifications
  static Future<List<AppNotification>> getUnreadNotifications({
    required String token,
    int page = 1,
    int perPage = 15,
  }) async {
    return getNotifications(
      token: token,
      readStatus: 'unread',
      page: page,
      perPage: perPage,
    );
  }

  /// Get read notifications
  static Future<List<AppNotification>> getReadNotifications({
    required String token,
    int page = 1,
    int perPage = 15,
  }) async {
    return getNotifications(
      token: token,
      readStatus: 'read',
      page: page,
      perPage: perPage,
    );
  }

  /// Mark specific notification as read
  static Future<ApiResponse<AppNotification>> markAsRead({
    required String token,
    required String notificationSlug,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.markNotificationRead(notificationSlug)),
        headers: _getAuthHeaders(token),
      );

      return ApiResponse.fromResponse(response);
    } catch (e) {
      return ApiResponse.error('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<ApiResponse<void>> markAllAsRead({
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.markAllNotificationsRead),
        headers: _getAuthHeaders(token),
      );

      return ApiResponse.fromResponse(response);
    } catch (e) {
      return ApiResponse.error('Failed to mark all notifications as read: $e');
    }
  }

  /// Get notification details by slug
  static Future<AppNotification?> getNotificationDetails({
    required String token,
    required String notificationSlug,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.getNotificationDetails(notificationSlug)),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AppNotification.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiEndpoints.notifications}?read_status=unread&per_page=1'),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['total'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Search notifications
  static Future<List<AppNotification>> searchNotifications({
    required String token,
    required String query,
    int page = 1,
    int perPage = 15,
  }) async {
    return getNotifications(
      token: token,
      search: query,
      page: page,
      perPage: perPage,
    );
  }

  /// Helper method to get auth headers
  static Map<String, String> _getAuthHeaders(String token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
