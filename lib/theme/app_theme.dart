import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // Primary Brand Colors - Based on ASSOU blue theme
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);

  // Secondary Colors - ASSOU yellow/gold accent
  static const Color secondary = Color(0xFFFBBF24);
  static const Color secondaryDark = Color(0xFFF59E0B);
  static const Color secondaryLight = Color(0xFFFDE047);

  // Background Colors - Clean, modern palette
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color surfaceSecondary = Color(0xFFE2E8F0);

  // Text Colors - Improved contrast and hierarchy
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);

  // Status Colors - Modern, accessible colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF06B6D4);
  static const Color infoLight = Color(0xFFCFFAFE);

  // Border & Divider
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);

  // Card Colors
  static const Color cardShadow = Color(0x0A000000);
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Special Colors for ASSOU theme
  static const Color voucherActive = Color(0xFF3B82F6);
  static const Color voucherExpiring = Color(0xFFFBBF24);
  static const Color voucherExpired = Color(0xFF94A3B8);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextTertiary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF475569);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

class AppBorderRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;
}

class AppShadows {
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x06000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -1,
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x19000000),
      offset: Offset(0, 20),
      blurRadius: 25,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 10),
      blurRadius: 10,
      spreadRadius: -5,
    ),
  ];

  // Special shadows for ASSOU components
  static List<BoxShadow> voucherCard = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.1),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> actionButton = [
    BoxShadow(
      color: AppColors.secondary.withOpacity(0.2),
      offset: const Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
}

class AppTextStyles {
  // Display styles
  static const TextStyle displayLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.1,
    letterSpacing: -0.5,
    fontFamily: 'Nunito',
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.25,
    fontFamily: 'Nunito',
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    fontFamily: 'Nunito',
  );

  // Headline styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    fontFamily: 'Nunito',
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    fontFamily: 'Nunito',
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    fontFamily: 'Nunito',
  );

  // Title styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
    fontFamily: 'Nunito',
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    fontFamily: 'Nunito',
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    fontFamily: 'Nunito',
  );

  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
    fontFamily: 'Nunito',
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
    fontFamily: 'Nunito',
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
    fontFamily: 'Nunito',
  );

  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
    fontFamily: 'Nunito',
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.3,
    fontFamily: 'Nunito',
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.3,
    fontFamily: 'Nunito',
  );

  // Special ASSOU styles
  static const TextStyle voucherAmount = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.2,
    fontFamily: 'Nunito',
  );

  static const TextStyle voucherSubtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.3,
    fontFamily: 'Nunito',
  );

  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    fontFamily: 'Nunito',
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.25,
    fontFamily: 'Nunito',
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',

      // Color Scheme
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.secondaryLight,
        onSecondaryContainer: AppColors.secondaryDark,
        tertiary: AppColors.info,
        onTertiary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: AppColors.errorLight,
        onErrorContainer: AppColors.error,
        outline: AppColors.border,
        outlineVariant: AppColors.borderLight,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.textSecondary,
        inverseSurface: AppColors.textPrimary,
        onInverseSurface: AppColors.surface,
        inversePrimary: AppColors.primaryLight,
        shadow: AppColors.cardShadow,
        scrim: Colors.black54,
        surfaceTint: AppColors.primary,
      ),

      scaffoldBackgroundColor: AppColors.background,

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headlineMedium,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: AppColors.cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          textStyle: AppTextStyles.buttonLarge,
          minimumSize: const Size(120, 48),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          textStyle: AppTextStyles.buttonLarge,
          minimumSize: const Size(120, 48),
        ),
      ),

      // Filled Button Theme (for secondary actions)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          textStyle: AppTextStyles.buttonLarge,
          minimumSize: const Size(120, 48),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F7FF), // Premium light blue-wash

        // Border styles
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide:
              BorderSide(color: AppColors.primary.withOpacity(0.2), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
              color: AppColors.borderLight.withOpacity(0.5), width: 1),
        ),

        // Content padding
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 18,
        ),

        // Text styles
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        floatingLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.error,
          fontSize: 11,
        ),

        // Constraints
        constraints: const BoxConstraints(
          minHeight: 56,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 24,
        shadowColor: AppColors.cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        ),
        titleTextStyle: AppTextStyles.headlineSmall,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        highlightElevation: 12,
        shape: CircleBorder(),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        titleTextStyle: AppTextStyles.titleMedium,
        subtitleTextStyle: AppTextStyles.bodySmall,
        leadingAndTrailingTextStyle: AppTextStyles.labelMedium,
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.border, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xs),
        ),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.border;
        }),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withOpacity(0.5);
          }
          return AppColors.border;
        }),
      ),

      // Tab Bar Theme
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.titleMedium,
        unselectedLabelStyle: AppTextStyles.titleMedium,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.divider,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceVariant,
        circularTrackColor: AppColors.surfaceVariant,
      ),
    );
  }

  // Helper method to get consistent shadows for specific components
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.sm,
      );

  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: AppShadows.md,
      );

  static BoxDecoration get voucherCardDecoration => BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        boxShadow: AppShadows.voucherCard,
      );

  static BoxDecoration get actionButtonDecoration => BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: AppShadows.actionButton,
      );

  /// Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Nunito',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.surface,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textPrimary,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.error,
        onError: AppColors.surface,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,
        onSurfaceVariant: AppColors.darkTextSecondary,
        outline: AppColors.darkBorder,
      ),

      // App Bar Theme (Dark)
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: AppColors.darkSurface,
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // Card Theme (Dark)
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button Theme (Dark)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Text Theme (Dark)
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge
            .copyWith(color: AppColors.darkTextPrimary),
        displayMedium: AppTextStyles.displayMedium
            .copyWith(color: AppColors.darkTextPrimary),
        displaySmall: AppTextStyles.displaySmall
            .copyWith(color: AppColors.darkTextPrimary),
        headlineLarge: AppTextStyles.headlineLarge
            .copyWith(color: AppColors.darkTextPrimary),
        headlineMedium: AppTextStyles.headlineMedium
            .copyWith(color: AppColors.darkTextPrimary),
        headlineSmall: AppTextStyles.headlineSmall
            .copyWith(color: AppColors.darkTextPrimary),
        titleLarge:
            AppTextStyles.titleLarge.copyWith(color: AppColors.darkTextPrimary),
        titleMedium: AppTextStyles.titleMedium
            .copyWith(color: AppColors.darkTextPrimary),
        titleSmall: AppTextStyles.titleSmall
            .copyWith(color: AppColors.darkTextSecondary),
        bodyLarge:
            AppTextStyles.bodyLarge.copyWith(color: AppColors.darkTextPrimary),
        bodyMedium: AppTextStyles.bodyMedium
            .copyWith(color: AppColors.darkTextSecondary),
        bodySmall:
            AppTextStyles.bodySmall.copyWith(color: AppColors.darkTextTertiary),
        labelLarge:
            AppTextStyles.labelLarge.copyWith(color: AppColors.darkTextPrimary),
        labelMedium: AppTextStyles.labelMedium
            .copyWith(color: AppColors.darkTextSecondary),
        labelSmall: AppTextStyles.labelSmall
            .copyWith(color: AppColors.darkTextTertiary),
      ),

      // Input Decoration Theme (Dark)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
              color: AppColors.darkBorder.withOpacity(0.5), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: AppTextStyles.bodyMedium
            .copyWith(color: AppColors.darkTextSecondary),
        hintStyle: AppTextStyles.bodyMedium
            .copyWith(color: AppColors.darkTextTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 18,
        ),
      ),

      // Bottom Navigation Bar Theme (Dark)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkTextTertiary,
        selectedLabelStyle: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.darkTextTertiary,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  // Dark mode decorations
  static BoxDecoration get darkCardDecoration => BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.darkBorder),
      );

  static BoxDecoration get darkElevatedCardDecoration => BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
}
