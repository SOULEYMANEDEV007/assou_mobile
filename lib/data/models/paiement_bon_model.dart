// lib/data/models/paiement_bon_model.dart
import '../models/bon_achat_model.dart';
import '../models/user_model.dart';

class PaiementBon {
  final int id;
  final String codeBon;
  final double montantBon;
  final int etat;
  final DateTime? dateExpire;
  final DateTime? dateUsage;
  final BonAchat? bon;
  final User? donateur;
  final User? partenaire;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool has_thanked;

  // PaiementBon status constants
  static const int etatFailed = 0;
  static const int etatInitiated = 1;
  static const int etatIssued = 2; // Émis
  static const int etatUsed = 3; // Utilisé

  PaiementBon({
    required this.id,
    required this.codeBon,
    required this.montantBon,
    required this.etat,
    this.dateExpire,
    this.dateUsage,
    this.bon,
    this.donateur,
    this.partenaire,
    required this.createdAt,
    required this.updatedAt,
    this.has_thanked = false,
  });

  factory PaiementBon.fromJson(Map<String, dynamic> json) {
    return PaiementBon(
      id: json['id'] ?? 0,
      codeBon: json['code_bon'] ?? '',
      montantBon: (json['montant_bon'] ?? 0).toDouble(),
      etat: json['etat'] ?? etatFailed,
      dateExpire: json['date_expire'] != null
          ? DateTime.tryParse(json['date_expire'])
          : null,
      dateUsage: json['date_usage'] != null
          ? DateTime.tryParse(json['date_usage'])
          : null,
      bon: json['bon'] != null ? BonAchat.fromJson(json['bon']) : null,
      donateur:
          json['donateur'] != null ? User.fromJson(json['donateur']) : null,
      partenaire:
          json['partenaire'] != null ? User.fromJson(json['partenaire']) : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      has_thanked: json['has_thanked'] == true || json['has_thanked'] == 1,
    );
  }

  String get etatLabel {
    switch (etat) {
      case etatFailed:
        return 'Échec';
      case etatInitiated:
        return 'Initié';
      case etatIssued:
        return 'Émis';
      case etatUsed:
        return 'Utilisé';
      default:
        return 'Inconnu';
    }
  }

  bool get isUsable => etat == etatIssued && !isExpired;
  bool get isExpired =>
      dateExpire != null && dateExpire!.isBefore(DateTime.now());
  bool get isUsed => etat == etatUsed;
}
