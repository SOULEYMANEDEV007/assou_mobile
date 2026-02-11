import 'package:flutter/material.dart';

import '../services/inactivity_service.dart';

class InactivityTracker extends StatelessWidget {
  final Widget child;

  const InactivityTracker({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => InactivityService().userInteractionDetected(),
      child: child,
    );
  }
}
