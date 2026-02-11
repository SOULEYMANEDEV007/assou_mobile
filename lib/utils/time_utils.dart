import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility class for formatting time durations and dates
class TimeUtils {
  
  /// Converts a decimal day value to a human-readable format
  /// Returns the most appropriate unit (days, hours, or minutes)
  static String formatTimeUntilExpiration(double? days) {
    if (days == null) return '0 minute';
    
    // Handle negative values (already expired)
    if (days < 0) return 'Expiré';
    
    // If more than 1 day, show in days
    if (days >= 1) {
      int wholeDays = days.floor();
      if (wholeDays == 1) {
        return '1 jour';
      } else {
        return '$wholeDays jours';
      }
    }
    
    // Convert to hours
    double totalHours = days * 24;
    
    // If more than 1 hour, show in hours
    if (totalHours >= 1) {
      int wholeHours = totalHours.floor();
      if (wholeHours == 1) {
        return '1 heure';
      } else {
        return '$wholeHours heures';
      }
    }
    
    // Convert to minutes
    double totalMinutes = totalHours * 60;
    int wholeMinutes = totalMinutes.round();
    
    // Minimum 1 minute
    if (wholeMinutes < 1) {
      return '1 minute';
    } else if (wholeMinutes == 1) {
      return '1 minute';
    } else {
      return '$wholeMinutes minutes';
    }
  }
  
  /// More detailed version that shows the most significant unit
  /// with decimal precision for better accuracy
  static String formatTimeUntilExpirationDetailed(double? days) {
    if (days == null) return '0 minute';
    
    // Handle negative values (already expired)
    if (days < 0) return 'Expiré';
    
    // If more than 1 day, show days with decimal
    if (days >= 1) {
      if (days < 2) {
        return '${days.toStringAsFixed(1)} jour';
      } else {
        return '${days.toStringAsFixed(1)} jours';
      }
    }
    
    // Convert to hours
    double totalHours = days * 24;
    
    // If more than 1 hour, show in hours
    if (totalHours >= 1) {
      if (totalHours < 2) {
        return '${totalHours.toStringAsFixed(1)} heure';
      } else {
        return '${totalHours.toStringAsFixed(1)} heures';
      }
    }
    
    // Convert to minutes
    double totalMinutes = totalHours * 60;
    int wholeMinutes = totalMinutes.round();
    
    // Minimum 1 minute
    if (wholeMinutes < 1) {
      return '1 minute';
    } else if (wholeMinutes == 1) {
      return '1 minute';
    } else {
      return '$wholeMinutes minutes';
    }
  }
  
  /// Returns a short format suitable for compact displays
  static String formatTimeUntilExpirationShort(double? days) {
    if (days == null) return '0m';
    
    // Handle negative values (already expired)
    if (days < 0) return 'Expiré';
    
    // If more than 1 day, show in days
    if (days >= 1) {
      int wholeDays = days.floor();
      return '${wholeDays}j';
    }
    
    // Convert to hours
    double totalHours = days * 24;
    
    // If more than 1 hour, show in hours
    if (totalHours >= 1) {
      int wholeHours = totalHours.floor();
      return '${wholeHours}h';
    }
    
    // Convert to minutes
    double totalMinutes = totalHours * 60;
    int wholeMinutes = totalMinutes.round();
    
    // Minimum 1 minute
    if (wholeMinutes < 1) {
      return '1m';
    } else {
      return '${wholeMinutes}m';
    }
  }
  
  /// Returns color based on urgency level
  static Color getExpirationColor(double? days) {
    if (days == null) return const Color(0xFF94A3B8); // Gray
    
    if (days < 0) return const Color(0xFF6B7280); // Dark gray (expired)
    if (days < 0.0417) return const Color(0xFFDC2626); // Red (< 1 hour)
    if (days < 0.125) return const Color(0xFFEA580C); // Orange (< 3 hours)
    if (days < 1) return const Color(0xFFFBBF24); // Yellow (< 1 day)
    if (days < 7) return const Color(0xFF059669); // Green (< 1 week)
    return const Color(0xFF3B82F6); // Blue (> 1 week)
  }
  
