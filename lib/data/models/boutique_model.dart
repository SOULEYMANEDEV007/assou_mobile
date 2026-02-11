import 'bon_achat_model.dart';
import '../../config/environment.dart';

class Boutique {
  final int id;
  final String slug;
  final String name;
  final String? description;
  final String? logo;
  final String? codeBoutique;
  final String? contact;
  final String? address;
  final String? email;
  final BoutiqueType? type;
  final int? availableVouchersCount;
  final List<BonAchat>? firstVouchers;
  final double? totalAmount;

  Boutique({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logo,
    this.codeBoutique,
    this.contact,
    this.address,
    this.email,
    this.type,
    this.availableVouchersCount,
    this.firstVouchers,
    this.totalAmount,
  });

  factory Boutique.fromJson(Map<String, dynamic> json) {
    return Boutique(
      id: json['id'] ?? 0,
      name: json['nom'] ?? json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      logo: json['logo'],
      codeBoutique: json['code_boutique'],
      contact: json['contact'],
      address: json['adresse'],
      email: json['email'],
      type: json['type_boutique'] != null
          ? BoutiqueType.fromJson(json['type_boutique'])
          : null,
      availableVouchersCount: json['nb_bons_disponibles'],
      firstVouchers: json['premiers_bons'] != null
          ? (json['premiers_bons'] as List)
              .map((v) => BonAchat.fromJson(v))
              .toList()
          : null,
      totalAmount: json['total_montant_bon']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': name,
      'description': description,
      'logo': logo,
      'code_boutique': codeBoutique,
      'contact': contact,
      'adresse': address,
      'email': email,
      'type_boutique': type?.toJson(),
      'nb_bons_disponibles': availableVouchersCount,
      'premiers_bons': firstVouchers?.map((v) => v.toJson()).toList(),
      'total_montant_bon': totalAmount,
    };
  }

  // Helper method to get logo URL
  String? get logoUrl {
    return Environment.getImageUrl(logo);
  }
}

class BoutiqueType {
  final int id;
  final String name;
  final String? description;
  final String? icon;

  BoutiqueType({
    required this.id,
    required this.name,
    this.description,
    this.icon,
  });

  factory BoutiqueType.fromJson(Map<String, dynamic> json) {
    return BoutiqueType(
      id: json['id'] ?? 0,
      name: json['nom'] ?? json['name'] ?? '',
      description: json['description'],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': name,
      'description': description,
      'icon': icon,
    };
  }
}
