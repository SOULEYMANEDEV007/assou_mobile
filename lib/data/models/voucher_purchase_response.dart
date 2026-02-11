import 'package:flutter/material.dart';

class VoucherPurchaseResponse {
  final VoucherPayment paiement;
  final String? waveLaunchUrl;
  final DebugInfo? debugInfo;

  VoucherPurchaseResponse({
    required this.paiement,
    this.waveLaunchUrl,
    this.debugInfo,
  });

  factory VoucherPurchaseResponse.fromJson(Map<String, dynamic> json) {
    return VoucherPurchaseResponse(
      paiement: json['paiement'] != null
          ? VoucherPayment.fromJson(json['paiement'] as Map<String, dynamic>)
          : throw Exception("paiement field is missing or null"),
      waveLaunchUrl: json['wave_launch_url'] ??
          (json['paiement']?['wave_launch_url'] as String?),
      debugInfo: json['debug_info'] != null
          ? DebugInfo.fromJson(json['debug_info'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() {
    return 'VoucherPurchaseResponse{paiement: ${paiement.reference}, waveLaunchUrl: $waveLaunchUrl, debugInfo: $debugInfo}';
  }
}

class Data {
  final bool isSuccessful;
  final bool isProcessing;

  Data({this.isSuccessful = false, this.isProcessing = false});

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      isSuccessful: json['is_successful'] == true ||
          json['isSuccessful'] == true ||
          json['is_successful'] == "succeeded", // Support legacy if needed
      isProcessing: json['is_processing'] == true,
    );
  }
}

class VoucherPayment {
  final int id;
  final String slug;
  final int idUser;
  final String reference;
  final double montantPaiement;
  final int quantite;
  final double fraisPaiement;
  final int etat;
  final String? waveCheckoutId;
  final String? waveLaunchUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<VoucherPaiementBon>? paiementBons;
  final bool? success;
  final Data? data;
  final DateTime? datePaiement;
  final int? idBonAchat;
  final int? idBoutique;

  // Payment status constants
  static const int ETAT_INITIATED = 0; // Changed from 1
  static const int ETAT_SUCCEEDED = 2;
  static const int ETAT_PENDING = 3;
  static const int ETAT_FAILED = 4; // Changed from 0

  VoucherPayment({
    required this.id,
    required this.slug,
    required this.idUser,
    required this.reference,
    required this.montantPaiement,
    required this.quantite,
    required this.fraisPaiement,
    required this.etat,
    this.waveCheckoutId,
    this.waveLaunchUrl,
    required this.createdAt,
    required this.updatedAt,
    this.paiementBons,
    this.success,
    this.data,
    this.datePaiement,
    this.idBonAchat,
    this.idBoutique,
  });

  // Status helper methods
  bool get isFailed => etat == ETAT_FAILED;

  bool get isInitiated => etat == ETAT_INITIATED;

  bool get isPending => etat == ETAT_PENDING;

  bool get isProcessing => data?.isProcessing ?? false;

  bool get isSuccessful => data?.isSuccessful ?? false;

  bool get isSucceeded {
    return (etat == ETAT_SUCCEEDED && datePaiement != null) || isSuccessful;
  }

  String get statusText {
    switch (etat) {
      case ETAT_FAILED:
        return 'Échec';
      case ETAT_INITIATED:
        return 'Initié';
      case ETAT_PENDING:
        return 'En attente';
      case ETAT_SUCCEEDED:
        return 'Réussi';
      default:
        return 'Inconnu';
    }
  }

  Color get statusColor {
    switch (etat) {
      case ETAT_FAILED:
        return Colors.red;
      case ETAT_INITIATED:
        return Colors.orange;
      case ETAT_PENDING:
        return Colors.blue;
      case ETAT_SUCCEEDED:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  factory VoucherPayment.fromJson(Map<String, dynamic> json) {
    return VoucherPayment(
      id: json['id'] ?? 0,
      slug: json['slug'] ?? '',
      idUser: json['id_user'] ?? 0,
      reference: json['reference'] ?? json['slug'] ?? '',
      // Use slug as fallback for reference
      montantPaiement: _parseDouble(json['montant_paiement']),
      quantite: json['quantite'] ?? 0,
      fraisPaiement: _parseDouble(json['frais_paiement']),
      etat: json['etat'] ?? 0,
      waveCheckoutId: json['wave_checkout_id'],
      waveLaunchUrl: json['wave_launch_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      paiementBons: json['paiement_bons'] != null
          ? (json['paiement_bons'] as List)
              .map((bon) => VoucherPaiementBon.fromJson(bon))
              .toList()
          : null,
      success: json['success'] ?? false,
      data: json['data'] != null ? Data.fromJson(json['data']) : null,
      datePaiement: json['date_paiement'] != null
          ? DateTime.parse(json['date_paiement'])
          : null,
      idBonAchat: json['id_bon_achat'],
      idBoutique: json['id_boutique'],
    );
  }

  // Helper method to safely parse double values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}

class VoucherPaiementBon {
  final int id;
  final int idPaiement;
  final int idBonAchat;
  final int quantite;
  final DateTime createdAt;
  final DateTime updatedAt;

  VoucherPaiementBon({
    required this.id,
    required this.idPaiement,
    required this.idBonAchat,
    required this.quantite,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VoucherPaiementBon.fromJson(Map<String, dynamic> json) {
    return VoucherPaiementBon(
      id: json['id'] ?? 0,
      idPaiement: json['id_paiement'] ?? 0,
      idBonAchat: json['id_bon_achat'] ?? 0,
      quantite: json['quantite'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class DebugInfo {
  final int processedItems;
  final double totalAmount;
  final String waveId;

  DebugInfo({
    required this.processedItems,
    required this.totalAmount,
    required this.waveId,
  });

  factory DebugInfo.fromJson(Map<String, dynamic> json) {
    return DebugInfo(
      processedItems: json['processed_items'] ?? 0,
      totalAmount: VoucherPayment._parseDouble(json['total_amount']),
      waveId: json['wave_id'] ?? '',
    );
  }
}
