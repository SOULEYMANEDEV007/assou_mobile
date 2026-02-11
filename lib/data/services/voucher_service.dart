import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ASSOU/data/models/expired_bon.dart';
import 'package:ASSOU/data/services/user_service.dart';
import '../../config/api_endpoints.dart';
import '../models/bon_achat_model.dart';
import '../models/api_response_model.dart';
import '../models/voucher_transfer_model.dart';
import '../../utils/logger.dart';
import 'api_utils.dart';

class VoucherService {
  /// Get available vouchers for purchase
  static Future<List<BonAchat>> getAvailableVouchers({
    required String token,
    int? boutiqueId,
    int page = 1,
    int perPage = 10,
  }) async {
    AppLogger.info('Fetching available vouchers', 'VOUCHER_SERVICE');
    AppLogger.debug(
        'Parameters: boutiqueId=$boutiqueId, page=$page, perPage=$perPage',
        'VOUCHER_SERVICE');

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (boutiqueId != null) {
        queryParams['boutique_id'] = boutiqueId.toString();
      }

      final uri = Uri.parse(ApiEndpoints.availableVouchers)
          .replace(queryParameters: queryParams);

      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(uri, headers: getAuthHeaders(token));

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final vouchers = (data['data']['data'] as List)
            .map((json) => BonAchat.fromJson(json))
            .toList();

        AppLogger.info(
            'Successfully loaded ${vouchers.length} available vouchers',
            'VOUCHER_SERVICE');
        AppLogger.debug(
            'Vouchers: ${vouchers.map((v) => '${v.id}:${v.montantBon}FCFA').join(', ')}',
            'VOUCHER_SERVICE');

        return vouchers;
      } else {
        AppLogger.error(
            'Failed to load available vouchers: HTTP ${response.statusCode}',
            'VOUCHER_SERVICE');
        return [];
      }
    } catch (e) {
      AppLogger.error(
          'Exception loading available vouchers', 'VOUCHER_SERVICE', e);
      return [];
    }
  }

  /// Get vouchers by boutique
  static Future<List<BonAchat>> getVouchersByBoutique({
    required String token,
    required String boutiqueId,
  }) async {
    AppLogger.info(
        'Fetching vouchers for boutique: $boutiqueId', 'VOUCHER_SERVICE');

    try {
      final uri = Uri.parse(ApiEndpoints.getVouchersByBoutique(boutiqueId));
      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(
        uri,
        headers: getAuthHeaders(token),
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<BonAchat> vouchers;

        // Handle both API endpoint responses
        if (data['data'] is Map && data['data']['bons_achat'] != null) {
          // First endpoint: /bons-achat/boutique/{boutiqueId}
          vouchers = (data['data']['bons_achat'] as List)
              .map((json) => BonAchat.fromJson(json))
              .where((voucher) =>
                  voucher.isAvailable) // Only show available vouchers
              .toList();
        } else if (data['data'] is Map && data['data']['data'] != null) {
          // Second endpoint: /boutiques/{boutiqueId}/bons-achat
          vouchers = (data['data']['data'] as List)
              .map((json) => BonAchat.fromJson(json))
              .where((voucher) =>
                  voucher.isAvailable) // Only show available vouchers
              .toList();
        } else {
          vouchers = [];
        }

        AppLogger.info(
            'Successfully loaded ${vouchers.length} available vouchers for boutique $boutiqueId',
            'VOUCHER_SERVICE');
        AppLogger.debug(
            'Available vouchers: ${vouchers.map((v) => '${v.id}:${v.montantBon}FCFA').join(', ')}',
            'VOUCHER_SERVICE');

        return vouchers;
      } else {
        AppLogger.error(
            'Failed to load vouchers for boutique $boutiqueId: HTTP ${response.statusCode}',
            'VOUCHER_SERVICE');
        return [];
      }
    } catch (e) {
      AppLogger.error('Exception loading vouchers for boutique $boutiqueId',
          'VOUCHER_SERVICE', e);
      return [];
    }
  }

  /// Get user's purchased vouchers
  static Future<List<PaiementBon>> getMyVouchers(String token,
      {int page = 1, int perPage = 150}) async {
    AppLogger.info('Fetching user purchased vouchers', 'VOUCHER_SERVICE');
    AppLogger.debug(
        'Parameters: page=$page, perPage=$perPage', 'VOUCHER_SERVICE');

    try {
      final uri = Uri.parse(ApiEndpoints.myPurchasedVouchers).replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );
      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(
        uri,
        headers: getAuthHeaders(token),
      );

      //print('response api direct : ${response.body}');

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<PaiementBon> vouchers;

        // Handle the nested data structure
        if (data['data'] is Map && data['data']['data'] != null) {
          vouchers = (data['data']['data'] as List)
              .map((json) => PaiementBon.fromJson(json))
              .toList();
        } else if (data['data'] is List) {
          vouchers = (data['data'] as List)
              .map((json) => PaiementBon.fromJson(json))
              .toList();
        } else {
          vouchers = [];
        }

        AppLogger.info(
            'Successfully loaded ${vouchers.length} purchased vouchers',
            'VOUCHER_SERVICE');
        AppLogger.debug(
            'Purchased vouchers: ${vouchers.map((v) => '${v.id}:${v.montantBon}FCFA').join(', ')}',
            'VOUCHER_SERVICE');

        return vouchers;
      } else {
        AppLogger.error(
            'Failed to load purchased vouchers: HTTP ${response.statusCode}',
            'VOUCHER_SERVICE');
        return [];
      }
    } catch (e) {
      AppLogger.error(
          'Exception loading purchased vouchers', 'VOUCHER_SERVICE', e);
      return [];
    }
  }

  /// Get user's received vouchers
  static Future<List<PaiementBon>> getMyReceivedVouchers(String token,
      {int page = 1, int perPage = 50}) async {
    AppLogger.info('Fetching user received vouchers', 'VOUCHER_SERVICE');
    AppLogger.debug(
        'Parameters: page=$page, perPage=$perPage', 'VOUCHER_SERVICE');

    try {
      final uri = Uri.parse(ApiEndpoints.myReceivedVouchers).replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );
      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(
        uri,
        headers: getAuthHeaders(token),
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<PaiementBon> vouchers;

        // Handle the nested data structure
        if (data['data'] is Map && data['data']['data'] != null) {
          vouchers = (data['data']['data'] as List)
              .map((json) => PaiementBon.fromJson(json))
              .toList();
        } else if (data['data'] is List) {
          vouchers = (data['data'] as List)
              .map((json) => PaiementBon.fromJson(json))
              .toList();
        } else {
          vouchers = [];
        }

        AppLogger.info(
            'Successfully loaded ${vouchers.length} received vouchers',
            'VOUCHER_SERVICE');
        AppLogger.debug(
            'Received vouchers: ${vouchers.map((v) => '${v.id}:${v.montantBon}FCFA').join(', ')}',
            'VOUCHER_SERVICE');

        return vouchers;
      } else {
        AppLogger.error(
            'Failed to load received vouchers: HTTP ${response.statusCode}',
            'VOUCHER_SERVICE');
        return [];
      }
    } catch (e) {
      AppLogger.error(
          'Exception loading received vouchers', 'VOUCHER_SERVICE', e);
      return [];
    }
  }

  /// Get user's active vouchers from dedicated API endpoint
  static Future<List<PaiementBon>> getMyActiveVouchers(String token,
      {int page = 1, int perPage = 50}) async {
    AppLogger.info('Fetching user active vouchers from API', 'VOUCHER_SERVICE');
    AppLogger.debug(
        'Parameters: page=$page, perPage=$perPage', 'VOUCHER_SERVICE');

    try {
      final uri = Uri.parse(ApiEndpoints.myActiveVouchers).replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );
      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(
        uri,
        headers: getAuthHeaders(token),
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.debug(
            'Active vouchers API response structure: $data', 'VOUCHER_SERVICE');

        List<PaiementBon> vouchers = [];

        // Handle paginated response from bon-actifs endpoint
        if (data['data'] != null && data['data']['data'] != null) {
          vouchers = (data['data']['data'] as List)
              .map((json) => PaiementBon.fromJson(json))
              .toList();
        } else if (data['data'] is List) {
          // Fallback for direct array
          vouchers = (data['data'] as List)
              .map((json) => PaiementBon.fromJson(json))
              .toList();
        }

        AppLogger.info(
            'Successfully loaded ${vouchers.length} active vouchers from API',
            'VOUCHER_SERVICE');
        AppLogger.debug(
            'Active vouchers: ${vouchers.map((v) => '${v.id}:${v.montantBon}FCFA').join(', ')}',
            'VOUCHER_SERVICE');

        return vouchers;
      } else {
        AppLogger.error(
            'Failed to load active vouchers: HTTP ${response.statusCode}',
            'VOUCHER_SERVICE');
        return [];
      }
    } catch (e) {
      AppLogger.error(
          'Exception loading active vouchers', 'VOUCHER_SERVICE', e);
      return [];
    }
  }

  /// Get user's sent vouchers
  static Future<List<PaiementBon>> getMySentVouchers(String token,
      {int page = 1, int perPage = 50}) async {
    AppLogger.info('Fetching user sent vouchers', 'VOUCHER_SERVICE');
    AppLogger.debug(
        'Parameters: page=$page, perPage=$perPage', 'VOUCHER_SERVICE');

    try {
      final uri = Uri.parse(ApiEndpoints.mySentVouchers).replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );
      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(
        uri,
        headers: getAuthHeaders(token),
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<PaiementBon> vouchers;

        // Handle the nested data structure
        if (data['data'] is Map && data['data']['data'] != null) {
          vouchers = (data['data']['data'] as List)
              .map((json) => PaiementBon.fromJson(json))
              .toList();
        } else if (data['data'] is List) {
          vouchers = (data['data'] as List)
              .map((json) => PaiementBon.fromJson(json))
              .toList();
        } else {
          vouchers = [];
        }

        AppLogger.info('Successfully loaded ${vouchers.length} sent vouchers',
            'VOUCHER_SERVICE');
        AppLogger.debug(
            'Sent vouchers: ${vouchers.map((v) => '${v.id}:${v.montantBon}FCFA').join(', ')}',
            'VOUCHER_SERVICE');

        return vouchers;
      } else {
        AppLogger.error(
            'Failed to load sent vouchers: HTTP ${response.statusCode}',
            'VOUCHER_SERVICE');
        return [];
      }
    } catch (e) {
      AppLogger.error('Exception loading sent vouchers', 'VOUCHER_SERVICE', e);
      return [];
    }
  }

  /// Send voucher to another user
  static Future<ApiResponse<void>> sendVoucher({
    required String token,
    required String voucherSlug, // Le slug du paiement_bon
    required String recipientUserPhone, // Nom exact de champ
    int? eventTypeId, // Choix du type d'évènement (now enabled)
    String? message,
  }) async {
    AppLogger.info('Sending voucher to user', 'VOUCHER_SERVICE');
    AppLogger.debug(
        'Parameters: voucherSlug=$voucherSlug, recipientUserPhone=$recipientUserPhone, eventTypeId=$eventTypeId, message=$message',
        'VOUCHER_SERVICE');

    try {
      final body = <String, dynamic>{
        'user_purchased_voucher': voucherSlug, // Champ exact
        'recipient_user_phone': recipientUserPhone, // Champ exact
      };

      if (eventTypeId != null) {
        body['event_type_id'] = eventTypeId;
      }

      if (message != null) {
        body['message'] = message;
      }

      final uri = Uri.parse(ApiEndpoints.sendVoucher);
      AppLogger.apiCall('POST', uri.toString(), body: body);

      final response = await http.post(
        uri,
        headers: getAuthHeaders(token),
        body: jsonEncode(body),
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      final apiResponse = ApiResponse.fromResponse(response);

      if (apiResponse.success) {
        AppLogger.info('Successfully sent voucher to $recipientUserPhone',
            'VOUCHER_SERVICE');
      } else {
        AppLogger.error('Failed to send voucher: ${apiResponse.message}',
            'VOUCHER_SERVICE');
      }

      return apiResponse;
    } catch (e) {
      AppLogger.error('Exception sending voucher', 'VOUCHER_SERVICE', e);
      return ApiResponse.error('Failed to send voucher: $e');
    }
  }

  /// Utiliser un bon d'achat (scanner QR + slug du bon)
  static Future<ApiResponse> useVoucher({
    required String token,
    required String codeBoutique, // Récupéré depuis le QR code (boutique slug)
    required String slugBonPaiement, // Slug du paiement_bon
    String? message, // Optionnel (message au vendeur par ex.)
  }) async {
    AppLogger.info('Using voucher API call initiated', 'VOUCHER_SERVICE');
    AppLogger.debug(
      'Raw input parameters: codeBoutique=$codeBoutique, slugBonPaiement=$slugBonPaiement, message=$message',
      'VOUCHER_SERVICE',
    );

    try {
      String finalCodeBoutique = codeBoutique;

      // Logique pour extraire le code boutique s'il est contenu dans un JSON (QR code structuré)
      if (codeBoutique.trim().startsWith('{')) {
        try {
          AppLogger.debug(
              'Attempting to parse JSON codeBoutique...', 'VOUCHER_SERVICE');
          final Map<String, dynamic> decoded = jsonDecode(codeBoutique);
          if (decoded.containsKey('code_boutique')) {
            finalCodeBoutique = decoded['code_boutique'].toString();
            AppLogger.info(
                'Extracted code_boutique from JSON: $finalCodeBoutique',
                'VOUCHER_SERVICE');
          } else if (decoded.containsKey('boutique_code')) {
            finalCodeBoutique = decoded['boutique_code'].toString();
            AppLogger.info(
                'Extracted boutique_code from JSON: $finalCodeBoutique',
                'VOUCHER_SERVICE');
          }
        } catch (e) {
          AppLogger.warning(
              'Failed to parse JSON codeBoutique, using raw string',
              'VOUCHER_SERVICE');
        }
      }

      // Corps de la requête
      // Note: On envoie les deux variantes au cas où le backend attend l'un ou l'autre
      final body = <String, dynamic>{
        'boutique_code': finalCodeBoutique,
        'code_boutique':
            finalCodeBoutique, // Variante possible attendue par le backend
        'bon_id': slugBonPaiement,
      };

      if (message != null) {
        body['message'] = message;
      }

      // URL API
      final uri = Uri.parse(ApiEndpoints.useVoucher);
      AppLogger.apiCall('POST', uri.toString(), body: body);
      AppLogger.debug('Final Payload: ${jsonEncode(body)}', 'VOUCHER_SERVICE');

      // Requête HTTP
      final response = await http.post(
        uri,
        headers: getAuthHeaders(token),
        body: jsonEncode(body),
      );

      // Log réponse ultra détaillé
      AppLogger.apiResponse(
        response.statusCode,
        uri.toString(),
        response: response.body,
      );

      AppLogger.debug('Raw Response Body: ${response.body}', 'VOUCHER_SERVICE');

      // Conversion en objet ApiResponse
      final apiResponse = ApiResponse.fromResponse(response);

      if (apiResponse.success) {
        AppLogger.info('Voucher successfully used ✅', 'VOUCHER_SERVICE');
      } else {
        AppLogger.error(
          'Voucher use failed ❌: ${apiResponse.message} (Status: ${response.statusCode})',
          'VOUCHER_SERVICE',
        );
      }

      return apiResponse;
    } catch (e) {
      AppLogger.error('Exception while using voucher', 'VOUCHER_SERVICE', e);
      return ApiResponse.error('Failed to use voucher: $e');
    }
  }

  /// Get vouchers that are expiring soon (within 30 days)
  static Future<List<ExpiredBon>> getMyExpiringVouchers(String token) async {
    AppLogger.info('Fetching vouchers expiring soon', 'VOUCHER_SERVICE');

    try {
      final uri = Uri.parse(
          ApiEndpoints.myExpiringSoonVouchers); // Update this endpoint
      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(
        uri,
        headers: getAuthHeaders(token),
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.debug(
            'Expiring vouchers API response: $data', 'VOUCHER_SERVICE');
        final List<ExpiredBon> vouchers;

        // Handle the new API response structure: data.expiringSoonVouchers
        if (data['data'] is Map &&
            data['data']['expiringSoonVouchers'] != null) {
          vouchers = (data['data']['expiringSoonVouchers'] as List)
              .map((json) => ExpiredBon.fromJson(json))
              .toList();
        } else if (data['data'] is List) {
          // Fallback for direct array
          vouchers = (data['data'] as List)
              .map((json) => ExpiredBon.fromJson(json))
              .toList();
        } else if (data['data'] is Map && data['data']['data'] != null) {
          // Fallback for paginated structure
          vouchers = (data['data']['data'] as List)
              .map((json) => ExpiredBon.fromJson(json))
              .toList();
        } else {
          vouchers = [];
        }

        AppLogger.info(
            'Successfully loaded ${vouchers.length} expiring vouchers',
            'VOUCHER_SERVICE');
        AppLogger.debug(
            'Expiring vouchers: ${vouchers.map((v) => '${v.id}:${v.montant}FCFA:${v.joursAvantExpiration}days').join(', ')}',
            'VOUCHER_SERVICE');

        return vouchers;
      } else {
        AppLogger.error(
            'Failed to load expiring vouchers: HTTP ${response.statusCode}',
            'VOUCHER_SERVICE');
        return [];
      }
    } catch (e) {
      AppLogger.error(
          'Exception loading expiring vouchers', 'VOUCHER_SERVICE', e);
      return [];
    }
  }

  /// Get vouchers that are already expired
  static Future<List<PaiementBon>> getMyExpiredVouchers(String token) async {
    AppLogger.info('Fetching expired vouchers', 'VOUCHER_SERVICE');

    try {
      final uri = Uri.parse(ApiEndpoints.myExpiredVouchers);
      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(
        uri,
        headers: getAuthHeaders(token),
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<PaiementBon> vouchers;

        // Handle the nested data structure
        if (data['data'] is Map && data['data']['data'] != null) {
          vouchers = (data['data']['data'] as List)
              .map((json) => PaiementBon.fromJson(json))
              .toList();
        } else if (data['data'] is List) {
          vouchers = (data['data'] as List)
              .map((json) => PaiementBon.fromJson(json))
              .toList();
        } else {
          vouchers = [];
        }

        AppLogger.info(
            'Successfully loaded ${vouchers.length} expired vouchers',
            'VOUCHER_SERVICE');
        AppLogger.debug(
            'Expired vouchers: ${vouchers.map((v) => '${v.id}:${v.montantBon}FCFA:${v.joursDepuisExpiration}days').join(', ')}',
            'VOUCHER_SERVICE');

        return vouchers;
      } else {
        AppLogger.error(
            'Failed to load expired vouchers: HTTP ${response.statusCode}',
            'VOUCHER_SERVICE');
        return [];
      }
    } catch (e) {
      AppLogger.error(
          'Exception loading expired vouchers', 'VOUCHER_SERVICE', e);
      return [];
    }
  }

  /// Redeem voucher using QR code
  static Future<RedeemResponse> redeemVoucher({
    required String token,
    required String codeBon,
    required String boutiqueCode,
  }) async {
    AppLogger.info('Redeeming voucher', 'VOUCHER_SERVICE');
    AppLogger.debug('Parameters: codeBon=$codeBon, boutiqueCode=$boutiqueCode',
        'VOUCHER_SERVICE');

    try {
      final body = {
        'code_bon': codeBon,
        'boutique_code': boutiqueCode,
      };

      final uri = Uri.parse(ApiEndpoints.redeemVoucher);
      AppLogger.apiCall('POST', uri.toString(), body: body);

      final response = await http.post(
        uri,
        headers: getAuthHeaders(token),
        body: jsonEncode(body),
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      final redeemResponse = RedeemResponse.fromResponse(response);

      if (redeemResponse.success) {
        AppLogger.info(
            'Successfully redeemed voucher: $codeBon', 'VOUCHER_SERVICE');
      } else {
        AppLogger.error('Failed to redeem voucher: ${redeemResponse.message}',
            'VOUCHER_SERVICE');
      }

      return redeemResponse;
    } catch (e) {
      AppLogger.error('Exception redeeming voucher', 'VOUCHER_SERVICE', e);
      return RedeemResponse(
        success: false,
        message: 'Failed to redeem voucher: $e',
      );
    }
  }

  /// Get voucher details by ID
  static Future<BonAchat?> getVoucherDetails({
    required String token,
    required int voucherId,
  }) async {
    AppLogger.info(
        'Fetching voucher details for ID: $voucherId', 'VOUCHER_SERVICE');

    try {
      final uri =
          Uri.parse(ApiEndpoints.getVoucherDetails(voucherId.toString()));
      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(
        uri,
        headers: getAuthHeaders(token),
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final voucher = BonAchat.fromJson(data['data']);

        AppLogger.info('Successfully loaded voucher details for ID: $voucherId',
            'VOUCHER_SERVICE');
        AppLogger.debug(
            'Voucher details: ${voucher.libelle} - ${voucher.montantBon}FCFA',
            'VOUCHER_SERVICE');

        return voucher;
      } else {
        AppLogger.error(
            'Failed to load voucher details for ID $voucherId: HTTP ${response.statusCode}',
            'VOUCHER_SERVICE');
        return null;
      }
    } catch (e) {
      AppLogger.error('Exception loading voucher details for ID $voucherId',
          'VOUCHER_SERVICE', e);
      return null;
    }
  }

  // ----------- MODIFICATION POUR WAVE -----------
  static Future<Map<String, dynamic>> initierPaiementWave(
    List<Map<String, int>> bonsAchat,
    int montantTotal,
    String? waveNumber,
  ) async {
    AppLogger.info('🚀 Initiating Wave payment', 'VOUCHER_SERVICE');

    try {
      // 1. Validation préalable
      if (bonsAchat.isEmpty) {
        AppLogger.error('❌ No vouchers selected', 'VOUCHER_SERVICE');
        throw Exception('Aucun bon sélectionné');
      }

      AppLogger.info('📊 Input parameters:', 'VOUCHER_SERVICE');
      AppLogger.info(
          '   • Original amount: $montantTotal FCFA', 'VOUCHER_SERVICE');
      AppLogger.info('   • Selected vouchers count: ${bonsAchat.length}',
          'VOUCHER_SERVICE');
      AppLogger.info(
          '   • Wave number: ${waveNumber ?? 'null'}', 'VOUCHER_SERVICE');

      // Log each voucher in detail
      AppLogger.info('📋 Detailed voucher breakdown:', 'VOUCHER_SERVICE');
      for (int i = 0; i < bonsAchat.length; i++) {
        final bon = bonsAchat[i];
        AppLogger.info(
            '   Voucher ${i + 1}: ID=${bon['id_bon_achat']}, Quantity=${bon['quantite']}',
            'VOUCHER_SERVICE');
      }

      // On force le montant à 5F pour Wave, comme demandé
      int montantWave = 5;
      AppLogger.info(
          '💰 Wave amount forced to: $montantWave FCFA (for testing)',
          'VOUCHER_SERVICE');

      final token = await UserService.getAuthToken();
      if (token == null) {
        AppLogger.error(
            '❌ User not authenticated - no token', 'VOUCHER_SERVICE');
        throw Exception('Utilisateur non authentifié');
      }

      AppLogger.info(
          '🔐 Auth token retrieved successfully (length: ${token.length})',
          'VOUCHER_SERVICE');

      // Prepare the request body
      final requestBody = {
        'bons': bonsAchat,
        'montant': montantWave, // On force 5F
        'wave_number': waveNumber,
      };

      // Log the complete request details
      final uri = Uri.parse(ApiEndpoints.createPayment);
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      AppLogger.info('🌐 API Request Details:', 'VOUCHER_SERVICE');
      AppLogger.info('   • URL: ${uri.toString()}', 'VOUCHER_SERVICE');
      AppLogger.info('   • Method: POST', 'VOUCHER_SERVICE');
      AppLogger.info('   • Headers:', 'VOUCHER_SERVICE');
      headers.forEach((key, value) {
        if (key == 'Authorization') {
          AppLogger.info(
              '     $key: Bearer ***${value.substring(value.length - 10)}',
              'VOUCHER_SERVICE');
        } else {
          AppLogger.info('     $key: $value', 'VOUCHER_SERVICE');
        }
      });

      final jsonBody = jsonEncode(requestBody);
      AppLogger.info('📤 Request Body (JSON):', 'VOUCHER_SERVICE');
      AppLogger.info(jsonBody, 'VOUCHER_SERVICE');

      // Also log the raw request body structure
      AppLogger.info('📤 Request Body Structure:', 'VOUCHER_SERVICE');
      AppLogger.info('   • bons: $bonsAchat', 'VOUCHER_SERVICE');
      AppLogger.info('   • montant: $montantWave', 'VOUCHER_SERVICE');
      AppLogger.info('   • wave_number: $waveNumber', 'VOUCHER_SERVICE');

      // 2. Appel API
      AppLogger.info('📡 Sending HTTP request...', 'VOUCHER_SERVICE');
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonBody,
      );

      // Log response details immediately
      AppLogger.info('📥 API Response received:', 'VOUCHER_SERVICE');
      AppLogger.info(
          '   • Status Code: ${response.statusCode}', 'VOUCHER_SERVICE');
      AppLogger.info('   • Response Headers:', 'VOUCHER_SERVICE');
      response.headers.forEach((key, value) {
        AppLogger.info('     $key: $value', 'VOUCHER_SERVICE');
      });
      AppLogger.info('   • Response Body:', 'VOUCHER_SERVICE');
      AppLogger.info(response.body, 'VOUCHER_SERVICE');

      // 3. Gestion de la réponse
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);

        // Validation robuste de la réponse
        if (responseData['data'] == null) {
          throw Exception('Réponse API incomplète: data manquant');
        }

        final waveUrl = responseData['data']['wave_launch_url']?.toString();

        // On force le montant de paiement à 5F
        int montantPaiement = 5;

        // Vérification de l'URL Wave
        if (waveUrl == null || !waveUrl.startsWith('https://pay.wave.com')) {
          throw Exception('URL Wave invalide: $waveUrl');
        }

        // Correction du montant dans l'URL si nécessaire
        // On remplace le paramètre "a=" dans l'URL par 5
        String correctedWaveUrl = waveUrl;
        final montantRegExp = RegExp(r'a=(\d+)');
        if (montantRegExp.hasMatch(waveUrl)) {
          correctedWaveUrl =
              waveUrl.replaceFirst(montantRegExp, 'a=$montantPaiement');
        } else {
          // Si "a=" n'est pas présent, on l'ajoute avant le premier "&" ou à la fin
          if (waveUrl.contains('?')) {
            correctedWaveUrl =
                waveUrl.replaceFirst('?', '?a=$montantPaiement&');
          } else {
            correctedWaveUrl = '$waveUrl?a=$montantPaiement';
          }
        }

        // Vérification du montant dans l'URL (pour éviter le bug "Montant invalide dans l'URL Wave: null XOF")
        final montantDansUrl =
            RegExp(r'a=(\d+)').firstMatch(correctedWaveUrl)?.group(1);
        if (montantDansUrl == null ||
            int.tryParse(montantDansUrl) == null ||
            int.parse(montantDansUrl) <= 0) {
          throw Exception(
              'Montant invalide dans l\'URL Wave: $montantDansUrl XOF');
        }

        AppLogger.info('Paiement Wave initié avec succès', 'VOUCHER_SERVICE');
        return {
          ...responseData,
          'data': {
            ...responseData['data'],
            'wave_launch_url': correctedWaveUrl,
            // On force le montant_paiement à 5 pour la cohérence
            'paiement': {
              ...?responseData['data']['paiement'],
              'montant_paiement': montantPaiement,
            },
          },
        };
      } else {
        // Detailed error logging for 500 errors
        AppLogger.error('❌ API Request failed with HTTP ${response.statusCode}',
            'VOUCHER_SERVICE');
        AppLogger.error(
            '   • Error response body: ${response.body}', 'VOUCHER_SERVICE');
        AppLogger.error(
            '   • Request URL was: ${uri.toString()}', 'VOUCHER_SERVICE');
        AppLogger.error('   • Request body was: $jsonBody', 'VOUCHER_SERVICE');

        // Try to parse error response if possible
        try {
          final errorData = jsonDecode(response.body);
          AppLogger.error(
              '   • Parsed error message: ${errorData['message'] ?? 'No message'}',
              'VOUCHER_SERVICE');
          AppLogger.error(
              '   • Error details: ${errorData['errors'] ?? errorData['error'] ?? 'No details'}',
              'VOUCHER_SERVICE');
        } catch (parseError) {
          AppLogger.error(
              '   • Could not parse error response as JSON', 'VOUCHER_SERVICE');
        }

        throw Exception(
            'Erreur serveur: HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.error('💥 Exception during Wave payment:', 'VOUCHER_SERVICE');
      AppLogger.error(
          '   • Exception type: ${e.runtimeType}', 'VOUCHER_SERVICE');
      AppLogger.error('   • Exception message: $e', 'VOUCHER_SERVICE');

      // Log stack trace if available
      if (e is Error) {
        AppLogger.error('   • Stack trace: ${e.stackTrace}', 'VOUCHER_SERVICE');
      }

      rethrow;
    }
  }

  /// Get vouchers by status using new 4-status system
  static Future<List<PaiementBon>> getVouchersByStatus({
    required String token,
    required int status,
  }) async {
    AppLogger.info('Fetching vouchers with status: $status', 'VOUCHER_SERVICE');

    try {
      final allVouchers = await getMyVouchers(token);
      final filteredVouchers =
          allVouchers.where((voucher) => voucher.etat == status).toList();

      AppLogger.info(
          'Filtered ${filteredVouchers.length} vouchers with status $status from ${allVouchers.length} total',
          'VOUCHER_SERVICE');

      return filteredVouchers;
    } catch (e) {
      AppLogger.error(
          'Exception loading vouchers by status $status', 'VOUCHER_SERVICE', e);
      return [];
    }
  }

  static Future<ApiResponse<void>> remerciementEmeteurBon({
    required String token,
    required int paiement_bon_id,
    String? message,
    int? sender_id,
    required String libelle,
  }) async {
    const String source = 'VOUCHER_SERVICE';
    AppLogger.info(
        '💝 Envoi d\'un remerciement pour le bon ID: $paiement_bon_id', source);
    AppLogger.debug('Message de remerciement: ${message ?? "Défaut"}', source);

    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}/remerciment');
      final body = {
        'paiement_bon_id': paiement_bon_id,
        'message': message ??
            "Merci beaucoup pour ce bon d'achat, ton geste me touche énormément 🙏.",
      };

      AppLogger.apiCall('POST', uri.toString(), body: body);

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      final apiResponse = ApiResponse.fromResponse(response);

      if (apiResponse.success) {
        AppLogger.info('✅ Remerciement envoyé avec succès', source);
      } else {
        AppLogger.error(
            '❌ Échec de l\'envoi du remerciement: ${apiResponse.message}',
            source);
      }

      return apiResponse;
    } catch (e) {
      AppLogger.error(
          '💥 Exception lors de l\'envoi du remerciement', source, e);
      return ApiResponse.error('Échec de l\'envoi du remerciement : $e');
    }
  }

  /// Get active vouchers using new constants
  static Future<List<PaiementBon>> getActiveVouchers(
      {required String token}) async {
    return getVouchersByStatus(token: token, status: PaiementBon.ETAT_ACTIVE);
  }

  /// Get used vouchers using new constants
  static Future<List<PaiementBon>> getUsedVouchers(
      {required String token}) async {
    return getVouchersByStatus(token: token, status: PaiementBon.ETAT_UTILISE);
  }

  /// Get expired vouchers using new constants
  static Future<List<PaiementBon>> getExpiredVouchersNew(
      {required String token}) async {
    return getVouchersByStatus(token: token, status: PaiementBon.ETAT_EXPIRE);
  }

  /// Get sent vouchers using new constants
  static Future<List<PaiementBon>> getSentVouchersNew(
      {required String token}) async {
    return getVouchersByStatus(token: token, status: PaiementBon.ETAT_SENT);
  }

  /// Check if voucher can be transferred using new status system
  static bool canTransferVoucher(PaiementBon voucher) {
    return voucher.etat == PaiementBon.ETAT_ACTIVE && !voucher.isExpired;
  }

  /// Check if voucher can be used/redeemed using new status system
  static bool canUseVoucher(PaiementBon voucher) {
    return voucher.etat == PaiementBon.ETAT_ACTIVE && !voucher.isExpired;
  }
}

class RedeemResponse {
  final bool success;
  final PaiementBon? voucher;
  final String message;

  RedeemResponse({
    required this.success,
    this.voucher,
    required this.message,
  });

  factory RedeemResponse.fromResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      final success = data['success'] ?? response.statusCode < 400;

      return RedeemResponse(
        success: success,
        voucher: success && data['data'] != null
            ? PaiementBon.fromJson(data['data'])
            : null,
        message: data['message'] ?? 'Redeem response',
      );
    } catch (e) {
      AppLogger.error('Failed to parse redeem response', 'VOUCHER_SERVICE', e);
      return RedeemResponse(
        success: false,
        message: 'Failed to parse redeem response: $e',
      );
    }
  }
}
