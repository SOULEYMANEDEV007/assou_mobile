import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_endpoints.dart';
import '../models/voucher_transfer_model.dart';
import '../models/api_response_model.dart';
import '../models/bon_achat_model.dart';
import '../../utils/logger.dart';
import 'api_utils.dart';

class VoucherTransferService {
  /// Transfer voucher to another user by ID
  static Future<ApiResponse<VoucherTransfer>> transferVoucher({
    required String token,
    required int paiementBonId,
    required int receiverId,
    String? transferMessage,
    int? eventTypeId,
  }) async {
    AppLogger.info('Transferring voucher to user ID: $receiverId', 'VOUCHER_TRANSFER_SERVICE');
    AppLogger.debug(
        'Parameters: paiementBonId=$paiementBonId, receiverId=$receiverId, eventTypeId=$eventTypeId',
        'VOUCHER_TRANSFER_SERVICE');

    try {
      final body = <String, dynamic>{
        'paiement_bon_id': paiementBonId,
        'receiver_id': receiverId,
      };

      if (transferMessage != null) {
        body['transfer_message'] = transferMessage;
      }

      if (eventTypeId != null) {
        body['event_type_id'] = eventTypeId;
      }

      final uri = Uri.parse('${ApiEndpoints.baseUrl}/voucher-transfers/transfer');
      AppLogger.apiCall('POST', uri.toString(), body: body);

      final response = await http.post(
        uri,
        headers: getAuthHeaders(token),
        body: jsonEncode(body),
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(), response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transfer = VoucherTransfer.fromJson(data['data']['transfer']);
        
        AppLogger.info('Successfully transferred voucher', 'VOUCHER_TRANSFER_SERVICE');
        return ApiResponse.success(data: transfer);
      } else {
        AppLogger.error('Failed to transfer voucher: HTTP ${response.statusCode}', 'VOUCHER_TRANSFER_SERVICE');
        final data = jsonDecode(response.body);
        return ApiResponse.error(data['message'] ?? 'Transfer failed');
      }
    } catch (e) {
      AppLogger.error('Exception during voucher transfer', 'VOUCHER_TRANSFER_SERVICE', e);
      return ApiResponse.error('Failed to transfer voucher: $e');
    }
  }

  /// Transfer voucher to phone number (registered or unregistered users)
  static Future<ApiResponse<VoucherTransfer>> transferVoucherByPhone({
    required String token,
    required int paiementBonId,
    required String recipientPhone,
    String? transferMessage,
    int? eventTypeId,
  }) async {
    AppLogger.info('Transferring voucher to phone: $recipientPhone', 'VOUCHER_TRANSFER_SERVICE');
    AppLogger.debug(
        'Parameters: paiementBonId=$paiementBonId, recipientPhone=$recipientPhone, eventTypeId=$eventTypeId',
        'VOUCHER_TRANSFER_SERVICE');

    try {
      final body = <String, dynamic>{
        'paiement_bon_id': paiementBonId,
        'recipient_phone': recipientPhone,
      };

      if (transferMessage != null) {
        body['transfer_message'] = transferMessage;
      }

      if (eventTypeId != null) {
        body['event_type_id'] = eventTypeId;
      }

      final uri = Uri.parse('${ApiEndpoints.baseUrl}/voucher-transfers/transfer');
      AppLogger.apiCall('POST', uri.toString(), body: body);

      final response = await http.post(
        uri,
        headers: getAuthHeaders(token),
        body: jsonEncode(body),
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(), response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transfer = VoucherTransfer.fromJson(data['data']['transfer']);
        
        AppLogger.info('Successfully transferred voucher to phone $recipientPhone', 'VOUCHER_TRANSFER_SERVICE');
        return ApiResponse.success(data: transfer);
      } else {
        AppLogger.error('Failed to transfer voucher: HTTP ${response.statusCode}', 'VOUCHER_TRANSFER_SERVICE');
        final data = jsonDecode(response.body);
        return ApiResponse.error(data['message'] ?? 'Transfer failed');
      }
    } catch (e) {
      AppLogger.error('Exception during voucher transfer by phone', 'VOUCHER_TRANSFER_SERVICE', e);
      return ApiResponse.error('Failed to transfer voucher: $e');
    }
  }

