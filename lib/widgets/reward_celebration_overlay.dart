import 'package:flutter/material.dart';

class RewardCelebrationOverlay extends StatelessWidget {
  final int points;
  final String message;
  final VoidCallback? onDismiss;

  const RewardCelebrationOverlay({
    super.key,
    required this.points,
    required this.message,
    this.onDismiss,
  });

  /// Show the celebration overlay
  static void show({
    required BuildContext context,
    required int points,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => RewardCelebrationOverlay(
        points: points,
        message: message,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFC107),
              Color(0xFFFFD54F),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFC107).withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lottie animation or celebration icon
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated celebration icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: const Icon(
                          Icons.celebration,
                          size: 120,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  // Sparkle effect
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1200),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: 1 - value,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Points badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '$points points',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFC107),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 30),
            // Close button
            ElevatedButton(
              onPressed: onDismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFFC107),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Continuer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
