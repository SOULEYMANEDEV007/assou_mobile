import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/logger.dart';

class PaymentWaitingScreen extends StatefulWidget {
  final String paymentReference;
  final double totalAmount;
  final VoidCallback onPaymentSuccess;
  final VoidCallback onPaymentFailed;
  final VoidCallback onManualRefresh;
  
  const PaymentWaitingScreen({
    super.key,
    required this.paymentReference,
    required this.totalAmount,
    required this.onPaymentSuccess,
    required this.onPaymentFailed,
    required this.onManualRefresh,
  });

  @override
  State<PaymentWaitingScreen> createState() => _PaymentWaitingScreenState();
}

class _PaymentWaitingScreenState extends State<PaymentWaitingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  Timer? _pollingTimer;
  Timer? _timeoutTimer;
  
  int _secondsElapsed = 0;
  bool _isPolling = true;
  bool _isTimedOut = false;
  String _status = 'En attente de paiement...';

  @override
  void initState() {
    super.initState();
    AppLogger.info('PaymentWaitingScreen initialized', 'PAYMENT_WAITING');
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.repeat(reverse: true);
    
    _startPolling();
    _startTimeout();
  }

  void _startPolling() {
    AppLogger.info('Starting payment status polling', 'PAYMENT_WAITING');
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      
      setState(() {
        _secondsElapsed += 3;
      });
      
      AppLogger.debug('Polling payment status - ${_secondsElapsed}s elapsed', 'PAYMENT_WAITING');
      
      // Simulate payment status checking
      // In real implementation, call your payment status API here
      _checkPaymentStatus();
    });
  }

  void _startTimeout() {
    // 5 minute timeout
    _timeoutTimer = Timer(const Duration(minutes: 5), () {
      if (!mounted) return;
      
      AppLogger.warning('Payment waiting timeout reached', 'PAYMENT_WAITING');
      
      setState(() {
        _isTimedOut = true;
        _isPolling = false;
        _status = 'Délai d\'attente dépassé';
      });
      
      _stopPolling();
    });
  }

  Future<void> _checkPaymentStatus() async {
    // In real implementation, this would call your payment status API
    // For now, we simulate different states
    try {
      AppLogger.debug('Checking payment status for reference: ${widget.paymentReference}', 'PAYMENT_WAITING');
      
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // For demonstration, simulate success after 30 seconds
      if (_secondsElapsed >= 30) {
        _handlePaymentSuccess();
      } else if (_secondsElapsed >= 90) {
        _handlePaymentFailed();
      } else {
        setState(() {
          _status = 'Vérification en cours... (${_secondsElapsed}s)';
        });
      }
    } catch (e) {
      AppLogger.error('Error checking payment status', 'PAYMENT_WAITING', e);
      setState(() {
        _status = 'Erreur lors de la vérification';
      });
    }
  }

  void _handlePaymentSuccess() {
    AppLogger.info('Payment confirmed as successful', 'PAYMENT_WAITING');
    
    setState(() {
      _isPolling = false;
      _status = 'Paiement confirmé!';
    });
    
    _stopPolling();
    
    // Show success animation briefly before calling callback
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onPaymentSuccess();
      }
    });
  }

  void _handlePaymentFailed() {
    AppLogger.warning('Payment failed or cancelled', 'PAYMENT_WAITING');
    
    setState(() {
      _isPolling = false;
      _status = 'Paiement échoué ou annulé';
    });
    
    _stopPolling();
    widget.onPaymentFailed();
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _timeoutTimer?.cancel();
    _animationController.stop();
  }

  void _manualRefresh() {
    AppLogger.info('Manual refresh triggered', 'PAYMENT_WAITING');
    
    if (!_isPolling && !_isTimedOut) {
      setState(() {
        _isPolling = true;
        _secondsElapsed = 0;
        _status = 'Vérification en cours...';
      });
      
      _animationController.repeat(reverse: true);
      _startPolling();
      _startTimeout();
    }
    
    widget.onManualRefresh();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    AppLogger.debug('Disposing PaymentWaitingScreen', 'PAYMENT_WAITING');
    _stopPolling();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2F55E0);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Attente de paiement'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            AppLogger.info('Payment waiting cancelled by user', 'PAYMENT_WAITING');
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Status Animation
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Payment Icon
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isPolling ? _pulseAnimation.value : 1.0,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getStatusColor(),
                                width: 3,
                              ),
                            ),
                            child: Icon(
                              _getStatusIcon(),
                              size: 60,
                              color: _getStatusColor(),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Status Text
                    Text(
                      _status,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Timer
                    if (_isPolling || _isTimedOut)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Temps écoulé: ${_formatTime(_secondsElapsed)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Payment Details
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Référence:',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          widget.paymentReference,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Montant:',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${(widget.totalAmount / 1000).toStringAsFixed(1)}k FCFA',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Column(
                children: [
                  // Refresh Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _manualRefresh,
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text(
                        'Actualiser le statut',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryBlue,
                        side: const BorderSide(color: primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: TextButton(
                      onPressed: () {
                        AppLogger.info('Payment cancelled by user', 'PAYMENT_WAITING');
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Annuler et retourner',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Help Text
              const SizedBox(height: 16),
              Text(
                'Le statut sera automatiquement mis à jour.\nSi le paiement ne se confirme pas, utilisez le bouton "Actualiser".',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (_status.contains('confirmé') || _status.contains('succès')) {
      return Colors.green;
    } else if (_status.contains('échoué') || _status.contains('annulé') || _isTimedOut) {
      return Colors.red;
    } else {
      return const Color(0xFF2F55E0);
    }
  }

  IconData _getStatusIcon() {
    if (_status.contains('confirmé') || _status.contains('succès')) {
      return Icons.check_circle;
    } else if (_status.contains('échoué') || _status.contains('annulé') || _isTimedOut) {
      return Icons.error;
    } else {
      return Icons.payment;
    }
  }
}
