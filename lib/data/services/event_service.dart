import 'dart:convert';
import 'package:http/http.dart' as http;

// Dans ton service (event_service.dart)
class EventService {
  static Future<List<dynamic>> getActiveEvents(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://ton-api.com/api/event-types?actif=1'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      print('Erreur lors du chargement des événements: $e');
      rethrow;
    }
  }
}
