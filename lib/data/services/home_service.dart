import 'package:ASSOU/data/services/user_service.dart';
import 'package:ASSOU/utils/logger.dart';

import '../../config/environment.dart';
import 'api_service.dart';
import '../../config/api_endpoints.dart';

/// HomeService handles dashboard and home page data
class HomeService {
  /// Get dashboard/home data from server
  static Future<Map<String, dynamic>> getAccueilData() async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.dashboardStats,
      );

      if (response.isSuccess && response.data != null) {
        return {
          'success': true,
          'data': response.data!['data'] ?? response.data,
        };
      } else {
        return {
          'success': false,
          'message': response.message,
        };
      }
    } catch (e) {
      if (Environment.debugMode) {
        print('HomeService.getAccueilData error: $e');
      }
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  /// Get boutiques with vouchers for home page
  static Future<Map<String, dynamic>> getBoutiquesWithVouchers() async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.boutiquesWithVouchers,
      );

      if (response.isSuccess && response.data != null) {
        return {
          'success': true,
          'data': response.data!['data'] ?? response.data,
        };
      } else {
        return {
          'success': false,
          'message': response.message,
        };
      }
    } catch (e) {
      if (Environment.debugMode) {
        print('HomeService.getBoutiquesWithVouchers error: $e');
      }
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  /// Get dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.dashboardStats,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        return {
          'success': true,
          'total_vouchers': data['total_vouchers'] ?? 0,
          'active_vouchers': data['active_vouchers'] ?? 0,
          'total_amount': data['total_amount'] ?? 0,
          'recent_transactions': data['recent_transactions'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': response.message,
        };
      }
    } catch (e) {
      if (Environment.debugMode) {
        print('HomeService.getDashboardStats error: $e');
      }
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  /// Get user's active vouchers
  static Future<Map<String, dynamic>> getUserBonsActifs() async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.myActiveVouchers,
      );

      if (response.isSuccess && response.data != null) {
        AppLogger.apiResponse(200, 'User Bons Actifs url',
            response: response.data);
        return {
          'success': true,
          'data': response.data!['data'] ?? response.data,
        };
      } else {
        return {
          'success': false,
          'message': response.message,
        };
      }
    } catch (e) {
      if (Environment.debugMode) {
        print('HomeService.getUserBonsActifs error: $e');
      }
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  /// Get vouchers that are expiring soon
  static Future<Map<String, dynamic>> getBonsExpires() async {
    AppLogger.info('Fetching expiring vouchers', 'HOME_SERVICE');
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.myExpiredVouchers,
      );

      if (response.isSuccess && response.data != null) {
        final allVouchers = response.data!['data'] ?? response.data;
        final List<dynamic> expiringVouchers = [];

        if (allVouchers is List) {
          for (var voucher in allVouchers) {
            if (voucher is Map<String, dynamic>) {
              final expirationDate = voucher['date_expiration'];
              if (expirationDate != null) {
                final expiration = DateTime.tryParse(expirationDate);
                if (expiration != null) {
                  final daysUntilExpiration =
                      expiration.difference(DateTime.now()).inDays;
                  if (daysUntilExpiration <= 30 && daysUntilExpiration >= 0) {
                    voucher['jours_avant_expiration'] = daysUntilExpiration;
                    expiringVouchers.add(voucher);
                  }
                }
              }
            }
          }
        }

        AppLogger.info(
            'Successfully loaded ${expiringVouchers.length} expiring vouchers',
            'HOME_SERVICE');
        AppLogger.debug(
            'Expiring vouchers: ${expiringVouchers.map((v) => v['id'] ?? '').join(', ')}',
            'HOME_SERVICE');

        return {
          'success': true,
          'data': expiringVouchers,
        };
      } else {
        AppLogger.error('Failed to load expiring vouchers: ${response.message}',
            'HOME_SERVICE');
        return {
          'success': false,
          'message': response.message,
        };
      }
    } catch (e) {
      AppLogger.error('Exception loading expiring vouchers', 'HOME_SERVICE', e);
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

// Methode pour envoyer des bons à un utilisateur

  /// Send a voucher to a user
  static Future<Map<String, dynamic>> envoyerBon(
      String contact, int idBonAchat, String message) async {
    try {
      final token = await UserService.getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Token d\'authentification manquant',
        };
      }

      final body = {
        'contact': contact,
        'id_bon_achat': idBonAchat,
        'message': message,
      };

      final response = await ApiService.post<Map<String, dynamic>>(
        ApiEndpoints.sendVoucher,
        body,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'] ?? response.data;
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': response.message ?? 'Erreur envoi bon',
        };
      }
    } catch (e) {
      if (Environment.debugMode) {
        print('HomeService.envoyerBon error: $e');
      }
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }
}
