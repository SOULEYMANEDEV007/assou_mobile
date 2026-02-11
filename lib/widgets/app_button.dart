import 'package:flutter/material.dart';

// Custom App Button matching ASSOU design
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final Color? backgroundColor; // ✅ ajouté
  final Color? foregroundColor; // ✅ ajouté

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.large,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.backgroundColor, // ✅ ajouté
    this.foregroundColor, // ✅ ajouté
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Priorité : si les couleurs personnalisées sont définies, on les utilise.
    final bgColor = backgroundColor ?? type.backgroundColor;
    final fgColor = foregroundColor ?? type.foregroundColor;

    return SizedBox(
      height: size.height,
      width: size == ButtonSize.large ? double.infinity : null,
      child: ElevatedButton(
        onPressed: (isDisabled || isLoading) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size.borderRadius),
            side: type.borderSide,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: size.horizontalPadding,
            vertical: size.verticalPadding,
          ),
        ),
        child: isLoading
            ? Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: size.iconSize),
              SizedBox(width: size.iconSpacing),
            ],
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: size.fontSize,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ButtonType {
  primary(
    backgroundColor: Color(0xFF3B82F6),
    foregroundColor: Colors.white,
    borderSide: BorderSide.none,
  ),
  secondary(
    backgroundColor: Color(0xFFFBBF24),
    foregroundColor: Colors.white,
    borderSide: BorderSide.none,
  ),
  outline(
    backgroundColor: Colors.transparent,
    foregroundColor: Color(0xFF3B82F6),
    borderSide: BorderSide(color: Color(0xFF3B82F6), width: 1.5),
  ),
  ghost(
    backgroundColor: Colors.transparent,
    foregroundColor: Color(0xFF3B82F6),
    borderSide: BorderSide.none,
  );

  const ButtonType({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderSide,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final BorderSide borderSide;
}

enum ButtonSize {
  small(
    height: 36.0,
    fontSize: 14.0,
    borderRadius: 8.0,
    horizontalPadding: 16.0,
    verticalPadding: 8.0,
    iconSize: 16.0,
    iconSpacing: 8.0,
  ),
  medium(
    height: 44.0,
    fontSize: 16.0,
    borderRadius: 12.0,
    horizontalPadding: 20.0,
    verticalPadding: 12.0,
    iconSize: 18.0,
    iconSpacing: 8.0,
  ),
  large(
    height: 52.0,
    fontSize: 16.0,
    borderRadius: 16.0,
    horizontalPadding: 24.0,
    verticalPadding: 16.0,
    iconSize: 20.0,
    iconSpacing: 10.0,
  );

  const ButtonSize({
    required this.height,
    required this.fontSize,
    required this.borderRadius,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.iconSize,
    required this.iconSpacing,
  });

  final double height;
  final double fontSize;
  final double borderRadius;
  final double horizontalPadding;
  final double verticalPadding;
  final double iconSize;
  final double iconSpacing;
}
