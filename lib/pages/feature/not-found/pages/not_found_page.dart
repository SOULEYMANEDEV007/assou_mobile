import 'dart:async';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NoInternetPage extends StatefulWidget {
  final VoidCallback? onRetry;

  const NoInternetPage({super.key, this.onRetry});

  @override
  State<NoInternetPage> createState() => _NoInternetPageState();
}

class _NoInternetPageState extends State<NoInternetPage>
    with TickerProviderStateMixin {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;



  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  final bool _isChecking = false;

  @override
  void initState() {
    super.initState();

    initConnectivity();

    // Écoute en temps réel
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);


    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _slideController.forward();
  }


  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      developer.log('Erreur lors de la vérification de la connexion', error: e);
      return;
    }

    if (!mounted) return;
    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });

    // Exemple de traitement selon la connexion
    if (_connectionStatus == ConnectivityResult.mobile || _connectionStatus == ConnectivityResult.wifi) {
      _showSnackBar("Connexion internet retablie");
      Navigator.pop(context);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.green, content: Text(message), duration: const Duration(seconds: 2)),
    );
  }


  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 93, 143, 235),
              Color.fromARGB(255, 93, 143, 235),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône Wi-Fi animée
                  _buildWifiIcon(),

                  const SizedBox(height: 32),

                  // Titre principal
                  const Text(
                    'Pas de connexion',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Message d'explication
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Oups ! Il semblerait que vous ne soyez pas connecté à internet.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF546e7a),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Suggestions
                        _buildSuggestions(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Texte d'information
                  const Text(
                    'Vérification automatique en cours...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWifiIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.red.shade300,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Barres Wi-Fi
          SizedBox(
            width: 60,
            height: 40,
            child: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 6,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 12,
                  child: Container(
                    width: 6,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 24,
                  child: Container(
                    width: 6,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 36,
                  child: Container(
                    width: 6,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Croix rouge
          const Icon(
            Icons.close,
            color: Colors.red,
            size: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggestions pour résoudre le problème :',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2c3e50),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _buildSuggestionItem('Vérifiez que le Wi-Fi est activé'),
          _buildSuggestionItem('Vérifiez les données mobiles'),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFF667eea),
            size: 12,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF546e7a),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
