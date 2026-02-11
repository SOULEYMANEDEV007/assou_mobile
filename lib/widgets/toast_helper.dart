import 'package:flutter/material.dart';

class ToastHelper {
  static void showToast(
      BuildContext context, {
        required String title,
        required String message,
        ToastType type = ToastType.success,
        Duration duration = const Duration(seconds: 2),
      }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) {
        return _ToastDialog(
          title: title,
          message: message,
          type: type,
          duration: duration,
        );
      },
    );
  }
}

enum ToastType { success, error, warning, info }


class _ToastDialog extends StatefulWidget {
  final String title;
  final String message;
  final ToastType type;
  final Duration duration;

  const _ToastDialog({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    required this.duration,
  });

  @override
  State<_ToastDialog> createState() => _ToastDialogState();
}

class _ToastDialogState extends State<_ToastDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.type) {
      case ToastType.success:
        return Colors.green;
      case ToastType.error:
        return Colors.red;
      case ToastType.warning:
        return Colors.orange;
      case ToastType.info:
      default:
        return Colors.blue;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.cancel_rounded;
      case ToastType.warning:
        return Icons.warning;
      case ToastType.info:
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _color.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, color: _color, size: 60),
              const SizedBox(height: 14),
              Text(
                widget.title,
                style: TextStyle(
                  color: _color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.message,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


