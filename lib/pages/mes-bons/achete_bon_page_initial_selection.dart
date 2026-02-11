import 'package:flutter/material.dart';

import '../../data/models/bon_achat_model.dart';
import '../acheter/acheter.dart';

class AcheterBonPageInitialSelection extends StatefulWidget {
  final String boutique;
  final String montant;
  final int? bonId;
  final PaiementBon? paiementBon;

  const AcheterBonPageInitialSelection({
    super.key,
    required this.boutique,
    required this.montant,
    this.bonId,
    this.paiementBon,
  });

  @override
  State<AcheterBonPageInitialSelection> createState() =>
      _AcheterBonPageInitialSelectionState();
}

class _AcheterBonPageInitialSelectionState
    extends State<AcheterBonPageInitialSelection> {
  @override
  Widget build(BuildContext context) {
    return const AcheterBonPage();
  }
}