  /// Backward compatibility method for old sendBon functionality
  static Future<ApiResponse<VoucherTransfer>> sendVoucherByPhone({
    required String token,
    required String voucherSlug,
    required String recipientPhone,
    String? message,
    int? eventTypeId,
  }) async {
    AppLogger.info('Sending voucher by slug to phone: $recipientPhone', 'VOUCHER_TRANSFER_SERVICE');
    AppLogger.debug(
        'Parameters: voucherSlug=$voucherSlug, recipientPhone=$recipientPhone, eventTypeId=$eventTypeId',
        'VOUCHER_TRANSFER_SERVICE');

    try {
      final body = <String, dynamic>{
        'user_purchased_voucher': voucherSlug,
        'recipient_user_phone': recipientPhone,
      };

      if (message != null) {
        body['message'] = message;
      }

      if (eventTypeId != null) {
        body['event_type_id'] = eventTypeId;
      }

      final uri = Uri.parse('${ApiEndpoints.baseUrl}/voucher-transfers/transfer-by-phone');
      AppLogger.apiCall('POST', uri.toString(), body: body);

      final response = await http.post(
        uri,
        headers: getAuthHeaders(token),
        body: jsonEncode(body),
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(), response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transfer = VoucherTransfer.fromJson(data['data']['transfer']);
        
        AppLogger.info('Successfully sent voucher by slug', 'VOUCHER_TRANSFER_SERVICE');
        return ApiResponse.success(data: transfer);
      } else {
        AppLogger.error('Failed to send voucher: HTTP ${response.statusCode}', 'VOUCHER_TRANSFER_SERVICE');
        final data = jsonDecode(response.body);
        return ApiResponse.error(data['message'] ?? 'Send failed');
      }
    } catch (e) {
      AppLogger.error('Exception during voucher send by phone', 'VOUCHER_TRANSFER_SERVICE', e);
      return ApiResponse.error('Failed to send voucher: $e');
    }
  }

  /// Get transfer history for current user
  static Future<List<VoucherTransfer>> getTransferHistory({
    required String token,
    int limit = 50
  }) async {
    AppLogger.info('Fetching transfer history (limit: $limit)', 'VOUCHER_TRANSFER_SERVICE');

    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}/voucher-transfers/history?limit=$limit');
      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(uri, headers: getAuthHeaders(token));

