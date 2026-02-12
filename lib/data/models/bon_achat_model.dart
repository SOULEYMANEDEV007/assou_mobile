import 'package:flutter/material.dart';
import '../../config/environment.dart';
import 'boutique_model.dart';
import 'user_model.dart';
import 'event_type_model.dart';

class Event {
  final int id;
  final String? image;
  final String? icone;
  final String? nom;

  Event({required this.id, this.image, this.icone, this.nom});

  String? get imageUrl => Environment.getImageUrl(image);

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? 0,
      image: json['image'],
      icone: json['icone'],
      nom: json['nom'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'icone': icone,
      'nom': nom,
    };
  }

  IconData get iconData {
    if (icone == null || icone!.isEmpty) return Icons.card_giftcard;
    final key = icone!.toLowerCase().trim();
    const iconMap = {
      'cake': Icons.cake,
      'building-office': Icons.location_city,
      'party': Icons.celebration,
      'star': Icons.star,
      'heart': Icons.favorite,
      'baby': Icons.child_friendly,
      'gift': Icons.card_giftcard,
      'academic-cap': Icons.school,
      'users': Icons.group,
      'home': Icons.home,
      'work': Icons.work,
      'business': Icons.business,
      'celebration': Icons.celebration,
    };
    return iconMap[key] ?? Icons.card_giftcard;
  }
}

class BonAchat {
  final int id;
  final String slug;
  final String libelle;
  final double montantBon;
  final int? boutiqueId; // Changed to nullable for universal vouchers
  final int status;
  final double fraisFixe;
  final double fraisEnPourcentage;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? imageUrl;
  final bool isUniversal; // Added universal flag
  final Boutique? boutique;

  // Status constants
  static const int statusInactive = 0;
  static const int statusActive = 1;
  static const int statusCreated = 2;
  static const int statusUsed = 3;
  static const int statusExpired = 4;
  static const int statusSent = 5;

  BonAchat({
    required this.id,
    required this.slug,
    required this.libelle,
    required this.montantBon,
    this.boutiqueId,
    required this.status,
    required this.fraisFixe,
    required this.fraisEnPourcentage,
    this.dateDebut,
    this.dateFin,
    this.imageUrl,
    this.isUniversal = false,
    this.boutique,
  });

