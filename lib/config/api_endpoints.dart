import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'environment.dart';

class ApiEndpoints {
  // Base URLs
  static String get baseUrl => Environment.apiBaseUrl;
  static String get waveBaseUrl => Environment.waveBaseUrl;

  // =========================================================================
  // AUTHENTICATION ENDPOINTS (PUBLIC)
  // =========================================================================
  static String get login => _getEndpoint('AUTH_LOGIN_ENDPOINT', '/login');
  static String get register =>
      _getEndpoint('AUTH_REGISTER_ENDPOINT', '/register');
  static String get logout => _getEndpoint('AUTH_LOGOUT_ENDPOINT', '/logout');
  static String get forgotPassword => Environment.getApiUrl('/forgot-password');
  static String get resetPassword => Environment.getApiUrl('/reset-password');
  static String get changePassword => Environment.getApiUrl('/change-password');

  // =========================================================================
  // USER ENDPOINTS (AUTHENTICATED)
  // =========================================================================
  static String get userProfile =>
      Environment.getApiUrl('/me'); // Real endpoint from backend
  static String get updateProfile =>
      _getEndpoint('USER_UPDATE_ENDPOINT', '/update-profil');

  // User-specific endpoints
  static String getUserPayments(String userId) =>
      Environment.getApiUrl('/users/$userId/paiements');
  static String getUserNotifications(String userId) =>
      Environment.getApiUrl('/users/$userId/notifications');

  // User roles management
  static String getUserRoles(String userId) =>
      Environment.getApiUrl('/users/$userId/roles');
  static String assignUserRole(String userId) =>
      Environment.getApiUrl('/users/$userId/roles/assign');
  static String removeUserRole(String userId) =>
      Environment.getApiUrl('/users/$userId/roles/remove');

  // =========================================================================
  // DASHBOARD / ACCUEIL ENDPOINTS
  // =========================================================================
  static String get dashboardStats => Environment.getApiUrl('/accueil');
  static String get boutiquesWithVouchers =>
      Environment.getApiUrl('/accueil/boutiques-avec-bons');

  // =========================================================================
  // BOUTIQUES ENDPOINTS
  // =========================================================================
  static String get boutiquesList => Environment.getApiUrl('/boutiques');
  static String get createBoutique => Environment.getApiUrl('/boutiques');
  static String getBoutiqueDetails(String boutiqueId) =>
      Environment.getApiUrl('/boutiques/$boutiqueId');
  static String updateBoutique(String boutiqueId) =>
      Environment.getApiUrl('/boutiques/$boutiqueId');
  static String deleteBoutique(String boutiqueId) =>
      Environment.getApiUrl('/boutiques/$boutiqueId');
  static String getBoutiquePayments(String boutiqueId) =>
      Environment.getApiUrl('/boutiques/$boutiqueId/paiements');

  // Boutique Types
  static String get boutiqueTypes => Environment.getApiUrl('/boutique-types');
  static String getBoutiquesByType(String typeId) =>
      Environment.getApiUrl('/boutique-types/$typeId/boutiques');

  // =========================================================================
  // VOUCHERS / BONS D'ACHAT ENDPOINTS
  // =========================================================================
  static String get vouchersList => Environment.getApiUrl('/bons-achat');
  static String get createVoucher => Environment.getApiUrl('/bons-achat');
  static String getVoucherDetails(String voucherId) =>
      Environment.getApiUrl('/bons-achat/$voucherId');
  static String updateVoucher(String voucherId) =>
      Environment.getApiUrl('/bons-achat/$voucherId');
  static String deleteVoucher(String voucherId) =>
      Environment.getApiUrl('/bons-achat/$voucherId');

  // Voucher actions
  static String activateVoucher(String voucherId) =>
      Environment.getApiUrl('/bons-achat/$voucherId/activate');
  static String deactivateVoucher(String voucherId) =>
      Environment.getApiUrl('/bons-achat/$voucherId/deactivate');
  static String getVoucherPayments(String voucherId) =>
      Environment.getApiUrl('/bons-achat/$voucherId/paiements');

  // Voucher filtering
  static String getVouchersByBoutique(String boutiqueId) =>
      Environment.getApiUrl('/bons-achat/boutique/$boutiqueId');
  static String get availableVouchers =>
      Environment.getApiUrl('/bons-achat/disponibles');

  // =========================================================================
  // PAYMENTS ENDPOINTS (REAL BACKEND ROUTES)
  // =========================================================================
  static String relanceBon(String bonId) =>
      "$baseUrl/bons/relance-un-bon?bon_id=$bonId";
  static String get paymentsList => Environment.getApiUrl('/paiements');
  static String get createPayment => Environment.getApiUrl('/paiements');
  static String getPaymentDetails(String paymentId) =>
      Environment.getApiUrl('/paiements/$paymentId');
  static String validatePayment(String paymentId) =>
      Environment.getApiUrl('/paiements/$paymentId/validate');
  static String confirmPayment(String paymentId) =>
      Environment.getApiUrl('/paiements/$paymentId/confirm');
  static String usePayment(String paymentId) =>
      Environment.getApiUrl('/paiements/$paymentId/use');
  static String cancelPayment(String paymentId) =>
      Environment.getApiUrl('/paiements/$paymentId/cancel');

