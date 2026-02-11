import 'dart:async';
import 'package:app_links/app_links.dart';
import '../../utils/logger.dart';
import 'payment_service.dart';
import 'user_service.dart';

class DeepLinkPaymentService {
  static final DeepLinkPaymentService _instance =
      DeepLinkPaymentService._internal();
  factory DeepLinkPaymentService() => _instance;
  DeepLinkPaymentService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Stream controller for payment results
  final StreamController<PaymentResult> _paymentController =
      StreamController<PaymentResult>.broadcast();

  Stream<PaymentResult> get paymentResults => _paymentController.stream;

  /// Initialize deep link listener for payment redirects
  void initializeDeepLinkListener() {
    _linkSubscription?.cancel(); // Cancel existing subscription

    AppLogger.info(
        'Initializing deep link listener with app_links', 'DEEP_LINK_PAYMENT');

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        AppLogger.info(
            'Deep link received: ${uri.toString()}', 'DEEP_LINK_PAYMENT');
        _handleDeepLink(uri.toString());
      },
      onError: (err) {
        AppLogger.error('Deep link error: $err', 'DEEP_LINK_PAYMENT');
        _paymentController.add(PaymentResult(
          success: false,
          message: 'Erreur de redirection: $err',
          reference: '',
        ));
      },
    );

    // Handle initial link if app was opened via deep link
    _handleInitialLink();
  }

  /// Handle initial deep link if app was opened via deep link
  void _handleInitialLink() async {
    try {
      final Uri? initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        AppLogger.info('Initial deep link: ${initialLink.toString()}',
            'DEEP_LINK_PAYMENT');
        _handleDeepLink(initialLink.toString());
      }
    } catch (e) {
      AppLogger.error('Error getting initial link', 'DEEP_LINK_PAYMENT', e);
    }
  }

  /// Handle incoming deep links
  void _handleDeepLink(String uri) async {
    try {
      final url = Uri.parse(uri);
      AppLogger.debug(
          'Parsing deep link: scheme=${url.scheme}, host=${url.host}, path=${url.path}',
          'DEEP_LINK_PAYMENT');

      // Check if it's a payment-related deep link
      if (url.scheme == 'assou' && url.host == 'payment') {
        // Log all query parameters for debugging
        AppLogger.debug(
            'Query parameters: ${url.queryParameters}', 'DEEP_LINK_PAYMENT');

        // Check both 'ref' and 'reference' parameters (backend may use either)
        final reference =
            url.queryParameters['ref'] ?? url.queryParameters['reference'];

        if (reference != null && reference.isNotEmpty) {
          // Determine if it's success or error based on path
          final isSuccessIntent = url.path.contains('/success');
          AppLogger.userAction('Payment deep link processed', data: {
            'reference': reference,
            'is_success_intent': isSuccessIntent,
            'path': url.path
          });

          await _checkPaymentStatus(reference,
              isSuccessIntent: isSuccessIntent);
        } else {
          AppLogger.error('Payment reference missing in deep link: $uri',
              'DEEP_LINK_PAYMENT');
          _paymentController.add(PaymentResult(
            success: false,
            message: 'Référence de paiement manquante',
            reference: '',
          ));
        }
      } else {
        AppLogger.debug(
            'Non-payment deep link ignored: $uri', 'DEEP_LINK_PAYMENT');
      }
    } catch (e) {
      AppLogger.error('Error handling deep link: $uri', 'DEEP_LINK_PAYMENT', e);
      _paymentController.add(PaymentResult(
        success: false,
        message: 'Erreur lors du traitement de la redirection',
        reference: '',
      ));
    }
  }

  /// Check payment status via API using existing payment service
  Future<void> _checkPaymentStatus(String reference,
      {bool isSuccessIntent = false}) async {
    try {
      AppLogger.info('Checking payment status for reference: $reference',
          'DEEP_LINK_PAYMENT');

      // Get auth token
      final token = await UserService.getAuthToken();
      if (token == null) {
        _paymentController.add(PaymentResult(
          success: false,
          message: 'Session expirée',
          reference: reference,
        ));
        return;
      }

      // Use existing PaymentService to check status
      final voucherPayment = await PaymentService.checkVoucherPaymentStatus(
        token: token,
        reference: reference,
      );

      if (voucherPayment != null) {
        AppLogger.info(
            'Payment status retrieved: ${voucherPayment.statusText}, isSucceeded: ${voucherPayment.isSucceeded}',
            'DEEP_LINK_PAYMENT');

        _paymentController.add(PaymentResult(
          success: voucherPayment.isSucceeded,
          message: voucherPayment.isSucceeded
              ? 'Paiement traité avec succès!'
              : (voucherPayment.etat == 2
                  ? 'Paiement reçu, préparation des bons...'
                  : 'Paiement ${voucherPayment.statusText.toLowerCase()}'),
          reference: reference,
          status: voucherPayment.statusText,
          isSuccessIntent: isSuccessIntent,
        ));
      } else {
        _paymentController.add(PaymentResult(
          success: false,
          message: 'Impossible de vérifier le statut du paiement',
          reference: reference,
          isSuccessIntent: isSuccessIntent,
        ));
      }
    } catch (e) {
      AppLogger.error('Error checking payment status for reference: $reference',
          'DEEP_LINK_PAYMENT', e);
      _paymentController.add(PaymentResult(
        success: false,
        message: 'Erreur lors de la vérification: $e',
        reference: reference,
      ));
    }
  }

  /// Manual payment status check (for polling or retry)
  Future<PaymentResult> checkPaymentStatusManually(String reference) async {
    try {
      AppLogger.info(
          'Manual payment status check for: $reference', 'DEEP_LINK_PAYMENT');

      // Get auth token
      final token = await UserService.getAuthToken();
      if (token == null) {
        return PaymentResult(
          success: false,
          message: 'Session expirée',
          reference: reference,
        );
      }

      // Use existing PaymentService to check status
      final voucherPayment = await PaymentService.checkVoucherPaymentStatus(
        token: token,
        reference: reference,
      );

      if (voucherPayment != null) {
        AppLogger.info(
            'Manual check result: ${voucherPayment.statusText}, isSucceeded: ${voucherPayment.isSucceeded}',
            'DEEP_LINK_PAYMENT');

        return PaymentResult(
          success: voucherPayment.isSucceeded,
          message: voucherPayment.isSucceeded
              ? 'Paiement traité avec succès!'
              : (voucherPayment.etat == 2
                  ? 'Paiement reçu, préparation des bons...'
                  : 'Paiement ${voucherPayment.statusText.toLowerCase()}'),
          reference: reference,
          status: voucherPayment.statusText,
        );
      } else {
        return PaymentResult(
          success: false,
          message: 'Impossible de vérifier le statut du paiement',
          reference: reference,
        );
      }
    } catch (e) {
      AppLogger.error(
          'Manual payment status check failed', 'DEEP_LINK_PAYMENT', e);
      return PaymentResult(
        success: false,
        message: 'Erreur lors de la vérification: $e',
        reference: reference,
      );
    }
  }

  /// Dispose resources
  void dispose() {
    AppLogger.info('Disposing deep link payment service', 'DEEP_LINK_PAYMENT');
    _linkSubscription?.cancel();
    if (!_paymentController.isClosed) {
      _paymentController.close();
    }
  }
}

/// Payment result data class for deep link responses
class PaymentResult {
  final bool success;
  final Map<String, dynamic>? payment;
  final String message;
  final String reference;
  final String? status;
  final bool isSuccessIntent;

  PaymentResult({
    required this.success,
    this.payment,
    required this.message,
    required this.reference,
    this.status,
    this.isSuccessIntent = false,
  });

  @override
  String toString() {
    return 'PaymentResult(success: $success, message: $message, reference: $reference, status: $status, isSuccessIntent: $isSuccessIntent)';
  }
}
