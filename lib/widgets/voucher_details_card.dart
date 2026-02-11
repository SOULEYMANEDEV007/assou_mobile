import 'package:ASSOU/widgets/toast_helper.dart';
import '../../config/environment.dart';
import 'package:flutter/material.dart';
import '../data/models/api_response_model.dart';
import '../data/services/user_service.dart';
import '../data/services/voucher_service.dart';
import '../utils/price_utils.dart';

class VoucherDetailsCard extends StatefulWidget {
  final String? imageUrl;
  final String? description;
  final String? recipientName;
  final String? recipientPhone;
  final String? partnerName;
  final String? partnerPhone;
  final int? userId;
  final bool? hasThanked;
  final int? paiementBonId;

  // Propriétés transaction
  final String? codeBon;
  final double? montantBon;
  final String? personal_message;
  final int? etat;
  final int? etatReceiver;
  final int? senderId;
  final int? usersId;
  final int? receiverId;
  final DateTime? dateExpire;
  final DateTime? dateUsage;
  final DateTime? dateAchat;
  final DateTime? dateExpiration;
  final String? donatorName;
  final String? boutiqueName;
  final String? eventName;
  final double? joursAvantExpiration;
  final double? joursDepuisExpiration;

  const VoucherDetailsCard({
    super.key,
    this.imageUrl,
    this.description,
    this.recipientName,
    this.recipientPhone,
    this.codeBon,
    this.montantBon,
    this.personal_message,
    this.etat,
    this.etatReceiver,
    this.senderId,
    this.receiverId,
    this.dateExpire,
    this.dateUsage,
    this.dateAchat,
    this.dateExpiration,
    this.donatorName,
    this.partnerName,
    this.partnerPhone,
    this.boutiqueName,
    this.eventName,
    this.joursAvantExpiration,
    this.joursDepuisExpiration,
    this.userId,
    this.usersId,
    this.hasThanked,
    this.paiementBonId,
  });

  @override
  State<VoucherDetailsCard> createState() => _VoucherDetailsCardState();
}

class _VoucherDetailsCardState extends State<VoucherDetailsCard> {
  String _formatDate(DateTime? date) {
    if (date == null) return "N/A";
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');
    return "$day/$month/${date.year} - ${hour}H$minute";
  }

  String? token;
  bool isLoadingRemerciment = false;
  bool _hasThanked = false;

  @override
  void initState() {
    super.initState();
    _hasThanked = widget.hasThanked ?? false;
    UserService.getAuthToken().then((value) {
      setState(() {
        token = value;
      });
    });
  }

  Widget _buildHistoryItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade700,
          height: 1.4,
        ),
      ),
    );
  }

  void _showRemerciementInputDialog() {
    final TextEditingController messageController = TextEditingController(
      text:
          "Merci beaucoup pour ce bon d'achat , ton geste me touche énormément 🙏.",
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Envoyer un remerciement",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Écrivez votre message ici...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade600),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Annuler",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final String message = messageController.text.trim();
                          Navigator.pop(context); // Close input dialog
                          _processRemerciement(message);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: const Text("Envoyer"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _processRemerciement(String message) async {
    setState(() {
      isLoadingRemerciment = true;
    });

    try {
      final ApiResponse reponse = await VoucherService.remerciementEmeteurBon(
        token: token!,
        paiement_bon_id: widget.paiementBonId!,
        message: message,
        libelle: '',
      );

      if (reponse.success) {
        setState(() {
          _hasThanked = true;
        });
        _showSuccessDialog();
      } else {
        ToastHelper.showToast(
          title: "Remerciement du bon",
          context,
          message: "Une erreur est survenue lors de l'envoi du remerciement",
          type: ToastType.error,
        );
      }
    } catch (e) {
      print(e);
      ToastHelper.showToast(
        title: "Erreur",
        context,
        message: "Une erreur s'est produite",
        type: ToastType.error,
      );
    } finally {
      setState(() {
        isLoadingRemerciment = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.green.shade500,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Vos remerciements\nont bien été envoyés",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTransactionView = widget.etatReceiver != 1;
    final String partnerOrRecipientName =
        widget.partnerName ?? widget.recipientName ?? "";
    final String partnerOrRecipientPhone =
        widget.partnerPhone ?? widget.recipientPhone ?? "N/A";

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header bleu
            Container(
              height: 4,
              color: Colors.blue.shade600,
            ),

            // En-tête avec montant et logo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          PriceUtils.formatPrice(
                            widget.montantBon,
                            showCurrency: true,
                          ),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            children: [
                              const TextSpan(text: "Utilisation de ce bon : "),
                              TextSpan(
                                text: widget.boutiqueName ?? "N/A",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.store,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.boutiqueName ?? "Partenaire",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Image du bon
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  Environment.getImageUrl(widget.imageUrl) ??
                      "https://images.unsplash.com/photo-1558636508-e0db3814bd1d?w=800&auto=format&fit=crop&q=80",
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey.shade400,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Message du bon
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  if (widget.personal_message != null &&
                      widget.personal_message!.isNotEmpty)
                    Column(
                      children: [
                        Text(
                          widget.personal_message!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  Text(
                    widget.description ?? "Aucune description disponible",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "$partnerOrRecipientName ($partnerOrRecipientPhone)",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Bouton Remercier (Visibilité corrigée)
                  if (widget.senderId != widget.userId &&
                      (widget.etatReceiver == 1 || widget.etat == 1))
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: isLoadingRemerciment
                          ? Center(
                              child: CircularProgressIndicator(
                                color: Colors.blue.shade600,
                              ),
                            )
                          : ElevatedButton(
                              onPressed: (_hasThanked == true)
                                  ? null
                                  : () => _showRemerciementInputDialog(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (_hasThanked == true)
                                    ? Colors.grey.shade300
                                    : Colors.blue.shade600,
                                foregroundColor: (_hasThanked == true)
                                    ? Colors.grey.shade500
                                    : Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                (_hasThanked == true)
                                    ? "Déjà remercié"
                                    : "Remercier",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                ],
              ),
            ),

            // Section Historique
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildHistoryItem(
                    widget.dateAchat != null
                        ? "Achat : ${_formatDate(widget.dateAchat)} - ${widget.donatorName ?? "${widget.recipientName} (${widget.recipientPhone})"}"
                        : "Achat : Date non disponible - ${widget.donatorName ?? "${widget.recipientName} (${widget.recipientPhone})"}",
                  ),
                  _buildHistoryItem(
                    widget.dateUsage != null
                        ? "Utilisation : ${_formatDate(widget.dateUsage)}"
                        : "Utilisation : Pas encore utilisé",
                  ),
                  if (widget.dateExpire != null)
                    _buildHistoryItem(
                      "Expiration : ${_formatDate(widget.dateExpire)}",
                    ),
                  if (widget.codeBon != null)
                    _buildHistoryItem(
                      "Code : ${widget.codeBon!}",
                    ),
                  if (widget.joursAvantExpiration != null &&
                      widget.joursAvantExpiration! > 0)
                    _buildHistoryItem(
                      "Expire dans : ${widget.joursAvantExpiration!.toInt()} jours",
                    ),
                  if (widget.joursDepuisExpiration != null &&
                      widget.joursDepuisExpiration! > 0)
                    _buildHistoryItem(
                      "Expiré depuis : ${widget.joursDepuisExpiration!.toInt()} jours",
                    ),
                ],
              ),
            ),

            // Bouton Fermer (toujours visible)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.grey.shade800,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text("Fermer"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
