import 'package:flutter/material.dart';
import '../data/models/bon_achat_model.dart';

class VoucherStatusChip extends StatelessWidget {
  final PaiementBon voucher;
  final bool showIcon;
  final double fontSize;

  const VoucherStatusChip({
    super.key,
    required this.voucher,
    this.showIcon = true,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: voucher.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: voucher.statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              voucher.statusIcon,
              size: 16,
              color: voucher.statusColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            voucher.etatLabel,
            style: TextStyle(
              color: voucher.statusColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