      AppLogger.apiResponse(response.statusCode, uri.toString(), response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transfers = (data['data']['transfers'] as List)
            .map((json) => VoucherTransfer.fromJson(json))
            .toList();
        
        AppLogger.info('Successfully loaded ${transfers.length} transfers from history', 'VOUCHER_TRANSFER_SERVICE');
        return transfers;
      } else {
        AppLogger.error('Failed to load transfer history: HTTP ${response.statusCode}', 'VOUCHER_TRANSFER_SERVICE');
        return [];
      }
    } catch (e) {
      AppLogger.error('Exception loading transfer history', 'VOUCHER_TRANSFER_SERVICE', e);
      return [];
    }
  }

  /// Get pending transfers for current user
  static Future<List<VoucherTransfer>> getPendingTransfers({
    required String token,
  }) async {
    AppLogger.info('Fetching pending transfers', 'VOUCHER_TRANSFER_SERVICE');

    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}/voucher-transfers/pending');
      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(uri, headers: getAuthHeaders(token));

      AppLogger.apiResponse(response.statusCode, uri.toString(), response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transfers = (data['data']['transfers'] as List)
            .map((json) => VoucherTransfer.fromJson(json))
            .toList();
        
        AppLogger.info('Successfully loaded ${transfers.length} pending transfers', 'VOUCHER_TRANSFER_SERVICE');
        return transfers;
      } else {
        AppLogger.error('Failed to load pending transfers: HTTP ${response.statusCode}', 'VOUCHER_TRANSFER_SERVICE');
        return [];
      }
    } catch (e) {
      AppLogger.error('Exception loading pending transfers', 'VOUCHER_TRANSFER_SERVICE', e);
      return [];
    }
  }

  /// Get transfer statistics for current user
  static Future<Map<String, int>> getTransferStats({
    required String token,
  }) async {
    AppLogger.info('Fetching transfer statistics', 'VOUCHER_TRANSFER_SERVICE');

    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}/voucher-transfers/stats');
      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(uri, headers: getAuthHeaders(token));

      AppLogger.apiResponse(response.statusCode, uri.toString(), response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stats = <String, int>{
          'totalSent': (data['data']['stats']['total_sent'] ?? 0) as int,
          'totalReceived': (data['data']['stats']['total_received'] ?? 0) as int,
          'pendingSent': (data['data']['stats']['pending_sent'] ?? 0) as int,
          'pendingReceived': (data['data']['stats']['pending_received'] ?? 0) as int,
          'completedSent': (data['data']['stats']['completed_sent'] ?? 0) as int,
          'completedReceived': (data['data']['stats']['completed_received'] ?? 0) as int,
        };
        
        AppLogger.info('Successfully loaded transfer stats: $stats', 'VOUCHER_TRANSFER_SERVICE');
        return stats;
      } else {
        AppLogger.error('Failed to load transfer stats: HTTP ${response.statusCode}', 'VOUCHER_TRANSFER_SERVICE');
        return <String, int>{};
      }
    } catch (e) {
      AppLogger.error('Exception loading transfer stats', 'VOUCHER_TRANSFER_SERVICE', e);
      return <String, int>{};
    }
  }

  /// Get specific transfer details
  static Future<VoucherTransfer?> getTransferDetails({
    required String token,
    required String transferReference,
  }) async {
    AppLogger.info('Fetching transfer details for: $transferReference', 'VOUCHER_TRANSFER_SERVICE');

    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}/voucher-transfers/$transferReference');
      AppLogger.apiCall('GET', uri.toString());

      final response = await http.get(uri, headers: getAuthHeaders(token));

      AppLogger.apiResponse(response.statusCode, uri.toString(), response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transfer = VoucherTransfer.fromJson(data['data']['transfer']);
        
        AppLogger.info('Successfully loaded transfer details', 'VOUCHER_TRANSFER_SERVICE');
        return transfer;
      } else {
        AppLogger.error('Failed to load transfer details: HTTP ${response.statusCode}', 'VOUCHER_TRANSFER_SERVICE');
        return null;
      }
    } catch (e) {
      AppLogger.error('Exception loading transfer details', 'VOUCHER_TRANSFER_SERVICE', e);
      return null;
    }
  }

  /// Cancel a pending transfer
  static Future<ApiResponse<VoucherTransfer>> cancelTransfer({
    required String token,
    required String transferReference,
  }) async {
    AppLogger.info('Cancelling transfer: $transferReference', 'VOUCHER_TRANSFER_SERVICE');

    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}/voucher-transfers/$transferReference/cancel');
      AppLogger.apiCall('POST', uri.toString());

      final response = await http.post(uri, headers: getAuthHeaders(token));

      AppLogger.apiResponse(response.statusCode, uri.toString(), response: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transfer = VoucherTransfer.fromJson(data['data']['transfer']);
        
        AppLogger.info('Successfully cancelled transfer', 'VOUCHER_TRANSFER_SERVICE');
        return ApiResponse.success(data: transfer);
      } else {
        AppLogger.error('Failed to cancel transfer: HTTP ${response.statusCode}', 'VOUCHER_TRANSFER_SERVICE');
        final data = jsonDecode(response.body);
        return ApiResponse.error(data['message'] ?? 'Cancel failed');
      }
    } catch (e) {
      AppLogger.error('Exception cancelling transfer', 'VOUCHER_TRANSFER_SERVICE', e);
      return ApiResponse.error('Failed to cancel transfer: $e');
    }
  }

  /// Check if PaiementBon can be transferred (backward compatibility)
  static bool canTransferPaiementBon(PaiementBon voucher) {
    return voucher.etat == PaiementBon.ETAT_ACTIVE &&
           !voucher.isExpired;
  }
}