  factory BonAchat.fromJson(Map<String, dynamic> json) {
    return BonAchat(
      id: json['id'] ?? 0,
      slug: json['slug'] ?? '',
      libelle: json['libelle'] ?? '',
      montantBon: (json['montant_bon'] ?? 0).toDouble(),
      boutiqueId: json['id_boutique'] ?? json['boutique_id'], // Can be null
      status: json['status'] ?? 0,
      fraisFixe: (json['frais_fixe'] ?? 0).toDouble(),
      fraisEnPourcentage:
          double.tryParse(json['frais_en_pourcentage']?.toString() ?? '0') ??
              0.0,
      dateDebut: json['date_debut'] != null
          ? DateTime.parse(json['date_debut'])
          : null,
      dateFin:
          json['date_fin'] != null ? DateTime.parse(json['date_fin']) : null,
      imageUrl: json['image_url'],
      isUniversal: json['is_universal'] ?? false,
      boutique:
          json['boutique'] != null ? Boutique.fromJson(json['boutique']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'libelle': libelle,
      'montant_bon': montantBon,
      'id_boutique': boutiqueId,
      'status': status,
      'frais_fixe': fraisFixe,
      'frais_en_pourcentage': fraisEnPourcentage,
      'date_debut': dateDebut?.toIso8601String(),
      'date_fin': dateFin?.toIso8601String(),
      'image_url': imageUrl,
      'is_universal': isUniversal,
      'boutique': boutique?.toJson(),
    };
  }

  String? get fullImageUrl => Environment.getImageUrl(imageUrl);

  String? get boutiqueLogoUrl =>
      boutique?.logoUrl ?? Environment.getImageUrl(boutique?.logo);

  // Helper methods
  String get statusLabel {
    switch (status) {
      case statusInactive:
        return 'Inactif';
      case statusActive:
        return 'Actif';
      case statusCreated:
        return 'Créé';
      case statusUsed:
        return 'Utilisé';
      case statusSent:
        return 'Envoyé';
      case statusExpired:
        return 'Expiré';
      default:
        return 'Inconnu';
    }
  }

  bool get isAvailable => status == statusActive && !isExpired;
  bool get isExpired => dateFin != null && dateFin!.isBefore(DateTime.now());
  bool get isActive => status == statusActive;
  bool get isUsed => status == statusUsed;
  bool get isSent => status == statusSent;

  // Calculate total cost including fees
  double calculateTotalCost(int quantity) {
    final baseAmount = montantBon * quantity;
    final fixedFees = fraisFixe * quantity;
    final percentageFees = (baseAmount * fraisEnPourcentage) / 100;
    return baseAmount + fixedFees + percentageFees;
  }

  // Calculate fees only
  double calculateFees(int quantity) {
    final baseAmount = montantBon * quantity;
    final fixedFees = fraisFixe * quantity;
    final percentageFees = (baseAmount * fraisEnPourcentage) / 100;
    return fixedFees + percentageFees;
  }
}

class PaiementBon {
  final int id;
  final String slug;
  final String codeBon;
  final double montantBon;
  final String? personal_message;
  final String? recipientPhone;
  final int etat;
  final int? etatReceiver; // NEW: Status for receiver of voucher
  final int? senderId; // NEW: ID of the sender
  final int? receiverId; // NEW: ID of the receiver
  final int? userId; // NEW: ID of the current user (sender or receiver)
  final DateTime? dateExpire;
  final DateTime? dateUsage;
  final BonAchat? bon;
  final Boutique? boutique;
  final Event? event;
  final User? donateur;
  final User? partenaire;
  final User? receiver;
  final String? qrCode;
  final DateTime? dateAchat;
  final DateTime? dateExpiration;
  final double? joursAvantExpiration; // For expiring vouchers
  final double? joursDepuisExpiration; // For expired vouchers
  final bool isUniversal;
  final String? destinataireName;
  final bool has_thanked;

  // Updated PaiementBon status constants - NEW 4-STATUS SYSTEM
  static const int ETAT_ACTIVE = 1; // Voucher is active and ready to use
  static const int ETAT_UTILISE = 2; // Voucher has been used/redeemed
  static const int ETAT_EXPIRE = 3; // Voucher has expired
  static const int ETAT_SENT = 4; // Voucher has been sent to another user

  // REMOVED CONSTANTS - No longer used in backend:
  // static const int etatFailed = 0;     ❌ REMOVED
  // static const int etatInitiated = 1;  ❌ REMOVED
  // static const int etatIssued = 2;     ❌ REMOVED

  PaiementBon(
      {required this.id,
      required this.slug,
      required this.codeBon,
      required this.montantBon,
      required this.etat,
      this.recipientPhone,
      this.etatReceiver,
      this.senderId,
      this.receiverId,
      this.userId,
      this.dateAchat,
      this.dateExpiration,
      this.joursAvantExpiration,
      this.joursDepuisExpiration,
      this.dateExpire,
      this.dateUsage,
      this.bon,
      this.event,
      this.boutique,
      this.donateur,
      this.partenaire,
      this.receiver,
      this.qrCode,
      this.personal_message,
      this.isUniversal = false,
      this.destinataireName,
      this.has_thanked = false});