  // My vouchers endpoints (real backend)
  static String get myPurchasedVouchers => Environment.getApiUrl('/mes-bon');
  static String get myReceivedVouchers =>
      Environment.getApiUrl('/mes-bon-recu');
  static String get myActiveVouchers => Environment.getApiUrl('/bon-actifs');
  static String get myExpiringSoonVouchers =>
      Environment.getApiUrl('/my-expiring-soon-vouchers');
  static String get myExpiredVouchers =>
      Environment.getApiUrl('/my-expired-vouchers');

  static String get mySentVouchers => Environment.getApiUrl('/bon-envoyer');

  // Voucher actions (real backend)
  static String get redeemVoucher => Environment.getApiUrl('/ancaisser-un-bon');
  static String get sendVoucher => Environment.getApiUrl('/envoyer-un-bon');
  static String get useVoucher =>
      Environment.getApiUrl('/bons/utiliser-un-bon');

  // =========================================================================
  // EVENT TYPES ENDPOINTS
  // =========================================================================
  static String get activeEventTypes =>
      Environment.getApiUrl('/event-types/active/list');
  static String get eventTypesList => Environment.getApiUrl('/event-types');
  static String getEventTypeDetails(String eventTypeId) =>
      Environment.getApiUrl('/event-types/$eventTypeId');

  // =========================================================================
  // NOTIFICATIONS ENDPOINTS
  // =========================================================================
  static String get notifications => Environment.getApiUrl('/notifications');
  static String get createNotification =>
      Environment.getApiUrl('/notifications');
  static String getNotificationDetails(String notificationId) =>
      Environment.getApiUrl('/notifications/$notificationId');
  static String markNotificationRead(String notificationId) =>
      Environment.getApiUrl('/notifications/$notificationId/mark-read');
  static String get markAllNotificationsRead =>
      Environment.getApiUrl('/notifications/mark-all-read');

  // =========================================================================
  // REWARDS / RÉCOMPENSES ENDPOINTS
  // =========================================================================
  static String get userRewards => Environment.getApiUrl('/rewards');
  static String get pointTransactions =>
      Environment.getApiUrl('/rewards/transactions');
  static String get recordGiftPoints =>
      Environment.getApiUrl('/rewards/record-gift');
  static String get checkAchievements =>
      Environment.getApiUrl('/rewards/achievements');

  // =========================================================================
  // GIFT CHALLENGE V2 ENDPOINTS
  // =========================================================================
  static String get giftChallengeStats =>
      Environment.getApiUrl('/v2/gift-challenge/stats');
  static String get giftChallengeLeaderboard =>
      Environment.getApiUrl('/v2/gift-challenge/leaderboard');
  static String get giftChallengeHistory =>
      Environment.getApiUrl('/v2/gift-challenge/history');
  static String get giftChallengeBadges =>
      Environment.getApiUrl('/v2/gift-challenge/badges');

  // =========================================================================
  // BANNER ADS V2 ENDPOINTS
  // =========================================================================
  static String get bannerAdsActive =>
      Environment.getApiUrl('/v2/banner-ads/active');

  // =========================================================================
  // LEGACY/COMPATIBILITY ENDPOINTS
  // =========================================================================

  // Old naming for backward compatibility
  static String get refreshToken => Environment.getApiUrl('/refresh');
  static String get initiatePayment => createPayment;
  static String get paymentStatus => Environment.getApiUrl('/paiements/status');

  // Upload endpoints (if needed)
  static String get uploadImage => Environment.getApiUrl('/upload/image');
  static String get uploadDocument => Environment.getApiUrl('/upload/document');

  // Account management
  static String get deleteAccount => Environment.getApiUrl('/user/account');
  static String get updateUserSettings =>
      Environment.getApiUrl('/user/settings');

  // =========================================================================
  // HELPER METHODS
  // =========================================================================

  // Helper method to get endpoint from environment or fallback
  static String _getEndpoint(String envKey, String fallback) {
    final endpoint = dotenv.env[envKey] ?? fallback;
    return Environment.getApiUrl(endpoint);
  }

  // Get full URL with base
  static String getFullUrl(String endpoint) {
    return Environment.getApiUrl(endpoint);
  }

  // Dynamic endpoints for REST operations
  static String getResourceEndpoint(String resource, [String? id]) {
    if (id != null) {
      return Environment.getApiUrl('/$resource/$id');
    }
    return Environment.getApiUrl('/$resource');
  }
}

// HTTP Methods enum for consistency
enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete,
}

// Common HTTP status codes
class HttpStatus {
  static const int ok = 200;
  static const int created = 201;
  static const int noContent = 204;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int methodNotAllowed = 405;
  static const int conflict = 409;
  static const int unprocessableEntity = 422;
  static const int internalServerError = 500;
  static const int badGateway = 502;
  static const int serviceUnavailable = 503;
}
