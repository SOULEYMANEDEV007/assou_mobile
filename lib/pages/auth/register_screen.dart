import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

// Importez vos services
import '../../services/otp_service.dart';
import '../../services/settings_service.dart';
import '../../utils/logger.dart';
import '../../pages/feature/not-found/pages/not_found_page.dart';
import '../../widgets/toast_helper.dart';
import 'otp_verification_screen.dart';
import 'login_screen.dart';
import '../../widgets/app_input.dart';
import '../../widgets/wave_clipper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _acceptTerms = false;

  final String _countryCode = '+225';
  final String _countryName = 'Côte d\'Ivoire';
  String _cguLink = 'https://assou.app/cgu';

  // Gestion de la connectivité
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    AppLogger.info('Register screen initialized', 'REGISTER_UI');
    initConnectivity();
    _loadSettings();

    // Écoute en temps réel
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      AppLogger.error(
          'Erreur lors de la vérification de la connexion', 'REGISTER_UI', e);
      return;
    }

    if (!mounted) return;
    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });

    if (_connectionStatus == ConnectivityResult.none) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const NoInternetPage()));
    }
  }

  Future<void> _loadSettings() async {
    try {
      final cguLink = await SettingsService.getString('cgu_link',
          defaultValue: 'https://assou.app/cgu');
      setState(() {
        _cguLink = cguLink;
      });
      AppLogger.info('Settings loaded successfully', 'REGISTER_UI');
    } catch (e) {
      AppLogger.error('Failed to load settings', 'REGISTER_UI', e);
    }
  }

  // MÉTHODE D'INSCRIPTION PRINCIPALE
  Future<void> _inscription() async {
    if (_isLoading) return;

    if (!mounted) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final phoneNumber = _phoneController.text.trim();

    // Validation du numéro de téléphone
    if (phoneNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez saisir votre numéro de téléphone';
        _isLoading = false;
      });
      return;
    }

    // Validation du format du numéro (10 chiffres commençant par 0)
    if (!RegExp(r'^0[0-9]{9}$').hasMatch(phoneNumber)) {
      setState(() {
        _errorMessage = 'Format de numéro invalide (ex: 0707999888)';
        _isLoading = false;
      });
      return;
    }

    // Vérification des conditions d'utilisation
    if (!_acceptTerms) {
      setState(() {
        _errorMessage =
            'Vous devez accepter les Conditions Générales d\'Utilisation';
        _isLoading = false;
      });
      return;
    }

    AppLogger.info(
        'Starting OTP registration flow for $phoneNumber', 'REGISTRATION');

    try {
      // Envoyer l'OTP pour l'inscription
      final response = await OtpService.sendOtp(
        phoneNumber,
        action: 'registration',
      );

      if (response.success) {
        AppLogger.info(
            'OTP sent successfully for registration', 'REGISTRATION');

        // Afficher un toast de succès
        ToastHelper.showToast(
          context,
          title: "Code de vérification",
          message:
              "Un code vous sera envoyé par SMS. Merci de vérifier votre téléphone.",
          type: ToastType.success,
        );

        // Naviguer vers l'écran de vérification OTP après un court délai
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                phoneNumber: phoneNumber,
                action: 'registration',
              ),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage =
              "Une erreur est survenue (veuillez réessayer plus tard)";
          _isLoading = false;
        });

        ToastHelper.showToast(
          context,
          title: "Erreur",
          message: "Échec de l'envoi du code OTP. Veuillez réessayer.",
          type: ToastType.error,
        );

        AppLogger.error(
            'Failed to send OTP: ${response.message}', 'REGISTRATION');
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur de connexion: $e";
        _isLoading = false;
      });

      ToastHelper.showToast(
        context,
        title: "Erreur",
        message: "Erreur de connexion: ${e.toString()}",
        type: ToastType.error,
      );

      AppLogger.error('Exception during OTP send', 'REGISTRATION', e);
    }
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro de téléphone est obligatoire';
    }

    final cleanValue = value.trim();

    // Validation pour le format ivoirien
    if (!RegExp(r'^0[0-9]{9}$').hasMatch(cleanValue)) {
      return 'Format invalide. Exemple: 0701234567';
    }

    return null;
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conditions Générales d\'Utilisation'),
        content: const Text(
            'Les Conditions Générales d\'Utilisation s\'ouvriront dans votre navigateur.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final Uri uri = Uri.parse(_cguLink);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  throw 'Impossible d\'ouvrir le lien';
                }
              } catch (e) {
                ToastHelper.showToast(
                  context,
                  title: "Erreur",
                  message: "Impossible d'ouvrir les CGU",
                  type: ToastType.error,
                );
              }
            },
            child: const Text('Ouvrir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeeedf3),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              children: [
                // Section bleue en haut - FIXE
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height * 0.48,
                  child: ClipPath(
                    clipper: WaveClipper(),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF3380fe),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(height: 30),
                            Image.asset(
                              "assets/images/assouLogo.png",
                              height: 150,
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "Créer son compte",
                              style: TextStyle(
                                fontSize: 26,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Carte blanche avec formulaire - SCROLLABLE
                Positioned.fill(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.30),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Message avec lien connexion
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF64748B),
                                      fontFamily: 'Nunito',
                                    ),
                                    children: [
                                      const TextSpan(
                                        text:
                                            'Si vous avez déjà créé votre compte, alors ',
                                      ),
                                      TextSpan(
                                        text: 'Connectez-vous',
                                        style: const TextStyle(
                                          color: Color(0xFF3380fe),
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Nunito',
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const LoginScreen(),
                                              ),
                                            );
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Message d'erreur
                              if (_errorMessage != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.red.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error,
                                          color: Colors.red, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Pays (visuel uniquement selon maquette)
                              AppInput(
                                readOnly: true,
                                controller:
                                    TextEditingController(text: _countryName),
                                prefixWidget: const Text('🇨🇮',
                                    style: TextStyle(fontSize: 20)),
                                showDivider: true,
                              ),

                              const SizedBox(height: 16),

                              // Numéro de téléphone
                              AppInput(
                                controller: _phoneController,
                                hint: '07 XX XX XX XX',
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                prefixWidget: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _countryCode,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF3380fe),
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                  ],
                                ),
                                showDivider: true,
                                validator: _validatePhoneNumber,
                                onChanged: (value) {
                                  if (_errorMessage != null &&
                                      value.isNotEmpty) {
                                    setState(() {
                                      _errorMessage = null;
                                    });
                                  }
                                },
                              ),

                              const SizedBox(height: 12),

                              // Checkbox pour accepter les CGU
                              Row(
                                children: [
                                  Checkbox(
                                    value: _acceptTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        _acceptTerms = value ?? false;
                                      });
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _showTermsDialog,
                                      child: RichText(
                                        text: const TextSpan(
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                            fontFamily: 'Nunito',
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'J\'accepte les ',
                                            ),
                                            TextSpan(
                                              text:
                                                  'Conditions Générales d\'Utilis.',
                                              style: TextStyle(
                                                color: Color(0xFF3380fe),
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'Nunito',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Bouton Continuer
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _inscription,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3380fe),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Text('Continuer'),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Message SMS
                              Text(
                                'Nous enverrons un code de vérification via SMS à ce numéro.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomSheet: Container(
        width: double.infinity,
        color: const Color(0xFFeeedf3),
        padding: const EdgeInsets.only(bottom: 20, top: 10),
        child: const Text(
          'Un produit KOSEH GROUP',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