  factory PaiementBon.fromJson(Map<String, dynamic> json) {
    return PaiementBon(
      id: json['id'] ?? 0,
      slug: json['slug'] ?? '',
      personal_message: json['personal_message'],
      recipientPhone: json['recipient_phone'] ?? '',
      codeBon: json['code_bon'] ?? json['slug'] ?? '',
      montantBon: (json['montant_bon'] ?? 0).toDouble(),
      etat: json['etat'] ?? 0,
      etatReceiver: json['etat_receiver'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      userId: json['user_id'],
      dateExpire: json['date_expire'] != null
          ? DateTime.parse(json['date_expire'])
          : null,
      dateUsage: json['date_usage'] != null
          ? DateTime.parse(json['date_usage'])
          : null,
      // Handle both 'bon' and 'bon_achat' field names
      // Handle both 'event' and 'event_type' fields
      event: json['event'] != null
          ? Event.fromJson(json['event'])
          : json['event_type'] != null
              ? Event.fromJson(json['event_type'])
              : null,
      bon: json['bon'] != null
          ? BonAchat.fromJson(json['bon'])
          : json['bon_achat'] != null
              ? BonAchat.fromJson(json['bon_achat'])
              : null,

      boutique: json['boutique'] != null
          ? Boutique.fromJson(json['boutique'])
          : (json['bon'] != null && json['bon']['boutique'] != null)
              ? Boutique.fromJson(json['bon']['boutique'])
              : (json['bon_achat'] != null &&
                      json['bon_achat']['boutique'] != null)
                  ? Boutique.fromJson(json['bon_achat']['boutique'])
                  // Fallback: If there's an id_boutique and a logo_boutique, create a partial boutique
                  : (json['id_boutique'] != null ||
                          json['logo_boutique'] != null ||
                          json['boutique_nom'] != null)
                      ? Boutique(
                          id: json['id_boutique'] ?? 0,
                          name: json['nom_boutique'] ??
                              json['boutique_nom'] ??
                              json['boutique_name'] ??
                              '',
                          slug: json['slug_boutique'] ??
                              json['boutique_slug'] ??
                              '',
                          logo: json['logo_boutique'] ??
                              json['boutique_logo'] ??
                              json['logo'] ??
                              '',
                        )
                      : null,
      donateur:
          json['donateur'] != null ? User.fromJson(json['donateur']) : null,
      receiver:
          json['receiver'] != null ? User.fromJson(json['receiver']) : null,
      partenaire:
          json['partenaire'] != null ? User.fromJson(json['partenaire']) : null,
      qrCode: json['qr_code'],
      dateAchat: json['date_achat'] != null
          ? DateTime.tryParse(json['date_achat'])
          : null,
      dateExpiration: json['date_expiration'] != null
          ? DateTime.tryParse(json['date_expiration'])
          : null,
      joursAvantExpiration: json['jours_avant_expiration']?.toDouble(),
      joursDepuisExpiration: json['jours_depuis_expiration']?.toDouble(),
      isUniversal: json['is_universal'] ?? false,
      destinataireName: json['destinataire_name'],
      has_thanked: json['has_thanked'] == true || json['has_thanked'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'code_bon': codeBon,
      'personal_message': personal_message,
      'montant_bon': montantBon,
      'etat': etat,
      'recipient_phone': recipientPhone,
      'etat_receiver': etatReceiver,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'user_id': userId,
      'date_expire': dateExpire?.toIso8601String(),
      'date_usage': dateUsage?.toIso8601String(),
      'bon': bon?.toJson(),
      'event': event?.toJson(),
      'boutique': boutique?.toJson(),
      'donateur': donateur?.toJson(),
      'partenaire': partenaire?.toJson(),
      'qr_code': qrCode,
      'date_achat': dateAchat?.toIso8601String(),
      'date_expiration': dateExpiration?.toIso8601String(),
      'jours_avant_expiration': joursAvantExpiration,
      'jours_depuis_expiration': joursDepuisExpiration,
      'has_thanked': has_thanked,
    };
  }

  // Updated helper methods for new 4-status system
  String get etatLabel {
    switch (etat) {
      case ETAT_ACTIVE:
        return 'Actif';
      case ETAT_UTILISE:
        return 'Utilisé';
      case ETAT_EXPIRE:
        return 'Expiré';
      case ETAT_SENT:
        return 'Envoyé';
      default:
        return 'Inconnu';
    }
  }

  // Helper methods to get the effective status based on current user
  int getEffectiveEtat(int? currentUserId) {
    if (currentUserId != null &&
        receiverId == currentUserId &&
        etatReceiver != null) {
      // User is the receiver, use etat_receiver
      return etatReceiver!;
    }
    // User is sender or no receiver info, use normal etat
    return etat;
  }

  String getEffectiveEtatLabel(int? currentUserId) {
    final effectiveEtat = getEffectiveEtat(currentUserId);
    switch (effectiveEtat) {
      case ETAT_ACTIVE:
        return 'Actif';
      case ETAT_UTILISE:
        return 'Utilisé';
      case ETAT_EXPIRE:
        return 'Expiré';
      case ETAT_SENT:
        return 'Envoyé';
      default:
        return 'Inconnu';
    }
  }

  // Updated status helper methods
  bool get isActive => etat == ETAT_ACTIVE;
  bool get isUtilise => etat == ETAT_UTILISE;
  bool get isExpired =>
      etat == ETAT_EXPIRE ||
      (dateExpire != null && dateExpire!.isBefore(DateTime.now()));
  bool get isSent => etat == ETAT_SENT;
  bool get isUsed => etat == ETAT_UTILISE; // Backward compatibility

  // Helper methods with receiver awareness
  bool isActiveForUser(int? currentUserId) {
    return getEffectiveEtat(currentUserId) == ETAT_ACTIVE;
  }

  bool isUtiliseForUser(int? currentUserId) {
    return getEffectiveEtat(currentUserId) == ETAT_UTILISE;
  }

  bool isSentForUser(int? currentUserId) {
    return getEffectiveEtat(currentUserId) == ETAT_SENT;
  }

  // Updated business logic methods
  bool get isUsable => etat == ETAT_ACTIVE && !isExpired;
  bool get canBeSent => etat == ETAT_ACTIVE && !isExpired;

  // Get days until expiration
  int? get daysUntilExpiration {
    if (dateExpire == null) return null;
    final now = DateTime.now();
    if (dateExpire!.isBefore(now)) return 0;
    return dateExpire!.difference(now).inDays;
  }

  // Get expiration status for UI
  String get expirationStatus {
    final days = daysUntilExpiration;
    if (days == null) return '';
    if (days == 0) return 'Expiré';
    if (days == 1) return 'Expire dans 1 jour';
    if (days <= 7) return 'Expire dans $days jours';
    return 'Expire le ${_formatDate(dateExpire!)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Enhanced UI methods for new status system
  Color get statusColor {
    switch (etat) {
      case ETAT_ACTIVE:
        return Colors.green; // Active vouchers - green
      case ETAT_UTILISE:
        return Colors.blue; // Used vouchers - blue
      case ETAT_EXPIRE:
        return Colors.orange; // Expired vouchers - orange
      case ETAT_SENT:
        return Colors.purple; // Sent vouchers - purple
      default:
        return Colors.grey; // Unknown status - grey
    }
  }

  IconData get statusIcon {
    switch (etat) {
      case ETAT_ACTIVE:
        return Icons.check_circle;
      case ETAT_UTILISE:
        return Icons.shopping_cart;
      case ETAT_EXPIRE:
        return Icons.schedule;
      case ETAT_SENT:
        return Icons.send;
      default:
        return Icons.help_outline;
    }
  }

  //bool? get has_thanked => null;
}

// Enhanced Voucher model for new integration with universal support and transfers
class Voucher {
  final int id;
  final String slug;
  final int? idBoutique;
  final int quantite;
  final int montantBon;
  final int? userId; // NEW: Added user_id field
  final int? senderId; // Sender of the voucher
  final int? receiverId; // Current owner of the voucher
  final int etat; // Status
  final DateTime? dateExpire;
  final DateTime? dateUsage;
  final DateTime? dateEnvoie;
  final int? idEventType; // NEW: Event type for voucher
  final bool isUniversal; // NEW: Universal voucher flag
  final BonAchat? bonAchat;
  final Boutique? boutique;
  final User? sender;
  final User? receiver;
  final EventType? eventType; // NEW: Event type relationship

  // Voucher status constants - UPDATED TO NEW 4-STATUS SYSTEM
  static const int ETAT_ACTIVE = 1; // Voucher is active and ready to use
  static const int ETAT_UTILISE = 2; // Voucher has been used/redeemed
  static const int ETAT_EXPIRE = 3; // Voucher has expired
  static const int ETAT_SENT = 4; // Voucher has been sent to another user

  Voucher({
    required this.id,
    required this.slug,
    this.idBoutique,
    required this.quantite,
    required this.montantBon,
    this.userId,
    this.senderId,
    this.receiverId,
    required this.etat,
    this.dateExpire,
    this.dateUsage,
    this.dateEnvoie,
    this.idEventType,
    required this.isUniversal,
    this.bonAchat,
    this.boutique,
    this.sender,
    this.receiver,
    this.eventType,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'],
      slug: json['slug'],
      idBoutique: json['id_boutique'],
      quantite: json['quantite'],
      montantBon: json['montant_bon'],
      userId: json['user_id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      etat: json['etat'],
      dateExpire: json['date_expire'] != null
          ? DateTime.parse(json['date_expire'])
          : null,
      dateUsage: json['date_usage'] != null
          ? DateTime.parse(json['date_usage'])
          : null,
      dateEnvoie: json['date_envoie'] != null
          ? DateTime.parse(json['date_envoie'])
          : null,
      idEventType: json['id_event_type'],
      isUniversal: json['is_universal'] ?? false,
      bonAchat: json['bon_achat'] != null
          ? BonAchat.fromJson(json['bon_achat'])
          : null,
      boutique:
          json['boutique'] != null ? Boutique.fromJson(json['boutique']) : null,
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      receiver:
          json['receiver'] != null ? User.fromJson(json['receiver']) : null,
      eventType: json['event_type'] != null
          ? EventType.fromJson(json['event_type'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'id_boutique': idBoutique,
      'quantite': quantite,
      'montant_bon': montantBon,
      'user_id': userId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'etat': etat,
      'date_expire': dateExpire?.toIso8601String(),
      'date_usage': dateUsage?.toIso8601String(),
      'date_envoie': dateEnvoie?.toIso8601String(),
      'id_event_type': idEventType,
      'is_universal': isUniversal,
      'bon_achat': bonAchat?.toJson(),
      'boutique': boutique?.toJson(),
      'sender': sender?.toJson(),
      'receiver': receiver?.toJson(),
      'event_type': eventType?.toJson(),
    };
  }

  // Status helper methods
  bool get isActive => etat == ETAT_ACTIVE;
  bool get isUtilise => etat == ETAT_UTILISE;
  bool get isExpired =>
      etat == ETAT_EXPIRE ||
      (dateExpire != null && dateExpire!.isBefore(DateTime.now()));
  bool get isSent => etat == ETAT_SENT;

  String get statusText {
    switch (etat) {
      case ETAT_ACTIVE:
        return 'Actif';
      case ETAT_UTILISE:
        return 'Utilisé';
      case ETAT_EXPIRE:
        return 'Expiré';
      case ETAT_SENT:
        return 'Envoyé';
      default:
        return 'Inconnu';
    }
  }

  Color get statusColor {
    switch (etat) {
      case ETAT_ACTIVE:
        return Colors.green; // Active vouchers - green
      case ETAT_UTILISE:
        return Colors.blue; // Used vouchers - blue
      case ETAT_EXPIRE:
        return Colors.orange; // Expired vouchers - orange
      case ETAT_SENT:
        return Colors.purple; // Sent vouchers - purple
      default:
        return Colors.grey; // Unknown status - grey
    }
  }

  IconData get statusIcon {
    switch (etat) {
      case ETAT_ACTIVE:
        return Icons.check_circle;
      case ETAT_UTILISE:
        return Icons.shopping_cart;
      case ETAT_EXPIRE:
        return Icons.schedule;
      case ETAT_SENT:
        return Icons.send;
      default:
        return Icons.help_outline;
    }
  }

  // Transfer and business logic helpers
  bool get canBeTransferred =>
      etat == ETAT_ACTIVE && !isExpired && receiverId == null;

  // Get days until expiration
  int? get daysUntilExpiration {
    if (dateExpire == null) return null;
    final now = DateTime.now();
    if (dateExpire!.isBefore(now)) return 0;
    return dateExpire!.difference(now).inDays;
  }
}
