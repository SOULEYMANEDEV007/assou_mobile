import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_endpoints.dart';
import '../models/event_type_model.dart';
import '../../utils/logger.dart';
import 'api_utils.dart';

class EventTypeService {
  /// Get all active event types for send voucher functionality
  static Future<List<EventType>> getActiveEventTypes({
    required String token,
  }) async {
    AppLogger.info('Fetching active event types', 'EVENT_TYPE_SERVICE');

    try {
      final uri = Uri.parse(ApiEndpoints.activeEventTypes);
      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(
        uri,
        headers: getAuthHeaders(token),
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] is List) {
          final eventTypes = (data['data'] as List)
              .map((json) => EventType.fromJson(json))
              .toList();

          AppLogger.info(
              'Successfully loaded ${eventTypes.length} active event types',
              'EVENT_TYPE_SERVICE');
          AppLogger.debug(
              'Event types: ${eventTypes.map((e) => '${e.id}:${e.libelle}(${e.icone})').join(', ')}',
              'EVENT_TYPE_SERVICE');

          return eventTypes;
        } else {
          AppLogger.warning(
              'API returned success=false or invalid data structure',
              'EVENT_TYPE_SERVICE');
          return [];
        }
      } else {
        AppLogger.error(
            'Failed to load active event types: HTTP ${response.statusCode}',
            'EVENT_TYPE_SERVICE');
        return [];
      }
    } catch (e) {
      AppLogger.error(
          'Exception loading active event types', 'EVENT_TYPE_SERVICE', e);
      return [];
    }
  }

  /// Get all event types (admin functionality)
  static Future<List<EventType>> getAllEventTypes({
    required String token,
  }) async {
    AppLogger.info('Fetching all event types', 'EVENT_TYPE_SERVICE');

    try {
      final uri = Uri.parse(ApiEndpoints.eventTypesList);
      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(
        uri,
        headers: getAuthHeaders(token),
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] is List) {
          final eventTypes = (data['data'] as List)
              .map((json) => EventType.fromJson(json))
              .toList();

          AppLogger.info('Successfully loaded ${eventTypes.length} event types',
              'EVENT_TYPE_SERVICE');

          return eventTypes;
        } else {
          return [];
        }
      } else {
        AppLogger.error(
            'Failed to load event types: HTTP ${response.statusCode}',
            'EVENT_TYPE_SERVICE');
        return [];
      }
    } catch (e) {
      AppLogger.error('Exception loading event types', 'EVENT_TYPE_SERVICE', e);
      return [];
    }
  }

  /// Get specific event type details
  static Future<EventType?> getEventTypeDetails({
    required String token,
    required String eventTypeId,
  }) async {
    AppLogger.info('Fetching event type details for ID: $eventTypeId',
        'EVENT_TYPE_SERVICE');

    try {
      final uri = Uri.parse(ApiEndpoints.getEventTypeDetails(eventTypeId));
      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(
        uri,
        headers: getAuthHeaders(token),
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final eventType = EventType.fromJson(data['data']);

          AppLogger.info('Successfully loaded event type: ${eventType.libelle}',
              'EVENT_TYPE_SERVICE');

          return eventType;
        } else {
          return null;
        }
      } else {
        AppLogger.error(
            'Failed to load event type details: HTTP ${response.statusCode}',
            'EVENT_TYPE_SERVICE');
        return null;
      }
    } catch (e) {
      AppLogger.error(
          'Exception loading event type details', 'EVENT_TYPE_SERVICE', e);
      return null;
    }
  }
}
