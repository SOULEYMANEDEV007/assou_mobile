class QRScanResult {
  final String qrCode;
  final String type;
  final String typeLabel;
  final Map<String, dynamic> data;
  final int usageCount;
  final DateTime? expiresAt;
  final QRBoutique boutique;
  final DateTime scannedAt;
  
  QRScanResult({
    required this.qrCode,
    required this.type,
    required this.typeLabel,
    required this.data,
    required this.usageCount,
    this.expiresAt,
    required this.boutique,
    required this.scannedAt,
  });
  
  factory QRScanResult.fromJson(Map<String, dynamic> json) {
    return QRScanResult(
      qrCode: json['qr_code'] ?? '',
      type: json['type'] ?? '',
      typeLabel: json['type_label'] ?? '',
      data: json['data'] ?? {},
      usageCount: json['usage_count'] ?? 0,
      expiresAt: json['expires_at'] != null 
        ? DateTime.parse(json['expires_at']) 
        : null,
      boutique: QRBoutique.fromJson(json['boutique']),
      scannedAt: json['scanned_at'] != null
        ? DateTime.parse(json['scanned_at'])
        : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'qr_code': qrCode,
      'type': type,
      'type_label': typeLabel,
      'data': data,
      'usage_count': usageCount,
      'expires_at': expiresAt?.toIso8601String(),
      'boutique': boutique.toJson(),
      'scanned_at': scannedAt.toIso8601String(),
    };
  }
  
  // Helper methods for different QR types
  bool get isPaymentQR => type == 'payment';
  bool get isContactQR => type == 'contact';
  bool get isPromotionQR => type == 'promotion';
  bool get isGeneralQR => type == 'general';
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  
  Map<String, String>? get paymentMethods {
    if (!isPaymentQR) return null;
    return Map<String, String>.from(data['payment_methods'] ?? {});
  }
  
  String? get contactEmail => isContactQR ? data['email'] : null;
  String? get contactPhone => isContactQR ? data['phone'] : null;
  String? get contactAddress => isContactQR ? data['address'] : null;
  
  int? get activeVouchersCount => isPromotionQR ? data['active_vouchers'] : null;
  double? get totalVoucherAmount => isPromotionQR ? data['total_voucher_amount']?.toDouble() : null;
}

class QRBoutique {
  final int id;
  final String name;
  final String codeBoutique;
  final String? description;
  final String? logo;
  final String? contact;
  final String? adresse;
  final String? email;
  
  QRBoutique({
    required this.id,
    required this.name,
    required this.codeBoutique,
    this.description,
    this.logo,
    this.contact,
    this.adresse,
    this.email,
  });
  
  factory QRBoutique.fromJson(Map<String, dynamic> json) {
    return QRBoutique(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['nom'] ?? '',
      codeBoutique: json['code_boutique'] ?? '',
      description: json['description'],
      logo: json['logo'],
      contact: json['contact'],
      adresse: json['adresse'],
      email: json['email'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code_boutique': codeBoutique,
      'description': description,
      'logo': logo,
      'contact': contact,
      'adresse': adresse,
      'email': email,
    };
  }
  
  // Helper method to get logo URL
  String? get logoUrl {
    if (logo == null || logo!.isEmpty) return null;
    if (logo!.startsWith('http')) return logo;
    return 'https://your-domain.com/storage/$logo';
  }
}
