import 'package:ASSOU/widgets/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/otp_service.dart';
import '../../services/settings_service.dart';
import '../../data/services/user_service.dart';
import '../../data/models/user_model.dart';
import '../../utils/logger.dart';
import '../home/home.dart';
import 'login_screen.dart';

class CompleteRegistrationScreen extends StatefulWidget {
  final String phoneNumber;

  const CompleteRegistrationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<CompleteRegistrationScreen> createState() =>
      _CompleteRegistrationScreenState();
}

class _CompleteRegistrationScreenState
    extends State<CompleteRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  String _cguLink = 'https://assou.app/cgu';

  @override
  void initState() {
    super.initState();
    AppLogger.info(
        'Complete registration screen initialized for ${widget.phoneNumber}',
        'REGISTRATION_UI');
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final cguLink = await SettingsService.getString('cgu_link',
          defaultValue: 'https://assou.app/cgu');
      setState(() {
        _cguLink = cguLink;
      });
      AppLogger.info('CGU link loaded: $_cguLink', 'REGISTRATION_UI');
    } catch (e) {
      AppLogger.error('Failed to load settings', 'REGISTRATION_UI', e);
    }
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) {
      AppLogger.info('Registration form validation failed', 'REGISTRATION_UI');
      return;
    }

    if (!_acceptTerms) {
      ToastHelper.showToast(context,
          title: "Conditions Générales",
          message: "Vous devez accepter les conditions d'utilisation",
          type: ToastType.warning);
      return;
    }

    AppLogger.info('Starting registration completion', 'REGISTRATION_UI');
    setState(() => _isLoading = true);

    try {
      final response = await OtpService.completeRegistration(
        phoneNumber: widget.phoneNumber,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (response.success &&
            response.user != null &&
            response.token != null) {
          AppLogger.info(
              'Registration completed successfully', 'REGISTRATION_UI');

          // SAVE USER DATA CORRECTLY
          final userData = User.fromJson(response.user!.toJson());
          await UserService.saveUser(userData, response.token!);

          ToastHelper.showToast(context,
              title: "Inscription réussie",
              message: 'Bienvenue ${userData.firstName} !',
              type: ToastType.success);

          // Navigate to home screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        } else {
          AppLogger.error('Registration completion failed: ${response.message}',
              'REGISTRATION_UI');
          ToastHelper.showToast(context,
              title: "Échec de l'inscription",
              message: response.message ??
                  "Une erreur est survenue lors de la finalisation.",
              type: ToastType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppLogger.error(
            'Exception during registration completion', 'REGISTRATION_UI', e);
        ToastHelper.showToast(context,
            title: "Erreur",
            message: "Une erreur inattendue est survenue.",
            type: ToastType.error);
      }
    }
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
              final Uri uri = Uri.parse(_cguLink);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (mounted) {
                  ToastHelper.showToast(context,
                      title: "Erreur",
                      message: "Impossible d'ouvrir les CGU",
                      type: ToastType.error);
                }
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
      body: Container(
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
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF3380fe),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(80),
                    bottomRight: Radius.circular(80),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/images/assouLogo.png",
                      height: 220,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Finaliser l'inscription",
                      style: TextStyle(
                        fontSize: 34,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
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
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Lien vers connexion
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                  children: [
                                    const TextSpan(
                                        text:
                                            'Si vous avez déjà créé votre compte, alors '),
                                    TextSpan(
                                      text: 'Connectez-vous',
                                      style: const TextStyle(
                                        color: Color(0xFF3380fe),
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const LoginScreen()),
                                          );
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Text("Pour le numéro ${widget.phoneNumber}",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 13)),

                            const SizedBox(height: 20),

                            _buildPillInput(
                              controller: _firstNameController,
                              hintText: 'Prénom',
                              validator: (val) => val == null || val.isEmpty
                                  ? "Prénom requis"
                                  : null,
                            ),

                            const SizedBox(height: 16),

                            _buildPillInput(
                              controller: _lastNameController,
                              hintText: 'Nom',
                              validator: (val) => val == null || val.isEmpty
                                  ? "Nom requis"
                                  : null,
                            ),

                            const SizedBox(height: 16),

                            _buildPillInput(
                              controller: _emailController,
                              hintText: 'Email (optionnel)',
                              keyboardType: TextInputType.emailAddress,
                            ),

                            const SizedBox(height: 16),

                            _buildPillInput(
                              controller: _passwordController,
                              hintText: 'Mot de passe (4 chiffres)',
                              isPassword: true,
                              isObscured: _obscurePassword,
                              onToggleObscure: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4)
                              ],
                              validator: (val) => val != null && val.length == 4
                                  ? null
                                  : "4 chiffres requis",
                            ),

                            const SizedBox(height: 16),

                            _buildPillInput(
                              controller: _confirmPasswordController,
                              hintText: 'Confirmer mot de passe',
                              isPassword: true,
                              isObscured: _obscureConfirmPassword,
                              onToggleObscure: () => setState(() =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4)
                              ],
                              validator: (val) =>
                                  val == _passwordController.text
                                      ? null
                                      : "Ne correspond pas",
                            ),

                            const SizedBox(height: 16),

                            // CGU
                            Row(
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  onChanged: (val) => setState(
                                      () => _acceptTerms = val ?? false),
                                  activeColor: const Color(0xFF3380fe),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _showTermsDialog,
                                    child: RichText(
                                      text: const TextSpan(
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87),
                                        children: [
                                          TextSpan(text: "J'accepte les "),
                                          TextSpan(
                                            text: "Conditions d'Utilisation",
                                            style: TextStyle(
                                                color: Color(0xFF3380fe),
                                                fontWeight: FontWeight.bold,
                                                decoration:
                                                    TextDecoration.underline),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Bouton
                            SizedBox(
                              height: 60,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _completeRegistration,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3380fe),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5))
                                    : const Text("Créer mon compte",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18)),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildPillInput({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    bool isObscured = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF3380fe),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: isPassword && isObscured,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              validator: validator,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          if (isPassword)
            IconButton(
              icon: Icon(
                isObscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF3380fe),
                size: 24,
              ),
              onPressed: onToggleObscure,
            ),
        ],
      ),
    );
  }
}
