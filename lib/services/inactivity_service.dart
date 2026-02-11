import 'dart:async';
import 'package:flutter/material.dart';

class InactivityService {
  static final InactivityService _instance = InactivityService._internal();
  factory InactivityService() => _instance;

  InactivityService._internal();

  Timer? _inactivityTimer;
  final Duration timeout = const Duration(minutes: 5);

  VoidCallback? onTimeout;

  /// Appelé à chaque interaction utilisateur
  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(timeout, () {
      if (onTimeout != null) {
        onTimeout!();
      }
    });
  }

  /// Démarrer le suivi
  void startTracking(VoidCallback onTimeoutCallback) {
    onTimeout = onTimeoutCallback;
    _resetTimer();
  }

  /// Arrêter le suivi
  void stopTracking() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  /// Doit être appelé sur chaque interaction
  void userInteractionDetected() {
    _resetTimer();
  }
}