  /// Returns an appropriate icon based on urgency
  static IconData getExpirationIcon(double? days) {
    if (days == null) return Icons.schedule;
    
    if (days < 0) return Icons.block; // Expired
    if (days < 0.0417) return Icons.warning; // < 1 hour
    if (days < 0.125) return Icons.access_time; // < 3 hours
    if (days < 1) return Icons.schedule; // < 1 day
    return Icons.access_time_outlined; // > 1 day
  }
  
  /// Complete widget for displaying expiration info with color and icon
  static Widget buildExpirationWidget(double? days, {
    TextStyle? textStyle,
    bool showIcon = true,
    bool useShortFormat = false,
  }) {
    final color = getExpirationColor(days);
    final icon = getExpirationIcon(days);
    final text = useShortFormat 
        ? formatTimeUntilExpirationShort(days)
        : formatTimeUntilExpiration(days);
    
    final style = (textStyle ?? const TextStyle()).copyWith(color: color);
    
    if (showIcon) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(text, style: style),
        ],
      );
    } else {
      return Text(text, style: style);
    }
  }
  
  // =====================
  // DATE FORMATTING METHODS
  // =====================
  
  /// Formats date to French format: "10 août 2025"
  static String formatDateFrench(dynamic date) {
    if (date == null) return '';
    
    DateTime? dateTime;
    if (date is String) {
      dateTime = DateTime.tryParse(date);
    } else if (date is DateTime) {
      dateTime = date;
    }
    
    if (dateTime == null) return '';
    
    final formatter = DateFormat('d MMMM yyyy', 'fr_FR');
    return formatter.format(dateTime);
  }
  
  /// Formats date to short French format: "10 août"
  static String formatDateShortFrench(dynamic date) {
    if (date == null) return '';
    
    DateTime? dateTime;
    if (date is String) {
      dateTime = DateTime.tryParse(date);
    } else if (date is DateTime) {
      dateTime = date;
    }
    
    if (dateTime == null) return '';
    
    final formatter = DateFormat('d MMMM', 'fr_FR');
    return formatter.format(dateTime);
  }
  
  /// Formats date to ISO format: "2025-08-10"
  static String formatDateISO(dynamic date) {
    if (date == null) return '';
    
    DateTime? dateTime;
    if (date is String) {
      dateTime = DateTime.tryParse(date);
    } else if (date is DateTime) {
      dateTime = date;
    }
    
    if (dateTime == null) return '';
    
    final formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(dateTime);
  }
  
  /// Formats date to European format: "10/08/2025"
  static String formatDateEuropean(dynamic date) {
    if (date == null) return '';
    
    DateTime? dateTime;
    if (date is String) {
      dateTime = DateTime.tryParse(date);
    } else if (date is DateTime) {
      dateTime = date;
    }
    
    if (dateTime == null) return '';
    
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(dateTime);
  }
  
  /// Formats date and time: "10 août 2025 à 14h30"
  static String formatDateTimeFrench(dynamic dateTime) {
    if (dateTime == null) return '';
    
    DateTime? dt;
    if (dateTime is String) {
      dt = DateTime.tryParse(dateTime);
    } else if (dateTime is DateTime) {
      dt = dateTime;
    }
    
    if (dt == null) return '';
    
    final formatter = DateFormat('d MMMM yyyy à HH\'h\'mm', 'fr_FR');
    return formatter.format(dt);
  }
  
  /// Formats time only: "14h30"
  static String formatTimeFrench(dynamic dateTime) {
    if (dateTime == null) return '';
    
    DateTime? dt;
    if (dateTime is String) {
      dt = DateTime.tryParse(dateTime);
    } else if (dateTime is DateTime) {
      dt = dateTime;
    }
    
    if (dt == null) return '';
    
    final formatter = DateFormat('HH\'h\'mm');
    return formatter.format(dt);
  }
  
  /// Formats date relative to now: "Aujourd'hui", "Hier", "Dans 3 jours", etc.
  static String formatDateRelative(dynamic date) {
    if (date == null) return '';
    
    DateTime? dateTime;
    if (date is String) {
      dateTime = DateTime.tryParse(date);
    } else if (date is DateTime) {
      dateTime = date;
    }
    
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = targetDate.difference(today).inDays;
    
    switch (difference) {
      case -1:
        return 'A expiré hier';
      case 0:
        return 'Expire aujourd\'hui';
      case 1:
        return 'Expire demain';
      default:
        if (difference < -1) {
          return 'A expiré il y a ${-difference} jours';
        } else {
          return 'Expire dans $difference jours';
        }
    }
  }
  
  /// Returns day of week in French: "Lundi", "Mardi", etc.
  static String formatDayOfWeek(dynamic date) {
    if (date == null) return '';
    
    DateTime? dateTime;
    if (date is String) {
      dateTime = DateTime.tryParse(date);
    } else if (date is DateTime) {
      dateTime = date;
    }
    
    if (dateTime == null) return '';
    
    final formatter = DateFormat('EEEE', 'fr_FR');
    return formatter.format(dateTime);
  }
  
  /// Returns month name in French: "Janvier", "Février", etc.
  static String formatMonthName(dynamic date) {
    if (date == null) return '';
    
    DateTime? dateTime;
    if (date is String) {
      dateTime = DateTime.tryParse(date);
    } else if (date is DateTime) {
      dateTime = date;
    }
    
    if (dateTime == null) return '';
    
    final formatter = DateFormat('MMMM', 'fr_FR');
    return formatter.format(dateTime);
  }
  
  /// Checks if a date is today
  static bool isToday(dynamic date) {
    if (date == null) return false;
    
    DateTime? dateTime;
    if (date is String) {
      dateTime = DateTime.tryParse(date);
    } else if (date is DateTime) {
      dateTime = date;
    }
    
    if (dateTime == null) return false;
    
    final now = DateTime.now();
    return dateTime.year == now.year &&
           dateTime.month == now.month &&
           dateTime.day == now.day;
  }
  
  /// Checks if a date is in the past
  static bool isPast(dynamic date) {
    if (date == null) return false;
    
    DateTime? dateTime;
    if (date is String) {
      dateTime = DateTime.tryParse(date);
    } else if (date is DateTime) {
      dateTime = date;
    }
    
    if (dateTime == null) return false;
    
    return dateTime.isBefore(DateTime.now());
  }
  
  /// Checks if a date is in the future
  static bool isFuture(dynamic date) {
    if (date == null) return false;
    
    DateTime? dateTime;
    if (date is String) {
      dateTime = DateTime.tryParse(date);
    } else if (date is DateTime) {
      dateTime = date;
    }
    
    if (dateTime == null) return false;
    
    return dateTime.isAfter(DateTime.now());
  }
}

