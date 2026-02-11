// lib/utils/auth_guard.dart
import 'package:ASSOU/pages/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:ASSOU/utils/session_manager.dart';

class AuthGuard {
  static Future<bool> checkAuthentication(BuildContext context) async {
    final isValid = await SessionManager.isSessionValid();
    
    if (!isValid) {
      // Navigate to login if not authenticated
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
      return false;
    }
    
    return true;
  }

  static Future<void> requireAuthentication(
    BuildContext context,
    VoidCallback onAuthenticated,
  ) async {
    final isAuthenticated = await checkAuthentication(context);
    if (isAuthenticated) {
      onAuthenticated();
    }
  }
}
