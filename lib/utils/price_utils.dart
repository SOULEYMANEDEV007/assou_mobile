import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility class for formatting prices and monetary values
class PriceUtils {
  /// Default currency symbol
  static const String defaultCurrency = 'FCFA';

  /// Formats a price with thousands separators and currency
  /// Example: 25000 -> "25 000 FCFA"
  static String formatPrice(
    dynamic price, {
    String currency = defaultCurrency,
    bool showCurrency = true,
    String locale = 'de_DE',
  }) {
    if (price == null) return '0${showCurrency ? ' $currency' : ''}';

    double amount = 0.0;
    if (price is String) {
      amount = double.tryParse(price) ?? 0.0;
    } else if (price is num) {
      amount = price.toDouble();
    }

    // Use French formatting (spaces as thousands separators)
    final formatter = NumberFormat('#,##0', locale);
    String formattedPrice = formatter.format(amount);

    // Replace commas with spaces for French formatting
    formattedPrice = formattedPrice.replaceAll(',', ' ');

    return showCurrency ? '$formattedPrice $currency' : formattedPrice;
  }

  /// Formats price in a compact way for large amounts
  /// Example: 1500000 -> "1,5M FCFA", 25000 -> "25K FCFA"
  static String formatPriceCompact(
    dynamic price, {
    String currency = defaultCurrency,
    bool showCurrency = true,
  }) {
    if (price == null) return '0${showCurrency ? ' $currency' : ''}';

    double amount = 0.0;
    if (price is String) {
      amount = double.tryParse(price) ?? 0.0;
    } else if (price is num) {
      amount = price.toDouble();
    }

    String formattedPrice;

    if (amount >= 1000000000) {
      // Billions: 1.5B
      formattedPrice =
          '${(amount / 1000000000).toStringAsFixed(amount % 1000000000 == 0 ? 0 : 1)}B';
    } else if (amount >= 1000000) {
      // Millions: 1.5M
      formattedPrice =
          '${(amount / 1000000).toStringAsFixed(amount % 1000000 == 0 ? 0 : 1)}M';
    } else if (amount >= 1000) {
      // Thousands: 25K
      formattedPrice =
          '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    } else {
      // Less than 1000: just the number
      formattedPrice = amount.toStringAsFixed(0);
    }

    return showCurrency ? '$formattedPrice $currency' : formattedPrice;
  }

  /// Formats price with custom decimal places
  /// Example: 25000.50 -> "25 000,50 FCFA"
  static String formatPriceWithDecimals(
    dynamic price, {
    String currency = defaultCurrency,
    bool showCurrency = true,
    int decimalPlaces = 2,
    String locale = 'fr_FR',
  }) {
    if (price == null) return '0${showCurrency ? ' $currency' : ''}';

    double amount = 0.0;
    if (price is String) {
      amount = double.tryParse(price) ?? 0.0;
    } else if (price is num) {
      amount = price.toDouble();
    }

    final formatter = NumberFormat('#,##0.${'0' * decimalPlaces}', locale);
    String formattedPrice = formatter.format(amount);

    // Replace commas with spaces for thousands and dots with commas for decimals (French style)
    formattedPrice = formattedPrice.replaceAll(',', ' ');

    return showCurrency ? '$formattedPrice $currency' : formattedPrice;
  }

  /// Formats price for display in cards/lists
  /// Automatically chooses between compact and regular format based on amount
  static String formatPriceForDisplay(
    dynamic price, {
    String currency = defaultCurrency,
    bool showCurrency = true,
    bool preferCompact = false,
  }) {
    if (price == null) return '0${showCurrency ? ' $currency' : ''}';

    double amount = 0.0;
    if (price is String) {
      amount = double.tryParse(price) ?? 0.0;
    } else if (price is num) {
      amount = price.toDouble();
    }

    // Use compact format for large amounts or when preferred
    if (preferCompact || amount >= 1000000) {
      return formatPriceCompact(price,
          currency: currency, showCurrency: showCurrency);
    } else {
      return formatPrice(price, currency: currency, showCurrency: showCurrency);
    }
  }

  /// Gets price color based on amount (for visual hierarchy)
  static Color getPriceColor(
    dynamic price, {
    Color defaultColor = const Color(0xFF1E293B),
    Color highValueColor = const Color(0xFF059669), // Green
    Color mediumValueColor = const Color(0xFF3B82F6), // Blue
    Color lowValueColor = const Color(0xFF6B7280), // Gray
    double highThreshold = 100000,
    double mediumThreshold = 10000,
  }) {
    if (price == null) return lowValueColor;

    double amount = 0.0;
    if (price is String) {
      amount = double.tryParse(price) ?? 0.0;
    } else if (price is num) {
      amount = price.toDouble();
    }

    if (amount >= highThreshold) return highValueColor;
    if (amount >= mediumThreshold) return mediumValueColor;
    if (amount > 0) return defaultColor;
    return lowValueColor;
  }

  /// Creates a price widget with proper styling
  static Widget buildPriceWidget(
    dynamic price, {
    String currency = defaultCurrency,
    bool showCurrency = true,
    TextStyle? textStyle,
    bool useCompactFormat = false,
    bool autoColor = false,
  }) {
    final formattedPrice = useCompactFormat
        ? formatPriceCompact(price,
            currency: currency, showCurrency: showCurrency)
        : formatPrice(price, currency: currency, showCurrency: showCurrency);

    final color = autoColor ? getPriceColor(price) : null;
    final style = (textStyle ?? const TextStyle()).copyWith(
      color: color,
      fontWeight: FontWeight.w600,
    );

    return Text(formattedPrice, style: style);
  }

  /// Formats price for input fields (removes currency, proper decimal format)
  static String formatPriceForInput(dynamic price) {
    if (price == null) return '';

    double amount = 0.0;
    if (price is String) {
      amount = double.tryParse(price) ?? 0.0;
    } else if (price is num) {
      amount = price.toDouble();
    }

    if (amount == amount.toInt()) {
      return amount.toInt().toString();
    } else {
      return amount.toString();
    }
  }

  /// Parses a formatted price string back to double
  static double? parsePriceString(String priceString) {
    if (priceString.isEmpty) return null;

    // Remove currency and spaces
    String cleanPrice = priceString
        .replaceAll(RegExp(r'[^0-9,.]'), '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');

    return double.tryParse(cleanPrice);
  }

  /// Calculates percentage and formats it
  static String formatPercentage(
    dynamic value,
    dynamic total, {
    int decimalPlaces = 1,
  }) {
    if (value == null || total == null) return '0%';

    double val = 0.0;
    double tot = 0.0;

    if (value is String) {
      val = double.tryParse(value) ?? 0.0;
    } else if (value is num) val = value.toDouble();

    if (total is String) {
      tot = double.tryParse(total) ?? 0.0;
    } else if (total is num) tot = total.toDouble();

    if (tot == 0) return '0%';

    double percentage = (val / tot) * 100;
    return '${percentage.toStringAsFixed(decimalPlaces)}%';
  }
}

/// Extension methods for easier price formatting
extension PriceFormatting on dynamic {
  String get formattedPrice => PriceUtils.formatPrice(this);
  String get compactPrice => PriceUtils.formatPriceCompact(this);
  String get displayPrice => PriceUtils.formatPriceForDisplay(this);
  Color get priceColor => PriceUtils.getPriceColor(this);

  String priceWith({String currency = 'FCFA'}) =>
      PriceUtils.formatPrice(this, currency: currency);

  String compactPriceWith({String currency = 'FCFA'}) =>
      PriceUtils.formatPriceCompact(this, currency: currency);
}
