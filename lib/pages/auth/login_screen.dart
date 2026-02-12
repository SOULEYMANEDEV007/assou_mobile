import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/gestures.dart';

// Importez vos services et pages ici
import '../../data/services/auth_service.dart';
import '../../data/services/user_service.dart';
import '../../data/models/user_model.dart';
import '../../pages/home/home.dart';
import '../../widgets/toast_helper.dart';
import '../feature/not-found/pages/not_found_page.dart';
import 'register_screen.dart';
import '../../widgets/app_input.dart';
import '../../widgets/wave_clipper.dart';

class LoginScreen extends StatefulWidget {
  final bool showDialogPasswordForget;
  const LoginScreen({super.key, this.showDialogPasswordForget = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginPhoneController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    initConnectivity();
    getPhoneNumber();

    // Écoute en temps réel
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _loginPhoneController.dispose();
    _loginPasswordController.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    var phoneNumber = prefs.getString("phone_number");
    if (phoneNumber != null) {
      _loginPhoneController.text = phoneNumber;
    }
  }

  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print('Erreur lors de la vérification de la connexion: $e');
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

  Future<String> getToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    return token ?? '';
  }

  Future<void> _connexion() async {
    if (_isLoading) return;

    if (!mounted) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final phoneNumber = _loginPhoneController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (phoneNumber.isEmpty || password.isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Veuillez remplir tous les champs';
        _isLoading = false;
      });

      ToastHelper.showToast(
        context,
        title: "Validation des champs",
        message: "Veuillez remplir tous les champs",
        type: ToastType.warning,
      );
      return;
    }

    try {
      final String token = await getToken();

      final response = await AuthService.login(
        login: phoneNumber,
        password: password,
        token: token,
      );

      if (response.success &&
          response.data != null &&
          response.data['token'] != null &&
          response.data['user'] != null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = null;
          _isLoading = false;
        });

        // SAVE USER DATA CORRECTLY
        final userData = User.fromJson(response.data['user']);
        await UserService.saveUser(userData, response.data['token']);

        if (!mounted) return;
        ToastHelper.showToast(
          context,
          title: "Connexion réussie !",
          message: "Bienvenue ${userData.firstName} !",
          type: ToastType.success,
        );

        await Future.delayed(const Duration(milliseconds: 1000));
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = response.message ?? 'Erreur de connexion';
          _isLoading = false;
        });

        ToastHelper.showToast(
          context,
          title: "Connexion échouée !",
          message: "Identifiants invalides.",
          type: ToastType.error,
        );
      }
    } catch (e) {
      print('Login exception: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = "Erreur de connexion: ${e.toString()}";
        _isLoading = false;
      });

      if (mounted) {
        ToastHelper.showToast(
          context,
          title: "Erreur",
          message: "Erreur de connexion: ${e.toString()}",
          type: ToastType.error,
        );
      }
    }
  }

  void _showForgotPasswordDialog() {
    String numero = "";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Mot de passe oublié",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF3380fe),
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width *
                    0.7, // ✅ Limiter la largeur
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppInput(
                      hint: "07 XX XX XX XX",
                      keyboardType: TextInputType.phone,
                      onChanged: (value) => numero = value,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "Annuler",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (numero.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("Veuillez entrer un numéro valide"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() => isLoading = true);

                          final response = await AuthService.forgotPassword(
                            phone_number: numero,
                          );

                          setState(() => isLoading = false);

                          if (response.success) {
                            ToastHelper.showToast(
                              context,
                              title: "Code de vérification",
                              message:
                                  "Un code vous sera envoyé par SMS. Merci de vérifier votre téléphone.",
                              type: ToastType.success,
                            );

                            await Future.delayed(
                                const Duration(milliseconds: 1000));
                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                            _showPasswordResetDialog(numero);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(response.message ??
                                    "Erreur lors de l'envoi du code"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3380fe),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Envoyer le code",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPasswordResetDialog(String numero) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String code = "";
        String password = "";
        String confirmPassword = "";
        bool isLoading2 = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Réinitialiser mot de passe",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF3380fe),
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogInput(
                      hintText: "Code reçu par SMS",
                      onChanged: (v) => code = v,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    _buildDialogInput(
                      hintText: "Nouveau mot de passe",
                      onChanged: (v) => password = v,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    _buildDialogInput(
                      hintText: "Confirmer mot de passe",
                      onChanged: (v) => confirmPassword = v,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "Annuler",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading2
                      ? null
                      : () async {
                          if (code.isEmpty ||
                              password.isEmpty ||
                              confirmPassword.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Tous les champs sont requis"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (password != confirmPassword) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Les mots de passe ne correspondent pas"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() => isLoading2 = true);

                          final resetResponse = await AuthService.resetPassword(
                            phoneNumber: numero,
                            newPassword: password,
                            confirmPassword: confirmPassword,
                            resetCode: code,
                          );

                          setState(() => isLoading2 = false);

                          if (resetResponse.success) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(resetResponse.message ??
                                    "Mot de passe réinitialisé avec succès"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(resetResponse.message ??
                                    "Échec de la réinitialisation"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3380fe),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: isLoading2
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Réinitialiser",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogInput({
    required String hintText,
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return AppInput(
      hint: hintText,
      onChanged: onChanged,
      keyboardType: keyboardType,
      obscureText: obscureText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeeedf3),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Section bleue en haut avec courbe profonde
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
                        const SizedBox(height: 20),
                        const Text(
                          "Se connecter",
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

            // Contenu principal (Carte + Footer)
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.32),

                    // Carte blanche
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Lien vers inscription
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
                                          'Si c\'est votre première fois, alors '),
                                  TextSpan(
                                    text: 'Créez votre compte',
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
                                                  const RegisterScreen()),
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Champ téléphone avec drapeau
                          AppInput(
                            controller: _loginPhoneController,
                            hint: '07 XX XX XX XX',
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            prefixWidget: const Text(
                              '+225',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3380fe),
                                fontFamily: 'Nunito',
                              ),
                            ),
                            showDivider: true,
                          ),

                          const SizedBox(height: 16),

                          // Champ mot de passe
                          AppInput(
                            controller: _loginPasswordController,
                            hint: 'Mot de passe',
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Bouton
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _connexion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3380fe),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5))
                                  : const Text("Se connecter"),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Mot de passe oublié
                          Center(
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: const Text(
                                "Mot de passe oublié",
                                style: TextStyle(
                                  color: Color(0xFF3380fe),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Footer
                    const Text(
                      "Un produit KOSEH GROUP",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
