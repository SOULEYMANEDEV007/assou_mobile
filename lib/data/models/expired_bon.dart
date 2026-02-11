class ExpiredBon {
  final int id;
  final String slug;
  final double montant;
  final int quantite;
  final DateTime? dateAchat;
  final DateTime? dateExpiration;
  final double? joursAvantExpiration;
  final int etat;
  final ExpiredBonBoutique? boutique;
  final ExpiredBonAchat? bonAchat;
  final ExpiredBonPaiement? paiement;

  ExpiredBon({
    required this.id,
    required this.slug,
    required this.montant,
    required this.quantite,
    this.dateAchat,
    this.dateExpiration,
    this.joursAvantExpiration,
    required this.etat,
    this.boutique,
    this.bonAchat,
    this.paiement,
  });

  factory ExpiredBon.fromJson(Map<String, dynamic> json) {
    return ExpiredBon(
      id: json['id'] ?? 0,
      slug: json['slug'] ?? '',
      montant: (json['montant'] ?? 0).toDouble(),
      quantite: json['quantite'] ?? 0,
      dateAchat: json['date_achat'] != null
          ? DateTime.tryParse(json['date_achat'])
          : null,
      dateExpiration: json['date_expiration'] != null
          ? DateTime.tryParse(json['date_expiration'])
          : null,
      joursAvantExpiration: json['jours_avant_expiration'] != null
          ? (json['jours_avant_expiration'] as num).toDouble()
          : null,
      etat: json['etat'] ?? 0,
      boutique: json['boutique'] != null
          ? ExpiredBonBoutique.fromJson(json['boutique'])
          : null,
      bonAchat: json['bon_achat'] != null
          ? ExpiredBonAchat.fromJson(json['bon_achat'])
          : null,
      paiement: json['paiement'] != null
          ? ExpiredBonPaiement.fromJson(json['paiement'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'montant': montant,
      'quantite': quantite,
      'date_achat': dateAchat?.toIso8601String(),
      'date_expiration': dateExpiration?.toIso8601String(),
      'jours_avant_expiration': joursAvantExpiration,
      'etat': etat,
      'boutique': boutique?.toJson(),
      'bon_achat': bonAchat?.toJson(),
      'paiement': paiement?.toJson(),
    };
  }
}

class ExpiredBonBoutique {
  final String slug;
  final String name;
  final String logo;

  ExpiredBonBoutique({
    required this.slug,
    required this.name,
    required this.logo,
  });

  factory ExpiredBonBoutique.fromJson(Map<String, dynamic> json) {
    return ExpiredBonBoutique(
      slug: json['slug'] ?? '',
      name: json['name'] ?? '',
      logo: json['logo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'name': name,
      'logo': logo,
    };
  }
}

class ExpiredBonAchat {
  final String slug;
  final String libelle;
  final String path;

  ExpiredBonAchat({
    required this.slug,
    required this.libelle,
    required this.path,
  });

  factory ExpiredBonAchat.fromJson(Map<String, dynamic> json) {
    return ExpiredBonAchat(
      slug: json['slug'] ?? '',
      libelle: json['libelle'] ?? '',
      path: json['path'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'libelle': libelle,
      'path': path,
    };
  }
}

class ExpiredBonPaiement {
  final int id;
  final String slug;
  final double montantPaiement;

  ExpiredBonPaiement({
    required this.id,
    required this.slug,
    required this.montantPaiement,
  });

  factory ExpiredBonPaiement.fromJson(Map<String, dynamic> json) {
    return ExpiredBonPaiement(
      id: json['id'] ?? 0,
      slug: json['slug'] ?? '',
      montantPaiement: double.tryParse(json['montant_paiement']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'montant_paiement': montantPaiement,
    };
  }
}
