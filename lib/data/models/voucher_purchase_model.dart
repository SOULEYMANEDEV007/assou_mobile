// lib/data/models/voucher_purchase_model.dart
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
}
