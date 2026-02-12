import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../data/services/deep_link_payment_service.dart';
import '../../utils/logger.dart';
import '../mes-bons/mes_bons.dart';
import 'package:provider/provider.dart';
import '../../providers/reward_provider.dart';

/// Comprehensive payment screen with Wave integration and deep link handling
class PaymentScreen extends StatefulWidget {
  final String waveUrl;
  final String paymentReference;
  final Map<String, dynamic> paymentData;

  const PaymentScreen({
    super.key,
    required this.waveUrl,
    required this.paymentReference,
    required this.paymentData,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  bool _isWaitingForResult = false;
  late StreamSubscription<PaymentResult> _paymentSubscription;
  Timer? _timeoutTimer;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    AppLogger.info(
        'PaymentScreen initialized for reference: ${widget.paymentReference}',
        'PAYMENT_SCREEN');
    _initializePaymentListener();
  }

  void _initializePaymentListener() {
    AppLogger.debug('Initializing payment result listener', 'PAYMENT_SCREEN');
    // Listen for payment results from deep links
    _paymentSubscription = DeepLinkPaymentService().paymentResults.listen(
      (PaymentResult result) {
        AppLogger.debug(
            'Payment result received: ${result.toString()}', 'PAYMENT_SCREEN');
        if (result.reference == widget.paymentReference && mounted) {
          _cancelTimers();
          _handlePaymentResult(result);
        }
      },
      onError: (error) {
        AppLogger.error(
            'Payment result stream error: $error', 'PAYMENT_SCREEN');
        if (mounted) {
          _cancelTimers();
          _showError('Erreur lors du traitement du paiement: $error');
        }
      },
    );
  }

  void _launchWavePayment() async {
    setState(() {
      _isProcessing = true;
    });

    AppLogger.userAction('Wave payment launch initiated', data: {
      'reference': widget.paymentReference,
      'amount': widget.paymentData['montant_paiement'],
      'wave_url': widget.waveUrl,
    });

    try {
      final uri = Uri.parse(widget.waveUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        AppLogger.info('Wave app launched successfully', 'PAYMENT_SCREEN');
        setState(() {
          _isProcessing = false;
          _isWaitingForResult = true;
        });

        _showPaymentWaitingDialog();
        _startTimeoutTimer();
      } else {
        AppLogger.error('Cannot launch Wave app', 'PAYMENT_SCREEN');
        setState(() {
          _isProcessing = false;
        });
        _showError(
            'Impossible d\'ouvrir l\'application Wave. Vérifiez qu\'elle est installée.');
      }
    } catch (e) {
      AppLogger.error('Error launching Wave payment', 'PAYMENT_SCREEN', e);
      setState(() {
        _isProcessing = false;
      });
      _showError('Erreur lors du lancement du paiement: $e');
    }
  }

  void _startTimeoutTimer() {
    // Set a timeout for payment completion (5 minutes)
    _timeoutTimer = Timer(const Duration(minutes: 5), () {
      if (mounted && _isWaitingForResult) {
        AppLogger.warning(
            'Payment timeout reached for reference: ${widget.paymentReference}',
            'PAYMENT_SCREEN');
        _onPaymentTimeout();
      }
    });
  }

  void _startPollingTimer() {
    // Poll payment status every 15 seconds as backup
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (!_isWaitingForResult) {
        timer.cancel();
        return;
      }

      try {
        AppLogger.debug('Polling payment status', 'PAYMENT_SCREEN');
        final result = await DeepLinkPaymentService()
            .checkPaymentStatusManually(widget.paymentReference);
        if (result.success) {
          timer.cancel();
          if (mounted) {
            _handlePaymentResult(result);
          }
        }
      } catch (e) {
        AppLogger.error('Polling error', 'PAYMENT_SCREEN', e);
      }
    });
  }

  void _onPaymentTimeout() {
    Navigator.of(context, rootNavigator: true).pop(); // Close waiting dialog

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.access_time, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Temps dépassé'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Le délai d\'attente pour le paiement a été dépassé.'),
            SizedBox(height: 8),
            Text('Voulez-vous vérifier le statut manuellement ?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkStatusManually();
            },
            child: const Text('Vérifier'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _checkStatusManually() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Vérification en cours...'),
          ],
        ),
      ),
    );

    try {
      final result = await DeepLinkPaymentService()
          .checkPaymentStatusManually(widget.paymentReference);
      Navigator.pop(context); // Close loading dialog
      _handlePaymentResult(result);
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showError('Erreur lors de la vérification: $e');
    }
  }

  void _showPaymentWaitingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.payment, color: Colors.blue[700], size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Paiement en cours'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.blue[700]),
            const SizedBox(height: 16),
            const Text('Finalisez votre paiement dans l\'application Wave'),
            const SizedBox(height: 8),
            Text(
              'Vous serez redirigé automatiquement vers l\'application après le paiement',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Référence: ${widget.paymentReference}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500),
                  ),
                  if (widget.paymentData['montant_paiement'] != null)
                    Text(
                      'Montant: ${widget.paymentData['montant_paiement']} FCFA',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _cancelTimers();
              Navigator.pop(context);
              setState(() {
                _isWaitingForResult = false;
              });
            },
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: _checkStatusManually,
            child: const Text('Vérifier maintenant'),
          ),
        ],
      ),
    );

    // Start polling as backup
    _startPollingTimer();
  }

  void _handlePaymentResult(PaymentResult result) {
    if (!mounted) return;

    AppLogger.userAction('Payment result processed', data: {
      'success': result.success,
      'reference': result.reference,
      'message': result.message,
    });

    // Close waiting dialog if open
    Navigator.of(context, rootNavigator: true).pop();

    setState(() {
      _isWaitingForResult = false;
      _isProcessing = false;
    });

    if (result.success) {
      // Rafraîchir les récompenses suite à un achat réussi
      context.read<RewardProvider>().refreshAll();
      _showSuccessDialog(result);
    } else {
      _showErrorDialog(result);
    }
  }

  void _showSuccessDialog(PaymentResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.check_circle, color: Colors.green[600], size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text('Paiement réussi',
                    style: TextStyle(color: Colors.green[800]))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.message,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Text(
                    'Référence: ${result.payment?['reference'] ?? widget.paymentReference}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (result.payment != null &&
                      result.payment!['montant_paiement'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Montant: ${result.payment!['montant_paiement']} FCFA',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Vos bons d\'achat sont maintenant disponibles dans votre compte.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
              // Navigate to vouchers list
              _navigateToVouchers();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Voir mes bons'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(PaymentResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.error_outline, color: Colors.red[600], size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text('Problème de paiement',
                    style: TextStyle(color: Colors.red[800]))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.message, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  Text(
                    'Référence: ${widget.paymentReference}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Vous pouvez réessayer la vérification ou revenir plus tard.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkStatusManually();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _navigateToVouchers() {
    // Navigate to the vouchers page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MesBonsPage()),
    );
  }

  void _cancelTimers() {
    _timeoutTimer?.cancel();
    _pollingTimer?.cancel();
  }

  @override
  void dispose() {
    AppLogger.debug('PaymentScreen disposed', 'PAYMENT_SCREEN');
    _cancelTimers();
    _paymentSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Paiement Wave'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Payment icon with animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[400]!,
                      Colors.blue[600]!,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.payment,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Paiement sécurisé avec Wave',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Effectuez votre paiement en toute sécurité',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Payment details card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Référence:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            widget.paymentReference,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (widget.paymentData['montant_paiement'] != null) ...[
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey[200]),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Montant à payer:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${widget.paymentData['montant_paiement']} FCFA',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Payment button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isProcessing || _isWaitingForResult)
                      ? null
                      : _launchWavePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isProcessing
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Ouverture...',
                                style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : _isWaitingForResult
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('En attente...',
                                    style: TextStyle(fontSize: 16)),
                              ],
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.launch, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Payer avec Wave',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                ),
              ),

              const SizedBox(height: 24),

              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vous serez redirigé vers l\'application Wave pour finaliser votre paiement',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
