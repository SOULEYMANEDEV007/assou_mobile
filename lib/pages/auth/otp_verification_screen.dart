import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/otp_service.dart';
import '../../services/settings_service.dart';
import '../../utils/logger.dart';
import 'complete_registration_screen.dart';
import '../../widgets/wave_clipper.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String action;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.action = 'registration',
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _canResend = false;
  int _countdown = 300; // 5 minutes
  Timer? _timer;
  int _otpLength = 6;

  @override
  void initState() {
    super.initState();
    AppLogger.info(
        'OTP verification screen initialized for ${widget.phoneNumber}',
        'OTP_UI');
    _loadOtpSettings();
    _startCountdown();
  }

  Future<void> _loadOtpSettings() async {
    try {
      final otpLength =
          await SettingsService.getInt('otp_length', defaultValue: 6);
      final companyName = await SettingsService.getString('company_name',
          defaultValue: 'Assou');

      setState(() {
        _otpLength = otpLength > 0 ? otpLength : 6;
      });

      AppLogger.info(
          'OTP settings loaded: length=$otpLength, company=$companyName',
          'OTP_UI');
    } catch (e) {
      AppLogger.error('Failed to load OTP settings', 'OTP_UI', e);
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            _canResend = true;
            _timer?.cancel();
          }
        });
      }
    });
  }

  String get _formattedCountdown {
    final minutes = (_countdown ~/ 60).toString().padLeft(2, '0');
    final seconds = (_countdown % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _verifyOtp() async {
    final expectedLength = _otpLength > 0 ? _otpLength : 6;
    if (_otpController.text.length != expectedLength) {
      _showSnackBar('Veuillez saisir le code complet', isError: true);
      return;
    }

    AppLogger.info('Starting OTP verification', 'OTP_UI');
    setState(() => _isLoading = true);

    final response = await OtpService.verifyOtp(
      widget.phoneNumber,
      _otpController.text,
      action: widget.action,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (response.success) {
        AppLogger.info('OTP verification successful', 'OTP_UI');
        _showSnackBar(response.message, isError: false);

        if (widget.action == 'registration') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CompleteRegistrationScreen(
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        } else if (widget.action == 'password_reset') {
          Navigator.pop(context, true);
        } else {
          Navigator.pop(context, true);
        }
      } else {
        AppLogger.error(
            'OTP verification failed: ${response.message}', 'OTP_UI');
        _otpController.clear();
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) {
      _showSnackBar('Veuillez attendre 5 minutes avant de renvoyer un code',
          isError: true);
      return;
    }

    AppLogger.info('Resending OTP', 'OTP_UI');
    setState(() => _isLoading = true);

    final response = await OtpService.resendOtp(
      widget.phoneNumber,
      action: widget.action,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (response.success) {
        AppLogger.info('OTP resent successfully', 'OTP_UI');
        _showSnackBar('Code renvoyé avec succès', isError: false);

        setState(() {
          _canResend = false;
          _countdown = 300; // reset 5 minutes
        });
        _startCountdown();
      } else {
        AppLogger.error('Failed to resend OTP: ${response.message}', 'OTP_UI');
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: Duration(seconds: isError ? 4 : 3),
        ),
      );
    }
  }

  String _formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.length == 10 && phoneNumber.startsWith('0')) {
      return '+225 ${phoneNumber.substring(0, 2)} ${phoneNumber.substring(2, 4)} '
          '${phoneNumber.substring(4, 6)} ${phoneNumber.substring(6, 8)} '
          '${phoneNumber.substring(8)}';
    }
    return phoneNumber;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeeedf3),
      body: Stack(
        children: [
          // Header bleu avec vague
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.40,
            child: ClipPath(
              clipper: WaveClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF3380fe),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Text(
                        "Code de vérification",
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

          // Carte blanche
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                  Container(
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
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: Color(0xFF3380fe),
                          size: 60,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Nous avons envoyé un code de vérification via SMS au numéro',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontFamily: 'Nunito',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatPhoneNumber(widget.phoneNumber),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                            fontFamily: 'Nunito',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // PIN input
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(_otpLength),
                          ],
                          onChanged: (value) {
                            if (value.length == _otpLength) {
                              _verifyOtp();
                            }
                          },
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3380fe),
                            letterSpacing: 12,
                          ),
                          decoration: InputDecoration(
                            hintText: '•' * _otpLength,
                            hintStyle: TextStyle(
                              fontSize: 28,
                              color: Colors.grey[300],
                              letterSpacing: 12,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF1F7FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Bouton
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (_isLoading ||
                                    _otpController.text.length != _otpLength)
                                ? null
                                : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3380fe),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Text(
                                    'Vérifier',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Renvoyer le code
                        if (!_canResend)
                          Text(
                            'Renvoyer le code dans $_formattedCountdown',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          )
                        else
                          TextButton(
                            onPressed: _isLoading ? null : _resendOtp,
                            child: const Text(
                              'Renvoyer le code',
                              style: TextStyle(
                                color: Color(0xFF3380fe),
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
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
    );
  }
}
