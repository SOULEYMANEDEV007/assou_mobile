import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/user_service.dart';
import '../../widgets/toast_helper.dart';
import '../auth/login_screen.dart';
import '../home/home.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  String _pin = '';
  bool _isError = false;

  void _onNumberPressed(String number) {
    if (_pin.length < 4) {
      setState(() {
        _pin += number;
        _isError = false;
      });

      // Vérifier automatiquement quand on a 4 chiffres
      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _isError = false;
      });
    }
  }

  Future<String> getToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();

    return token!;
  }

  Future<void> _verifyPin() async {
    final prefs = await SharedPreferences.getInstance();

    var phoneNumber = prefs.getString("phone_number");
    String token = await getToken();

    // Exemple: vérifier le PIN (remplacer par votre logique)
    final response = await AuthService.login(
        login: phoneNumber!,
        password: _pin,
        token: token
    );



    if (response.success &&
        response.data != null &&
        response.data['token'] != null &&
        response.data['user'] != null){

      final newUser = User.fromJson(response.data['user']);
      await UserService.saveUser(newUser, response.data['token']);

      // Show success toast
      ToastHelper.showToast(
        context,
        title: "Connexion réussie !",
        message: "Bienvenue sur votre compte.",
        type: ToastType.success,
      );

      // Navigate to home after a short delay
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }

    } else {
      ToastHelper.showToast(
        context,
        title: "Connexion échoué !",
        message: "Identifiants invalides.",
        type: ToastType.error,
      );

      setState(() {
        _isError = true;
      });

      // Vibration et reset après erreur
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _pin = '';
        _isError = false;
      });
    }
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _pin.length
                ? (_isError ? Colors.red : Colors.blue)
                : Colors.blue.shade200,
          ),
        );
      }),
    );
  }

  Widget _buildNumberButton(String number) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNumberPressed(number),
        borderRadius: BorderRadius.circular(50),
        splashColor: Colors.blue.withOpacity(0.1),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withOpacity(0.1),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w300,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onDeletePressed,
        borderRadius: BorderRadius.circular(50),
        splashColor: Colors.white.withOpacity(0.1),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
          ),
          child: const Icon(
            Icons.backspace_outlined,
            color: Colors.blue,
            size: 28,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Center(
                child: Image.asset(
                  'assets/images/logo_assou.png',
                  fit: BoxFit.cover,
                  height: 80,
                ),
              ),
              const Spacer(flex: 2),

              // Points PIN
              _buildPinDots(),

              const Spacer(flex: 3),

              // Clavier numérique
              Column(
                children: [
                  // Ligne 1-2-3
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNumberButton('1'),
                      _buildNumberButton('2'),
                      _buildNumberButton('3'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Ligne 4-5-6
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNumberButton('4'),
                      _buildNumberButton('5'),
                      _buildNumberButton('6'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Ligne 7-8-9
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNumberButton('7'),
                      _buildNumberButton('8'),
                      _buildNumberButton('9'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Ligne vide-0-delete
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 80, height: 80),
                      _buildNumberButton('0'),
                      _buildDeleteButton(),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Lien mot de passe oublié
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen(
                    showDialogPasswordForget: true,
                  )));
                },
                child: const Text(
                  "Mot de passe oublié ?",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Exemple d'utilisation:
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (context) => const PinLoginScreen(),
//   ),
// );
