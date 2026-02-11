import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_endpoints.dart';
import '../models/boutique_model.dart';
import '../models/bon_achat_model.dart';
//import '../models/api_response_model.dart';
import '../../utils/logger.dart';

class BoutiqueService {
  /// Get boutiques with available vouchers for home screen
  static Future<List<Boutique>> getBoutiquesWithVouchers(String token) async {
    AppLogger.info('Fetching boutiques with vouchers', 'BOUTIQUE_SERVICE');

    try {
      final uri = Uri.parse(ApiEndpoints.boutiquesWithVouchers);
      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(uri, headers: _getAuthHeaders(token));

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final boutiques = (data['data'] as List)
            .map((json) => Boutique.fromJson(json))
            .toList();

        AppLogger.info(
            'Successfully loaded ${boutiques.length} boutiques with vouchers',
            'BOUTIQUE_SERVICE');
        return boutiques;
      }

      AppLogger.error(
          'Failed to load boutiques with vouchers: HTTP ${response.statusCode}',
          'BOUTIQUE_SERVICE');
      return [];
    } catch (e) {
      AppLogger.error(
          'Exception loading boutiques with vouchers', 'BOUTIQUE_SERVICE', e);
      return [];
    }
  }

  /// Get all boutiques
  static Future<List<Boutique>> getBoutiques({
    required String token,
    int page = 1,
    int perPage = 15,
  }) async {
    AppLogger.info('Fetching all boutiques', 'BOUTIQUE_SERVICE');
    AppLogger.debug(
        'Parameters: page=$page, perPage=$perPage', 'BOUTIQUE_SERVICE');

    try {
      final uri = Uri.parse(ApiEndpoints.boutiquesList).replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );

      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(uri, headers: _getAuthHeaders(token));

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final boutiques = (data['data']['data'] as List)
            .map((json) => Boutique.fromJson(json))
            .toList();

        AppLogger.info('Successfully loaded ${boutiques.length} boutiques',
            'BOUTIQUE_SERVICE');
        AppLogger.debug(
            'Boutiques: ${boutiques.map((b) => '${b.id}:${b.name}').join(', ')}',
            'BOUTIQUE_SERVICE');

        return boutiques;
      }

      AppLogger.error('Failed to load boutiques: HTTP ${response.statusCode}',
          'BOUTIQUE_SERVICE');
      return [];
    } catch (e) {
      AppLogger.error('Exception loading boutiques', 'BOUTIQUE_SERVICE', e);
      return [];
    }
  }

  /// Get boutique details by ID
  static Future<Boutique?> getBoutiqueDetails({
    required String token,
    required int boutiqueSlug,
  }) async {
    AppLogger.info(
        'Fetching boutique details for ID: $boutiqueSlug', 'BOUTIQUE_SERVICE');

    try {
      final uri =
          Uri.parse(ApiEndpoints.getBoutiqueDetails(boutiqueSlug.toString()));
      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(uri, headers: _getAuthHeaders(token));

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final boutique = Boutique.fromJson(data['data']);

        AppLogger.info('Successfully loaded boutique details: ${boutique.name}',
            'BOUTIQUE_SERVICE');
        return boutique;
      }

      AppLogger.error(
          'Failed to load boutique details for ID $boutiqueSlug: HTTP ${response.statusCode}',
          'BOUTIQUE_SERVICE');
      return null;
    } catch (e) {
      AppLogger.error('Exception loading boutique details for ID $boutiqueSlug',
          'BOUTIQUE_SERVICE', e);
      return null;
    }
  }

  /// Get vouchers for a specific boutique
  static Future<List<BonAchat>> getBoutiqueVouchers({
    required String token,
    required String boutiqueSlug,
    int page = 1,
    int perPage = 15,
  }) async {
    AppLogger.info(
        'Fetching vouchers for boutique ID: $boutiqueSlug', 'BOUTIQUE_SERVICE');
    AppLogger.debug(
        'Parameters: page=$page, perPage=$perPage', 'BOUTIQUE_SERVICE');

    try {
      final uri =
          Uri.parse(ApiEndpoints.getVouchersByBoutique(boutiqueSlug.toString()))
              .replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );

      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(uri, headers: _getAuthHeaders(token));

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.debug('API Response structure: $data', 'BOUTIQUE_SERVICE');
        
        List<BonAchat> vouchers = [];
        
        // Try different response structures
        if (data['data'] != null && data['data']['bons_achat'] != null) {
          // Boutique vouchers response: data.data.bons_achat
          vouchers = (data['data']['bons_achat'] as List)
              .map((json) => BonAchat.fromJson(json))
              .toList();
        } else if (data['data'] != null) {
          if (data['data'] is Map && data['data']['data'] != null) {
            // Paginated response: data.data.data
            vouchers = (data['data']['data'] as List)
                .map((json) => BonAchat.fromJson(json))
                .toList();
          } else if (data['data'] is List) {
            // Direct array: data.data
            vouchers = (data['data'] as List)
                .map((json) => BonAchat.fromJson(json))
                .toList();
          }
        } else if (data is List) {
          // Direct array response
          vouchers = (data)
              .map((json) => BonAchat.fromJson(json))
              .toList();
        }

        AppLogger.info(
            'Successfully loaded ${vouchers.length} vouchers for boutique $boutiqueSlug',
            'BOUTIQUE_SERVICE');
        AppLogger.debug(
            'Voucher details: ${vouchers.map((v) => '${v.id}:${v.libelle}:${v.montantBon} FCFA').join(', ')}',
            'BOUTIQUE_SERVICE');
        return vouchers;
      }

      AppLogger.error(
          'Failed to load vouchers for boutique $boutiqueSlug: HTTP ${response.statusCode}',
          'BOUTIQUE_SERVICE');
      return [];
    } catch (e) {
      AppLogger.error('Exception loading vouchers for boutique $boutiqueSlug',
          'BOUTIQUE_SERVICE', e);
      return [];
    }
  }

  /// Get boutique types
  static Future<List<BoutiqueType>> getBoutiqueTypes(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.boutiqueTypes),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => BoutiqueType.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get boutiques by type
  static Future<List<Boutique>> getBoutiquesByType({
    required String token,
    required int typeId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.getBoutiquesByType(typeId.toString())),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => Boutique.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
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
