// lib/utils/app_navigator.dart
import 'package:ASSOU/pages/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:ASSOU/utils/session_manager.dart';
import 'package:ASSOU/utils/auth_guard.dart';
import 'package:ASSOU/pages/home/home.dart';

class AppNavigator {
  static Future<void> navigateToHome(BuildContext context) async {
    final isAuthenticated = await AuthGuard.checkAuthentication(context);
    if (isAuthenticated) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    }
  }

  static Future<void> navigateToLogin(BuildContext context) async {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  static Future<void> logout(BuildContext context) async {
    await SessionManager.clearSession();
    await navigateToLogin(context);
  }
}
