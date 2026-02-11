// bon_recu_model.dart
import 'package:flutter/material.dart';
import 'dart:convert';

class BonRecuModel {
  final bool success;
  final String message;
  final BonRecuData data;
  final DateTime timestamp;

  BonRecuModel({
    required this.success,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  factory BonRecuModel.fromJson(Map<String, dynamic> json) => BonRecuModel(
        success: json["success"],
        message: json["message"],
        data: BonRecuData.fromJson(json["data"]),
        timestamp: DateTime.parse(json["timestamp"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data.toJson(),
        "timestamp": timestamp.toIso8601String(),
      };

  // Méthode pour parser depuis une string JSON
  factory BonRecuModel.fromRawJson(String str) =>
      BonRecuModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());
}

class BonRecuData {
  final int currentPage;
  final List<BonRecu> data;
  final String firstPageUrl;
  final int from;
  final int lastPage;
  final String lastPageUrl;
  final List<Link> links;
  final dynamic nextPageUrl;
  final String path;
  final int perPage;
  final dynamic prevPageUrl;
  final int to;
  final int total;

  BonRecuData({
    required this.currentPage,
    required this.data,
    required this.firstPageUrl,
    required this.from,
    required this.lastPage,
    required this.lastPageUrl,
    required this.links,
    required this.nextPageUrl,
    required this.path,
    required this.perPage,
    required this.prevPageUrl,
    required this.to,
    required this.total,
  });

  factory BonRecuData.fromJson(Map<String, dynamic> json) => BonRecuData(
        currentPage: json["current_page"],
        data: List<BonRecu>.from(json["data"].map((x) => BonRecu.fromJson(x))),
        firstPageUrl: json["first_page_url"],
        from: json["from"],
        lastPage: json["last_page"],
        lastPageUrl: json["last_page_url"],
        links: List<Link>.from(json["links"].map((x) => Link.fromJson(x))),
        nextPageUrl: json["next_page_url"],
        path: json["path"],
        perPage: json["per_page"],
        prevPageUrl: json["prev_page_url"],
        to: json["to"],
        total: json["total"],
      );

  Map<String, dynamic> toJson() => {
        "current_page": currentPage,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
        "first_page_url": firstPageUrl,
        "from": from,
        "last_page": lastPage,
        "last_page_url": lastPageUrl,
        "links": List<dynamic>.from(links.map((x) => x.toJson())),
        "next_page_url": nextPageUrl,
        "path": path,
        "per_page": perPage,
        "prev_page_url": prevPageUrl,
        "to": to,
        "total": total,
      };
}

class BonRecu {
  final int id;
  final int idBonAchat;
  final int idBoutique;
  final int quantite;
  final int prixDuBon;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic deletedAt;
  final int idPaiement;
  final int userId;
  final int userEnv;
  final dynamic dateExpire;
  final dynamic dateUsage;
  final dynamic dateEnvoie;
  final Bon bon;
  final Donateur donateur;

  BonRecu({
    required this.id,
    required this.idBonAchat,
    required this.idBoutique,
    required this.quantite,
    required this.prixDuBon,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.idPaiement,
    required this.userId,
    required this.userEnv,
    required this.dateExpire,
    required this.dateUsage,
    required this.dateEnvoie,
    required this.bon,
    required this.donateur,
  });

  factory BonRecu.fromJson(Map<String, dynamic> json) => BonRecu(
        id: json["id"],
        idBonAchat: json["id_bon_achat"],
        idBoutique: json["slug"],
        quantite: json["quantite"],
        prixDuBon: json["prix_du_bon"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        deletedAt: json["deleted_at"],
        idPaiement: json["id_paiement"],
        userId: json["user_id"],
        userEnv: json["user_env"],
        dateExpire: json["date_expire"],
        dateUsage: json["date_usage"],
        dateEnvoie: json["date_envoie"],
        bon: Bon.fromJson(json["bon"]),
        donateur: Donateur.fromJson(json["donateur"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "id_bon_achat": idBonAchat,
        "slug": idBoutique,
        "quantite": quantite,
        "prix_du_bon": prixDuBon,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
        "id_paiement": idPaiement,
        "user_id": userId,
        "user_env": userEnv,
        "date_expire": dateExpire,
        "date_usage": dateUsage,
        "date_envoie": dateEnvoie,
        "bon": bon.toJson(),
        "donateur": donateur.toJson(),
      };

  // Méthode pour convertir en format d'affichage
  Map<String, dynamic> toDisplayFormat() {
    final dateExpire = this.dateExpire ?? bon.dateFin;
    final joursRestants = dateExpire?.difference(DateTime.now()).inDays ?? 0;

    Color expirationColor;
    if (joursRestants <= 5) {
      expirationColor = Colors.red;
    } else if (joursRestants <= 12) {
      expirationColor = Colors.orange;
    } else {
      expirationColor = Colors.green;
    }

    final dateFormatted = dateExpire != null
        ? "${dateExpire.day.toString().padLeft(2, '0')}/${dateExpire.month.toString().padLeft(2, '0')}/${dateExpire.year}"
        : "Non spécifiée";

    return {
      'montant_bon': "${bon.montantBons} FCFA",
      'boutique_name': bon.boutique.name,
      'delai_expiration':
          joursRestants > 0 ? "Expire dans $joursRestants jours" : "Expiré",
      'date_expiration': dateFormatted,
      'expiration_color': expirationColor,
      'bon_id': id,
      'boutique_id': idBoutique,
      'image_path': bon.path,
      'donateur': '${donateur.firstName} ${donateur.lastName}',
    };
  }
}

class Bon {
  final int id;
  final String slug;
  final String libelle;
  final int montantBons;
  final int idBoutique;
  final int idadmin;
  final String path;
  final int status;
  final int fraisFixe;
  final String fraisEnPourcentage;
  final DateTime dateDebut;
  final DateTime dateFin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic deletedAt;
  final Boutique boutique;

  Bon({
    required this.id,
    required this.slug,
    required this.libelle,
    required this.montantBons,
    required this.idBoutique,
    required this.idadmin,
    required this.path,
    required this.status,
    required this.fraisFixe,
    required this.fraisEnPourcentage,
    required this.dateDebut,
    required this.dateFin,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.boutique,
  });

  factory Bon.fromJson(Map<String, dynamic> json) => Bon(
        id: json["id"],
        slug: json["slug"],
        libelle: json["libelle"],
        montantBons: json["montant_bon"],
        idBoutique: json["slug"],
        idadmin: json["idadmin"],
        path: json["path"],
        status: json["status"],
        fraisFixe: json["frais_fixe"],
        fraisEnPourcentage: json["frais_en_pourcentage"],
        dateDebut: DateTime.parse(json["date_debut"]),
        dateFin: DateTime.parse(json["date_fin"]),
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        deletedAt: json["deleted_at"],
        boutique: Boutique.fromJson(json["boutique"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "slug": slug,
        "libelle": libelle,
        "montant_bon": montantBons,
        "slug": idBoutique,
        "idadmin": idadmin,
        "path": path,
        "status": status,
        "frais_fixe": fraisFixe,
        "frais_en_pourcentage": fraisEnPourcentage,
        "date_debut": dateDebut.toIso8601String(),
        "date_fin": dateFin.toIso8601String(),
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
        "boutique": boutique.toJson(),
      };
}

class Boutique {
  final int id;
  final String slug;
  final String name;
  final String codeBoutique;
  final String numeroWave;
  final String numeroOm;
  final String numeroMtn;
  final String numeroMoov;
  final String description;
  final String contatct;
  final int idTypeBoutique;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String adresse;
  final dynamic slugAdmin;
  final String email;
  final dynamic deletedAt;

  Boutique({
    required this.id,
    required this.slug,
    required this.name,
    required this.codeBoutique,
    required this.numeroWave,
    required this.numeroOm,
    required this.numeroMtn,
    required this.numeroMoov,
    required this.description,
    required this.contatct,
    required this.idTypeBoutique,
    required this.createdAt,
    required this.updatedAt,
    required this.adresse,
    required this.slugAdmin,
    required this.email,
    required this.deletedAt,
  });

  factory Boutique.fromJson(Map<String, dynamic> json) => Boutique(
        id: json["id"],
        slug: json["slug"],
        name: json["name"],
        codeBoutique: json["code_boutique"],
        numeroWave: json["numero_wave"],
        numeroOm: json["numero_OM"],
        numeroMtn: json["numero_MTN"],
        numeroMoov: json["numero_MOOV"],
        description: json["description"],
        contatct: json["contatct"],
        idTypeBoutique: json["id_type_boutique"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        adresse: json["adresse"],
        slugAdmin: json["slug_admin"],
        email: json["email"],
        deletedAt: json["deleted_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "slug": slug,
        "name": name,
        "code_boutique": codeBoutique,
        "numero_wave": numeroWave,
        "numero_OM": numeroOm,
        "numero_MTN": numeroMtn,
        "numero_MOOV": numeroMoov,
        "description": description,
        "contatct": contatct,
        "id_type_boutique": idTypeBoutique,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "adresse": adresse,
        "slug_admin": slugAdmin,
        "email": email,
        "deleted_at": deletedAt,
      };
}

class Donateur {
  final int id;
  final String firstName;
  final String email;
  final dynamic emailVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String lastName;
  final String phoneNumber;
  final String slug;
  final dynamic deletedAt;

  Donateur({
    required this.id,
    required this.firstName,
    required this.email,
    required this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.lastName,
    required this.phoneNumber,
    required this.slug,
    required this.deletedAt,
  });

  factory Donateur.fromJson(Map<String, dynamic> json) => Donateur(
        id: json["id"],
        firstName: json["first_name"],
        email: json["email"],
        emailVerifiedAt: json["email_verified_at"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        lastName: json["last_name"],
        phoneNumber: json["phone_number"],
        slug: json["slug"],
        deletedAt: json["deleted_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "first_name": firstName,
        "email": email,
        "email_verified_at": emailVerifiedAt,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "last_name": lastName,
        "phone_number": phoneNumber,
        "slug": slug,
        "deleted_at": deletedAt,
      };
}

class Link {
  final String? url;
  final String label;
  final bool active;

  Link({
    required this.url,
    required this.label,
    required this.active,
  });

  factory Link.fromJson(Map<String, dynamic> json) => Link(
        url: json["url"],
        label: json["label"],
        active: json["active"],
      );

  Map<String, dynamic> toJson() => {
        "url": url,
        "label": label,
        "active": active,
      };
}
