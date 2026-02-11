class VoucherPurchaseRequest {
  final List<VoucherItem> bons;
  final double? montant; // Optional - calculated automatically
  final String? waveNumber;

  VoucherPurchaseRequest({
    required this.bons,
    this.montant,
    this.waveNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'bons': bons.map((bon) => bon.toJson()).toList(),
      if (montant != null) 'montant': montant,
      if (waveNumber != null) 'wave_number': waveNumber,
    };
  }
}

class VoucherItem {
  final int idBonAchat;
  final int quantite;

  VoucherItem({
    required this.idBonAchat,
    required this.quantite,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_bon_achat': idBonAchat,
      'quantite': quantite,
    };
  }

  factory VoucherItem.fromJson(Map<String, dynamic> json) {
    return VoucherItem(
      idBonAchat: json['id_bon_achat'],
      quantite: json['quantite'],
    );
  }
}

class CustomVoucherPurchaseRequest {
  final String destinataire;
  final int? evenementId;
  final bool? notifierEnvoyeur;
  final String? messagePersonnalise;
  final double montantPersonnalise;
  final int? idBoutique;
  final String? destinataireName;
  final String moyenPaiement;
  final String? successUrl;
  final String? errorUrl;

  CustomVoucherPurchaseRequest({
    required this.destinataire,
    this.evenementId,
    required this.notifierEnvoyeur,
    this.messagePersonnalise,
    required this.montantPersonnalise,
    this.idBoutique,
    this.destinataireName,
    required this.moyenPaiement,
    this.successUrl,
    this.errorUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'destinataire': destinataire,
      'evenement_id': evenementId,
      'notifier_envoyeur': notifierEnvoyeur,
      'message_personnalise': messagePersonnalise,
      'montant_personnalise': montantPersonnalise,
      'boutique_id': idBoutique,
      'moyen_paiement': moyenPaiement,
      'destinataire_name': destinataireName,
      if (successUrl != null) 'success_url': successUrl,
      if (errorUrl != null) 'error_url': errorUrl,
    };
  }
}