/// Extension method to make it easier to use
extension TimeFormatting on double? {
  String get timeUntilExpiration => TimeUtils.formatTimeUntilExpiration(this);
  String get timeUntilExpirationShort => TimeUtils.formatTimeUntilExpirationShort(this);
  String get timeUntilExpirationDetailed => TimeUtils.formatTimeUntilExpirationDetailed(this);
  Color get expirationColor => TimeUtils.getExpirationColor(this);
  IconData get expirationIcon => TimeUtils.getExpirationIcon(this);
}

/// Extension methods for date formatting
extension DateFormatting on dynamic {
  String get frenchDate => TimeUtils.formatDateFrench(this);
  String get shortFrenchDate => TimeUtils.formatDateShortFrench(this);
  String get isoDate => TimeUtils.formatDateISO(this);
  String get europeanDate => TimeUtils.formatDateEuropean(this);
  String get frenchDateTime => TimeUtils.formatDateTimeFrench(this);
  String get frenchTime => TimeUtils.formatTimeFrench(this);
  String get relativeDate => TimeUtils.formatDateRelative(this);
  String get dayOfWeek => TimeUtils.formatDayOfWeek(this);
  String get monthName => TimeUtils.formatMonthName(this);
  bool get isToday => TimeUtils.isToday(this);
  bool get isPast => TimeUtils.isPast(this);
  bool get isFuture => TimeUtils.isFuture(this);
}
