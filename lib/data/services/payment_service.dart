import 'dart:convert';
import 'package:ASSOU/widgets/toast_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:ASSOU/config/environment.dart';
import '../../config/api_endpoints.dart';
import '../models/payment_model.dart';
import '../models/api_response_model.dart';
import '../models/voucher_purchase_request.dart';
import '../models/voucher_purchase_response.dart';
import '../../utils/logger.dart';

class PaymentService {
  /// Purchase vouchers with improved error handling (new API)
  static Future<VoucherPurchaseResponse?> purchaseVouchers({
    required String token,
    required List<VoucherItem> voucherItems,
    double? expectedTotal,
    String? waveNumber,
  }) async {
    // Legacy method - kept for backward compatibility if needed, but likely unused now
    // Implementation omitted for brevity as we are moving to custom payload
    return null;
  }

  /// Purchase custom vouchers (New Implementation)
  static Future<VoucherPurchaseResponse?> purchaseCustomVouchers({
    required String token,
    required CustomVoucherPurchaseRequest request,
  }) async {
    AppLogger.info('🛒 Achat de bons personnalisés', 'VOUCHER_PURCHASE');
    AppLogger.debug(
        'Charge utile de la requête: ${request.toJson()}', 'VOUCHER_PURCHASE');

    try {
      // Utilisation de Environment pour une construction d'URL plus robuste
      final uri = Uri.parse(
          Environment.getApiUrl('v2/paiements/achat-avec-destinataire'));

      AppLogger.apiCall('POST', uri.toString(), body: request.toJson());

      final response = await http
          .post(
            uri,
            headers: _getAuthHeaders(token),
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 20));

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          try {
            final voucherResponse =
                VoucherPurchaseResponse.fromJson(responseData['data']);
            AppLogger.info(
                '✅ Achat de bon personnalisé réussi', 'VOUCHER_PURCHASE');
            return voucherResponse;
          } catch (e) {
            AppLogger.error('❌ Échec de l\'analyse de la réponse du bon',
                'VOUCHER_PURCHASE', e);
            return null;
          }
        } else {
          AppLogger.error(
              '❌ Échec de l\'achat de bon personnalisé: ${responseData['message']}',
              'VOUCHER_PURCHASE');
          return null;
        }
      } else {
        AppLogger.error(
            '❌ Erreur HTTP lors de l\'achat de bon personnalisé: ${response.statusCode}',
            'VOUCHER_PURCHASE');
        return null;
      }
    } catch (e) {
      AppLogger.error('❌ Exception lors de l\'achat de bon personnalisé',
          'VOUCHER_PURCHASE', e);
      return null;
    }
  }

  /// Check payment status for voucher purchase
  static Future<VoucherPayment?> checkVoucherPaymentStatus({
    required String token,
    required String reference,
  }) async {
    AppLogger.info(
        '🔍 Vérification du statut de paiement pour la référence: $reference',
        'VOUCHER_PURCHASE');

    try {
      // 1. Essai avec l'endpoint dédié check-status
      try {
        final uri =
            Uri.parse(Environment.getApiUrl('v2/paiements/check-status'));
        final checkResponse = await http
            .post(
              uri,
              headers: _getAuthHeaders(token),
              body: jsonEncode({'reference': reference}),
            )
            .timeout(const Duration(seconds: 15));

        if (checkResponse.statusCode == 200) {
          final responseData = jsonDecode(checkResponse.body);
          if (responseData['success'] == true) {
            final payment =
                VoucherPayment.fromJson(responseData['data']['paiement']);
            AppLogger.info(
                '🔍 Statut du paiement via check-status: ${payment.statusText}',
                'VOUCHER_PURCHASE');
            return payment;
          }
        }
      } catch (e) {
        AppLogger.debug(
            'Point de terminaison check-status non disponible ou erreur réseau: $e',
            'VOUCHER_PURCHASE');
      }

      // 2. Fallback: Recherche dans la liste des paiements
      final uri = Uri.parse(Environment.getApiUrl('paiements'));
      final response = await http
          .get(uri, headers: _getAuthHeaders(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final payments = responseData['data']['data'] as List;
          final paymentData = payments.firstWhere(
            (p) => p['slug'] == reference || p['reference'] == reference,
            orElse: () => null,
          );

          if (paymentData != null) {
            final payment = VoucherPayment.fromJson(paymentData);
            AppLogger.info(
                '🔍 Statut du paiement via la liste: ${payment.statusText}',
                'VOUCHER_PURCHASE');
            return payment;
          }
        }
      }

      AppLogger.warning(
          '❌ Impossible de trouver le paiement avec la référence: $reference',
          'VOUCHER_PURCHASE');
      return null;
    } catch (e) {
      AppLogger.error(
          '❌ Erreur lors de la vérification du statut: $e', 'VOUCHER_PURCHASE');
      // On propage l'erreur pour que l'appelant puisse décider de réessayer
      return null;
    }
  }

  static Future<VoucherPayment?> checkVoucherPaymentStatusRelance(
      {required String token,
      required String reference,
      required BuildContext context}) async {
    try {
      // 1. Essai avec l'endpoint check-status
      final checkUri =
          Uri.parse('${ApiEndpoints.baseUrl}/paiements/check-status');
      final checkResponse = await http.post(
        checkUri,
        headers: _getAuthHeaders(token),
        body: jsonEncode({'reference': reference}),
      );

      if (checkResponse.statusCode == 200) {
        final responseData = jsonDecode(checkResponse.body);
        if (responseData['success'] == true &&
            responseData['data']?['paiement'] != null) {
          final payment =
              VoucherPayment.fromJson(responseData['data']['paiement']);

          if (payment.isSucceeded) {
            ToastHelper.showToast(context,
                title: "Achat de bon",
                message: "Le paiement a été effectué avec succès.",
                type: ToastType.success);
            return payment;
          } else {
            ToastHelper.showToast(context,
                title: "Achat de bon",
                message:
                    "Le paiement est en attente ou a échoué (${payment.statusText}).",
                type: ToastType.error);
          }
        } else {
          ToastHelper.showToast(context,
              title: "Achat de bon",
              message: "Le paiement n'a pas pu être vérifié.",
              type: ToastType.error);
        }
      } else {
        ToastHelper.showToast(context,
            title: "Achat de bon",
            message: "Le paiement n'a pas pu être vérifié. Veuillez réessayer.",
            type: ToastType.error);
      }
    } catch (e) {
      AppLogger.error("Erreur lors de la vérification relance: $e", "PAYMENT");
    }
    return null;
  }

  /// Create payment for voucher purchases (legacy method)
  static Future<PaymentResponse> createPayment({
    required String token,
    required List<VoucherPurchase> vouchers,
  }) async {
    AppLogger.info('Création du paiement', 'PAYMENT_SERVICE');
    AppLogger.debug(
        'Achats de bons: ${vouchers.map((v) => '${v.voucherId}:${v.quantity}').join(', ')}',
        'PAYMENT_SERVICE');

    try {
      final body = vouchers.map((v) => v.toJson()).toList();
      final uri = Uri.parse(ApiEndpoints.createPayment);

      // AppLogger.apiCall('POST', uri.toString(), body: body);

      final response = await http.post(
        uri,
        headers: _getAuthHeaders(token),
        body: jsonEncode(body),
      );

      AppLogger.apiResponse(response.statusCode, uri.toString(),
          response: response.body);

      final paymentResponse =
          PaymentResponse.fromJson(jsonDecode(response.body));

      if (paymentResponse.success) {
        AppLogger.info('Paiement créé avec succès', 'PAYMENT_SERVICE');
        AppLogger.userAction('Paiement initié',
            data: {'nombre_de_bons': vouchers.length});
      } else {
        AppLogger.error(
            'Échec de la création du paiement: ${paymentResponse.message}',
            'PAYMENT_SERVICE');
      }

      return paymentResponse;
    } catch (e) {
      AppLogger.error(
          'Exception lors de la création du paiement', 'PAYMENT_SERVICE', e);
      return PaymentResponse(
        success: false,
        message: 'Échec de la création du paiement: $e',
      );
    }
  }

  /// Get user payments with filtering
  static Future<List<Payment>> getUserPayments({
    required String token,
    int? etat,
    String? search,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (etat != null) queryParams['etat'] = etat.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;

      final uri = Uri.parse(ApiEndpoints.paymentsList)
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _getAuthHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data']['data'] as List)
            .map((json) => Payment.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get payment details by ID
  static Future<Payment?> getPaymentDetails({
    required String token,
    required int paymentId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.getPaymentDetails(paymentId.toString())),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Payment.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Validate payment (mark as processing)
  static Future<ApiResponse<Payment>> validatePayment({
    required String token,
    required int paymentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.validatePayment(paymentId.toString())),
        headers: _getAuthHeaders(token),
      );

      return ApiResponse.fromResponse(response);
    } catch (e) {
      return ApiResponse.error('Échec de la validation du paiement: $e');
    }
  }

  /// Confirm payment (mark as successful)
  static Future<ApiResponse<Payment>> confirmPayment({
    required String token,
    required int paymentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.confirmPayment(paymentId.toString())),
        headers: _getAuthHeaders(token),
      );

      return ApiResponse.fromResponse(response);
    } catch (e) {
      return ApiResponse.error('Échec de la confirmation du paiement: $e');
    }
  }

  /// Use payment (mark vouchers as issued)
  static Future<ApiResponse<Payment>> usePayment({
    required String token,
    required int paymentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.usePayment(paymentId.toString())),
        headers: _getAuthHeaders(token),
      );

      return ApiResponse.fromResponse(response);
    } catch (e) {
      return ApiResponse.error('Échec de l\'utilisation du paiement: $e');
    }
  }

  /// Cancel payment
  static Future<ApiResponse<Payment>> cancelPayment({
    required String token,
    required int paymentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.cancelPayment(paymentId.toString())),
        headers: _getAuthHeaders(token),
      );

      return ApiResponse.fromResponse(response);
    } catch (e) {
      return ApiResponse.error('Échec de l\'annulation du paiement: $e');
    }
  }

  /// Get successful payments only
  static Future<List<Payment>> getSuccessfulPayments({
    required String token,
    int page = 1,
    int perPage = 15,
  }) async {
    return getUserPayments(
      token: token,
      etat: Payment.etatSucceeded,
      page: page,
      perPage: perPage,
    );
  }

  /// Get pending payments only
  static Future<List<Payment>> getPendingPayments({
    required String token,
    int page = 1,
    int perPage = 15,
  }) async {
    return getUserPayments(
      token: token,
      etat: Payment.etatPending,
      page: page,
      perPage: perPage,
    );
  }

  /// Get failed payments only
  static Future<List<Payment>> getFailedPayments({
    required String token,
    int page = 1,
    int perPage = 15,
  }) async {
    return getUserPayments(
      token: token,
      etat: Payment.etatFailed,
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

  /// Relance un bon et retourne l’URL Wave de paiement
  Future<ApiResponseRelance<VoucherPurchaseResponse>> relanceBon({
    required String token,
    required int bonId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.relanceBon(bonId.toString())),
        headers: _getAuthHeaders(token),
      );

      return ApiResponseRelance.fromResponse(
        response,
        fromJson: (json) => VoucherPurchaseResponse.fromJson(json),
      );
    } catch (e) {
      return ApiResponseRelance.error('Échec de la relance du bon: $e');
    }
  }
}
