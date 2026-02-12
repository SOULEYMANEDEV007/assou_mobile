import 'package:ASSOU/utils/logger.dart';
import '../../config/environment.dart';
import 'package:ASSOU/widgets/custom_app_bar.dart';
import 'package:ASSOU/widgets/toast_helper.dart';
import 'package:flutter/material.dart';
import '../../data/models/api_response_model.dart';

import '../../data/services/user_service.dart';
import '../../data/services/voucher_service.dart';
import '../../utils/price_utils.dart';

class VoucherDetailsPage extends StatefulWidget {
  final String? imageUrl;
  final String? description;
  final String? recipientName;
  final String? recipientPhone;
  final String? partnerName;
  final String? partnerPhone;
  final int? userId;
  final int? currentTab;

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
  final String? boutiqueLogoUrl;
  final IconData? eventIcon;

  const VoucherDetailsPage({
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
    this.boutiqueLogoUrl,
    this.eventIcon,
    this.userId,
    this.usersId,
    this.currentTab,
    this.hasThanked,
    this.paiementBonId,
  });

  final bool? hasThanked;
  final int? paiementBonId;

  @override
  State<VoucherDetailsPage> createState() => _VoucherDetailsPageState();
}

class _VoucherDetailsPageState extends State<VoucherDetailsPage> {
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
  final TextEditingController _thankYouController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _hasThanked = widget.hasThanked ?? false;
    UserService.getAuthToken().then((value) {
      if (mounted) {
        setState(() {
          token = value;
        });
      }
    });
  }

  @override
  void dispose() {
    _thankYouController.dispose();
    super.dispose();
  }

  Widget _buildHistoryItem(String title, String fullText, {String? boldValue}) {
    if (boldValue != null && fullText.contains(boldValue)) {
      final parts = fullText.split(boldValue);
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
            children: [
              TextSpan(text: parts[0]),
              TextSpan(
                text: boldValue,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (parts.length > 1) TextSpan(text: parts[1]),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        fullText,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  void _showThankYouMessageDialog() {
    _thankYouController.clear();
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
              children: [
                const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Mot de remerciement",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Souhaitez-vous ajouter un petit message de remerciement ?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _thankYouController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Votre message ici...",
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Annuler",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleRemerciement(_thankYouController.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Envoyer",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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

  Future<void> _handleRemerciement(String message) async {
    AppLogger.info(
        '🎬 Déclenchement de la procédure de remerciement', 'VOUCHER_DETAILS');
    setState(() {
      isLoadingRemerciment = true;
    });

    try {
      AppLogger.debug(
          'ID PaiementBon: ${widget.paiementBonId}', 'VOUCHER_DETAILS');
      AppLogger.debug('Contenu du message: $message', 'VOUCHER_DETAILS');

      if (token == null) {
        AppLogger.error('❌ Token absent lors de l\'appel de remerciement',
            'VOUCHER_DETAILS');
        throw Exception("Token non trouvé");
      }

      final ApiResponse reponse = await VoucherService.remerciementEmeteurBon(
        token: token!,
        paiement_bon_id: widget.paiementBonId!,
        sender_id: widget.senderId,
        libelle: widget.boutiqueName ?? widget.description ?? "Bon d'achat",
        message: message.isNotEmpty ? message : null,
      );

      if (reponse.success) {
        AppLogger.info('✨ Procédure terminée avec succès', 'VOUCHER_DETAILS');
        setState(() {
          _hasThanked = true;
        });
        _showSuccessDialog();
      } else {
        AppLogger.error(
            '⚠️ Réponse API négative: ${reponse.message}', 'VOUCHER_DETAILS');
        ToastHelper.showToast(
          title: "Remerciement du bon",
          context,
          message: "Une erreur est survenue lors de l'envoi du remerciement",
          type: ToastType.error,
        );
      }
    } catch (e) {
      AppLogger.error('🚨 Exception critique dans _handleRemerciement',
          'VOUCHER_DETAILS', e);
      ToastHelper.showToast(
        title: "Erreur",
        context,
        message: "Une erreur s'est produite",
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingRemerciment = false;
        });
      }
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
                    Navigator.of(context).pop(); // Go back or Refresh
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
    final String partnerOrRecipientName =
        widget.partnerName ?? widget.recipientName ?? "";
    final String partnerOrRecipientPhone =
        widget.partnerPhone ?? widget.recipientPhone ?? "N/A";

    final String shopLabel =
        (widget.boutiqueName?.toLowerCase() == "toutes les boutiques" ||
                widget.boutiqueName?.toLowerCase() == "assou")
            ? "ASSOU"
            : (widget.boutiqueName ?? "Boutique");

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: "Détails",
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête avec montant et logo
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
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
                              fontFamily: 'Nunito',
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'Nunito',
                                color: Color(0xFF666666),
                              ),
                              children: [
                                const TextSpan(
                                    text: "Utilisation de ce bon : "),
                                TextSpan(
                                  text: (widget.boutiqueName?.toLowerCase() ==
                                              "toutes les boutiques" ||
                                          widget.boutiqueName?.toLowerCase() ==
                                              "assou")
                                      ? "Toutes les boutiques"
                                      : (widget.boutiqueName ?? "N/A"),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
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
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: widget.boutiqueLogoUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: widget.boutiqueLogoUrl!
                                          .startsWith('assets/')
                                      ? Image.asset(
                                          widget.boutiqueLogoUrl!,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                            widget.eventIcon ?? Icons.store,
                                            color: Colors.grey.shade600,
                                            size: 24,
                                          ),
                                        )
                                      : Image.network(
                                          Environment.getImageUrl(
                                                  widget.boutiqueLogoUrl) ??
                                              "",
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                            widget.eventIcon ?? Icons.store,
                                            color: Colors.grey.shade600,
                                            size: 24,
                                          ),
                                        ),
                                )
                              : Icon(
                                  widget.eventIcon ?? Icons.store,
                                  color: Colors.grey.shade600,
                                  size: 24,
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shopLabel,
                          style: const TextStyle(
                            fontSize: 10, // Réduit légèrement
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Nunito',
                            color: Color(0xFF1A1A1A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section Image et Message (Uniformisée)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Image du bon
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        Environment.getImageUrl(widget.imageUrl) ??
                            "https://images.unsplash.com/photo-1558636508-e0db3814bd1d?w=800&auto=format&fit=crop&q=80",
                        height: 230,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 230,
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
                    // Message du bon
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(12)),
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          const SizedBox(height: 12),
                          Text(
                            "$partnerOrRecipientName ($partnerOrRecipientPhone)",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Nunito',
                              color: Color(0xFF555555),
                            ),
                            textAlign: TextAlign.center,
                          ),

                          // Bouton Remercier
                          if (widget.senderId != widget.userId &&
                              (widget.etatReceiver == 1 || widget.etat == 1))
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: isLoadingRemerciment
                                  ? Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.blue.shade600,
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: (widget.currentTab == 0 &&
                                              (widget.etatReceiver == 1 ||
                                                  widget.etat == 1) &&
                                              _hasThanked != true)
                                          ? _showThankYouMessageDialog
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            (widget.currentTab == 0 &&
                                                    (widget.etatReceiver == 1 ||
                                                        widget.etat == 1) &&
                                                    _hasThanked != true)
                                                ? Colors.blue.shade600
                                                : Colors.grey.shade300,
                                        foregroundColor:
                                            (widget.currentTab == 0 &&
                                                    (widget.etatReceiver == 1 ||
                                                        widget.etat == 1) &&
                                                    _hasThanked != true)
                                                ? Colors.white
                                                : Colors.grey.shade500,
                                        minimumSize:
                                            const Size(double.infinity, 44),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        _hasThanked == true
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
                  ],
                ),
              ),

              SizedBox(
                height: 20,
              ),

              // Section Historique
              /*Container(
                //padding: const EdgeInsets.all(20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Historique",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.dateAchat != null)
                      _buildHistoryItem(
                        "Achat",
                        "Achat : ${_formatDate(widget.dateAchat)} - ${widget.donatorName ?? "${widget.recipientName} (${widget.recipientPhone})"}",
                        boldValue: _formatDate(widget.dateAchat),
                      ),
                    if (widget.dateUsage != null)
                      _buildHistoryItem(
                        "Utilisation",
                        "Utilisation : ${_formatDate(widget.dateUsage)} - ${widget.boutiqueName ?? "Boutique"}",
                        boldValue: _formatDate(widget.dateUsage),
                      )
                    else
                      _buildHistoryItem(
                        "Utilisation",
                        "Utilisation : Pas encore utilisé",
                        boldValue: "Pas encore utilisé",
                      )
                  ],
                ),
              ),*/

              // Section Historique
              /*Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Historique",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Ligne Achat
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        children: [
                          const TextSpan(text: "Achat : "),
                          TextSpan(
                            text: widget.dateAchat != null
                                ? _formatDate(widget.dateAchat!)
                                : "N/A",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextSpan(
                            text: widget.donatorName != null
                                ? " - ${widget.donatorName}"
                                : widget.recipientName != null
                                    ? " - ${widget.recipientName!.split(' ').first}"
                                    : "",
                          ),
                          if (widget.recipientPhone != null)
                            TextSpan(
                              text: " (${widget.recipientPhone})",
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Ligne Utilisation
                    widget.dateUsage != null
                        ? RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                              children: [
                                const TextSpan(text: "Utilisation : "),
                                TextSpan(
                                  text: _formatDate(widget.dateUsage!),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                /* TextSpan(
                                  text: widget.boutiqueName != null
                                      ? " - ${widget.boutiqueName}"
                                      : " - Boutique",
                                ), */
                              ],
                            ),
                          )
                        : Text(
                            "Utilisation : Pas encore utilisé",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                  ],
                ),
              ),*/

              // Logs de débogage (Console uniquement)
              /*if (kDebugMode) {
                print("🔍 Logs de débogage:");
                print("• Date d'achat: ${widget.dateAchat ?? "null"}");
                print("• Date d'utilisation: ${widget.dateUsage ?? "null"}");
                print("• Date actuelle: ${DateTime.now()}");
                print("• Date passée ?: ${widget.dateAchat != null ? (widget.dateAchat!.isBefore(DateTime.now()) ? "OUI" : "NON") : "N/A"}");
              }*/

              // Section Historique - Version Simple (Carte Blanche)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Historique",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Ligne Achat
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontFamily: 'Nunito',
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: "Achat : "),
                          TextSpan(
                            text: widget.dateAchat != null
                                ? "${_formatDate(widget.dateAchat!)} - ${widget.donatorName ?? (widget.recipientName != null ? "${widget.recipientName!.split(' ').first} (${widget.recipientPhone ?? ''})" : "N/A")}"
                                : "N/A",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Ligne Utilisation
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontFamily: 'Nunito',
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: "Utilisation : "),
                          TextSpan(
                            text: widget.dateUsage != null
                                ? "${_formatDate(widget.dateUsage!)} - ${widget.boutiqueName ?? "Boutique"}"
                                : "Pas encore utilisé",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /* 
              // ANCIENNE VERSION (Complex Grid)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                margin: const EdgeInsets.symmetric(
                    horizontal: 0), // S'étend sur toute la largeur
                width: double.infinity, // Prend toute la largeur disponible
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Historique",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        fontFamily: 'Nunito', // Police Nunito
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // ... (Code précédent commenté)
               */

              SizedBox(height: 20),

              // Bouton Fermer (toujours visible)
              Container(
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
      ),
    );
  }

  int _calculateDaysDifference(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    return difference.inDays.abs();
  }
}
