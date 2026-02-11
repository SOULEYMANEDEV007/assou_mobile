// To parse this JSON data, do:
// final mesBonModel = mesBonModelFromJson(jsonString);

import 'dart:convert';

MesBonModel mesBonModelFromJson(String str) =>
    MesBonModel.fromJson(json.decode(str));

String mesBonModelToJson(MesBonModel data) => json.encode(data.toJson());

class MesBonModel {
  bool success;
  String message;
  Data data;
  DateTime timestamp;

  MesBonModel({
    required this.success,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  factory MesBonModel.fromJson(Map<String, dynamic> json) => MesBonModel(
        success: json["success"],
        message: json["message"],
        data: Data.fromJson(json["data"]),
        timestamp: DateTime.parse(json["timestamp"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data.toJson(),
        "timestamp": timestamp.toIso8601String(),
      };
}

class Data {
  int currentPage;
  List<Datum> data;
  String firstPageUrl;
  int from;
  int lastPage;
  String lastPageUrl;
  List<Link> links;
  dynamic nextPageUrl;
  String path;
  int perPage;
  dynamic prevPageUrl;
  int to;
  int total;

  Data({
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

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        currentPage: json["current_page"],
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
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

class Datum {
  int id;
  int idBonAchat;
  int idBoutique;
  int quantite;
  int prixDuBon;
  DateTime createdAt;
  DateTime updatedAt;
  dynamic deletedAt;
  int idPaiement;
  int userId;
  dynamic userEnv;
  dynamic dateExpire;
  dynamic dateUsage;
  dynamic dateEnvoie;
  Bon bon;
  dynamic partenaire;

  Datum({
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
    required this.partenaire,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        id: json["id"],
        idBonAchat: json["id_bon_achat"],
        idBoutique: json["id_boutique"],
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
        partenaire: json["partenaire"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "id_bon_achat": idBonAchat,
        "id_boutique": idBoutique,
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
        "partenaire": partenaire,
      };
}

class Bon {
  int id;
  String slug;
  String libelle;
  int montantBons;
  int idBoutique;
  int idadmin;
  String path;
  int status;
  int fraisFixe;
  String fraisEnPourcentage;
  DateTime dateDebut;
  DateTime dateFin;
  DateTime createdAt;
  DateTime updatedAt;
  dynamic deletedAt;
  Boutique boutique;

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
        montantBons: json["montant_bons"],
        idBoutique: json["id_boutique"],
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
        "montant_bons": montantBons,
        "id_boutique": idBoutique,
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
  int id;
  String slug;
  String name;
  String codeBoutique;
  String numeroWave;
  String numeroOm;
  String numeroMtn;
  String numeroMoov;
  String description;
  String contatct;
  int idTypeBoutique;
  DateTime createdAt;
  DateTime updatedAt;
  String adresse;
  dynamic slugAdmin;
  String email;
  dynamic deletedAt;

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

class Link {
  String? url;
  String label;
  bool active;

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
