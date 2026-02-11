class AppNotification {
  final int id;
  final String slug;
  final String titre;
  final String? description;
  final String? message;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? type;
  final Map<String, dynamic>? data;
  
  AppNotification({
    required this.id,
    required this.slug,
    required this.titre,
    this.description,
    this.message,
    required this.isRead,
    required this.createdAt,
    this.updatedAt,
    this.type,
    this.data,
  });
  
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? 0,
      slug: json['slug'] ?? '',
      titre: json['titre'] ?? json['title'] ?? '',
      description: json['description'],
      message: json['message'],
      isRead: json['is_read'] ?? json['read_at'] != null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : null,
      type: json['type'],
      data: json['data'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'titre': titre,
      'description': description,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'type': type,
      'data': data,
    };
  }
  
  // Helper methods
  String get displayTitle => titre.isNotEmpty ? titre : 'Notification';
  String get displayMessage => message ?? description ?? '';
  
  bool get hasMessage => message != null && message!.isNotEmpty;
  bool get hasDescription => description != null && description!.isNotEmpty;
  
  // Get formatted creation date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
  
  // Get full formatted date
  String get fullFormattedDate {
    final date = createdAt;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  // Notification type helpers
  bool get isPaymentNotification => type == 'payment';
  bool get isVoucherNotification => type == 'voucher';
  bool get isGeneralNotification => type == 'general' || type == null;
  bool get isPromotionNotification => type == 'promotion';
  
  // Priority levels (if added to backend later)
  NotificationPriority get priority {
    if (data?['priority'] != null) {
      switch (data!['priority']) {
        case 'high': return NotificationPriority.high;
        case 'medium': return NotificationPriority.medium;
        case 'low': return NotificationPriority.low;
        default: return NotificationPriority.normal;
      }
    }
    return NotificationPriority.normal;
  }
  
  // Copy with method for state management
  AppNotification copyWith({
    int? id,
    String? slug,
    String? titre,
    String? description,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? type,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      data: data ?? this.data,
    );
  }
}

enum NotificationPriority {
  low,
  normal,
  medium,
  high,
}

class NotificationMarkReadResponse {
  final bool success;
  final String message;
  final AppNotification? notification;
  
  NotificationMarkReadResponse({
    required this.success,
    required this.message,
    this.notification,
  });
  
  factory NotificationMarkReadResponse.fromJson(Map<String, dynamic> json) {
    return NotificationMarkReadResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      notification: json['data'] != null 
        ? AppNotification.fromJson(json['data']) 
        : null,
    );
  }
}
