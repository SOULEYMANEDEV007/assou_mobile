import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/bon_achat_model.dart';
import 'voucher_status_chip.dart';

class VoucherCard extends StatelessWidget {
  final PaiementBon voucher;
  final VoidCallback? onTap;
  final bool showTransferButton;
  final bool showUseButton;
  final VoidCallback? onTransfer;
  final VoidCallback? onUse;

  const VoucherCard({
    super.key,
    required this.voucher,
    this.onTap,
    this.showTransferButton = true,
    this.showUseButton = true,
    this.onTransfer,
    this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Boutique info
                  if (voucher.boutique != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        voucher.boutique!.name,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Bon Universel',
                        style: TextStyle(
                          color: Colors.purple,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  // Status chip
                  VoucherStatusChip(voucher: voucher),
                ],
              ),

              const SizedBox(height: 12),

              // Amount
              Text(
                '${NumberFormat('#,###', 'fr_FR').format(voucher.montantBon)} FCFA',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 8),

              // Voucher details
              if (voucher.bon != null) ...[
                Text(
                  voucher.bon!.libelle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Expiration info
              if (voucher.dateExpire != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      voucher.expirationStatus,
                      style: TextStyle(
                        color: voucher.daysUntilExpiration != null &&
                                voucher.daysUntilExpiration! <= 7
                            ? Colors.orange
                            : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Transfer info if voucher has been transferred
              if (voucher.donateur != null && voucher.partenaire != null &&
                  voucher.donateur!.id != voucher.partenaire!.id) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.swap_horiz,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Envoyé par ${voucher.donateur!.fullName}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Action buttons
              if ((showTransferButton && voucher.canBeSent) ||
                  (showUseButton && voucher.isUsable)) ...[
                Row(
                  children: [
                    if (showUseButton && voucher.isUsable) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onUse,
                          icon: const Icon(Icons.shopping_cart, size: 16),
                          label: const Text('Utiliser'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                    if (showTransferButton && voucher.canBeSent && showUseButton && voucher.isUsable) 
                      const SizedBox(width: 8),
                    if (showTransferButton && voucher.canBeSent) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onTransfer,
                          icon: const Icon(Icons.send, size: 16),
                          label: const Text('Envoyer'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

