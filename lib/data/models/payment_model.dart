import 'bon_achat_model.dart';

class Payment {
  final int id;
  final String slug;
  final String reference;
  final int userId;
  final int etat;
  final double? montantTotal;
  final double? totalFrais;
  final DateTime? datePaiement;
  final List<PaiementBon>? paiementBons;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Payment status constants
  static const int etatFailed = 0;
  static const int etatInitiated = 1;
  static const int etatSucceeded = 2;
  static const int etatPending = 3;

  Payment({
    required this.id,
    required this.slug,
    required this.reference,
    required this.userId,
    required this.etat,
    this.montantTotal,
    this.totalFrais,
    this.datePaiement,
    this.paiementBons,
    this.createdAt,
    this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? 0,
      slug: json['slug'] ?? '',
      reference: json['reference'] ?? '',
      userId: json['id_user'] ?? json['user_id'] ?? 0,
      etat: json['etat'] ?? 0,
      montantTotal: (json['montant_total'] ?? 0).toDouble(),
      totalFrais: (json['total_frais'] ?? 0).toDouble(),
      datePaiement: json['date_paiement'] != null
          ? DateTime.parse(json['date_paiement'])
          : null,
      paiementBons: json['paiement_bons'] != null
          ? (json['paiement_bons'] as List)
              .map((pb) => PaiementBon.fromJson(pb))
              .toList()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'reference': reference,
      'id_user': userId,
      'etat': etat,
      'montant_total': montantTotal,
      'total_frais': totalFrais,
      'date_paiement': datePaiement?.toIso8601String(),
      'paiement_bons': paiementBons?.map((pb) => pb.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper methods
  String get etatLabel {
    switch (etat) {
      case etatFailed:
        return 'Échec';
      case etatInitiated:
        return 'Initié';
      case etatSucceeded:
        return 'Succès';
      case etatPending:
        return 'En attente';
      default:
        return 'Inconnu';
    }
  }

  bool get isSuccess => etat == etatSucceeded && datePaiement != null;
  bool get isPending => etat == etatInitiated || etat == etatPending;
  bool get isFailed => etat == etatFailed;

  // Calculate subtotal (without fees)
  double get subtotal => (montantTotal ?? 0) - (totalFrais ?? 0);

  // Get total voucher count
  int get voucherCount => paiementBons?.length ?? 0;

  // Format reference for display
  String get displayReference => '#$reference';

  // Get payment date formatted
  String get formattedDate {
    if (datePaiement == null) return '';
    final date = datePaiement!;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Get payment time formatted
  String get formattedTime {
    if (datePaiement == null) return '';
    final date = datePaiement!;
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class VoucherPurchase {
  final int voucherId;
  final int quantity;

  VoucherPurchase({
    required this.voucherId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_bon_achat': voucherId,
      'quantite': quantity,
    };
  }

  factory VoucherPurchase.fromJson(Map<String, dynamic> json) {
    return VoucherPurchase(
      voucherId: json['id_bon_achat'] ?? json['voucher_id'] ?? 0,
      quantity: json['quantite'] ?? json['quantity'] ?? 0,
    );
  }
}

class PaymentResponse {
  final bool success;
  final Payment? payment;
  final String message;
  final Map<String, dynamic>? errors;

  PaymentResponse({
    required this.success,
    this.payment,
    required this.message,
    this.errors,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] ?? false,
      payment: json['data'] != null ? Payment.fromJson(json['data']) : null,
      message: json['message'] ?? '',
      errors: json['errors'],
    );
  }
}
