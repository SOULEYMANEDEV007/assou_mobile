// lib/data/models/qr_scan_result_model.dart
import 'boutique_model.dart';

class QRScanResult {
  final String qrCode;
  final String type;
  final String typeLabel;
  final Map<String, dynamic> data;
  final int usageCount;
  final DateTime? expiresAt;
  final Boutique boutique;
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
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      usageCount: json['usage_count'] ?? 0,
      expiresAt: json['expires_at'] != null 
          ? DateTime.tryParse(json['expires_at']) 
          : null,
      boutique: Boutique.fromJson(json['boutique'] ?? {}),
      scannedAt: DateTime.tryParse(json['scanned_at'] ?? '') ?? DateTime.now(),
    );
  }

  // Helper methods for different QR types
  bool get isPaymentQR => type == 'payment';
  bool get isContactQR => type == 'contact';
  bool get isPromotionQR => type == 'promotion';
  bool get isGeneralQR => type == 'general';

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
