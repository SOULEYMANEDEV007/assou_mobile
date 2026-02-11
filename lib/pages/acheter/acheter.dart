import 'dart:async';
import 'package:ASSOU/pages/acheter/widgets/contact_picker_field.dart';
import 'package:ASSOU/pages/acheter/widgets/custom_radio_group.dart';
import 'package:ASSOU/pages/acheter/widgets/custom_text_field.dart';
import 'package:ASSOU/pages/acheter/widgets/even_type_selector_widget.dart';
import 'package:ASSOU/pages/acheter/widgets/store_selector_widget.dart';
import 'package:ASSOU/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ASSOU/utils/price_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/event_type_model.dart';
import '../../data/services/boutique_service.dart';
import '../../data/services/event_type_service.dart';
import '../../data/services/payment_service.dart';
import '../../data/models/boutique_model.dart';
import '../../data/models/bon_achat_model.dart';
import '../../data/models/voucher_purchase_request.dart';
import '../../data/models/voucher_purchase_response.dart';
import '../../data/services/user_service.dart';
import '../../data/services/deep_link_payment_service.dart';
import '../../utils/logger.dart';
import '../../widgets/toast_helper.dart';
import 'package:provider/provider.dart';
import '../../providers/reward_provider.dart';
import '../../config/environment.dart';

class AcheterBonPage extends StatefulWidget {
  final bool showBottomNav;

  const AcheterBonPage({super.key, this.showBottomNav = true});

  @override
  State<AcheterBonPage> createState() => _AcheterBonPageState();
}

class _AcheterBonPageState extends State<AcheterBonPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  List<Boutique> boutiques = [];
  List<Boutique> filteredBoutiques = [];

  // Boutique? filteredBoutique; // Removed as unused
  Boutique? selectedBoutique;
  final TextEditingController searchController = TextEditingController();
  bool isSearchExpanded = false;
  String urlogo = "";

  // Real vouchers from API
  List<BonAchat> availableVouchers = [];
  Set<int> selectedVoucherIds = {}; // Selected voucher IDs (1 of each)
  bool isLoadingVouchers = false;

  bool isLoading = false;
  String? token;
  bool _showSuccess = false;
  bool _dialogDismissed = false;
  late AnimationController _successController;
  late Animation<double> _successScale;

  // Payment status polling
  Timer? _paymentStatusTimer;
  Timer? _paymentTimeoutTimer;
  int _statusCheckAttempts = 0;
  static const int _maxStatusCheckAttempts = 30; // 5 minutes (30 * 10 seconds)

  // Deep link listener
  StreamSubscription? _deepLinkSubscription;

  // Payment reference for status checking
  String? _currentPaymentReference;
  bool _isFormValid = false;

  String logobase =
      "https://res.cloudinary.com/dmlozs3uk/image/upload/v1758204981/istockphoto-1174549062-612x612_ajteum.jpg";

  final TextEditingController destinataireController = TextEditingController();
  final TextEditingController evenementController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final TextEditingController montantController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  EventType? selectedEventType;
  bool isLoadingEventTypes = false;
  List<EventType> eventTypes = [];

  bool notificationValue = false;
  String? boutiqueValue;
  String? paymentMethod = 'wave';

  @override
  void initState() {
    super.initState();
    AppLogger.info('Initializing AcheterBonPage', 'ACHETER');

    _loadEventTypes();

    // Reset all states to prevent persistence across hot reloads
    _showSuccess = false;
    _dialogDismissed = false;
    isLoading = false;

    // Clear any existing toasts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    });

    _initializeData();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );

    searchController.addListener(() {
      _filterBoutiques();
    });

    // Listen for deep link payment results
    _setupDeepLinkListener();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _currentPaymentReference != null) {
      AppLogger.info(
          '📱 App resumed - Triggering immediate status check', 'ACHETER');
      _checkPaymentStatusAutomatically(
          _currentPaymentReference!, _paymentStatusTimer!);
    }
  }

  Future<void> _initializeData() async {
    AppLogger.debug('Initializing data for purchase page', 'ACHETER');
    token = await UserService.getAuthToken();
    if (token != null) {
      AppLogger.info('Auth token retrieved successfully', 'ACHETER');
      await _loadBoutiques();
    } else {
      AppLogger.warning('No auth token available', 'ACHETER');
    }
  }

  @override
  void dispose() {
    AppLogger.debug('Disposing AcheterBonPage', 'ACHETER');
    WidgetsBinding.instance.removeObserver(this);
    _paymentStatusTimer?.cancel();
    _paymentTimeoutTimer?.cancel();
    _deepLinkSubscription?.cancel();
    _successController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _setupDeepLinkListener() {
    final deepLinkService = DeepLinkPaymentService();
    _deepLinkSubscription = deepLinkService.paymentResults.listen(
      (PaymentResult result) {
        AppLogger.info(
            'Résultat du paiement par lien profond reçu: ${result.toString()}',
            'ACHETER');

        // Stop polling when deep link is received
        _paymentStatusTimer?.cancel();

        // Dismiss payment dialog if open
        if (mounted) {
          _dismissPaymentDialog().then((_) async {
            if (mounted) {
              if (result.success) {
                AppLogger.info('✅ Paiement réussi via lien profond', 'ACHETER');
                _showSuccessToastAndReload();
              } else {
                AppLogger.error(
                    '❌ Échec du paiement via lien profond: ${result.message}',
                    'ACHETER');
                _handlePaymentFailure();
              }
            }
          }).catchError((e) {
            AppLogger.error(
                'Navigation error in deep link handler', 'ACHETER', e);
            if (mounted) {
              if (result.success) {
                _showAnimatedSuccess();
              } else {
                _handlePaymentFailure();
              }
            }
          });
        }
      },
      onError: (error) {
        AppLogger.error('Deep link payment error', 'ACHETER', error);
      },
    );
  }

  Future<void> _loadBoutiques() async {
    if (token == null) return;

    AppLogger.info('Loading boutiques', 'ACHETER');
    setState(() {
      isLoading = true;
    });

    try {
      final list = await BoutiqueService.getBoutiques(token: token!);
      setState(() {
        boutiques = list.map((b) {
          if (b.name == "Toutes les boutiques") {
            // Mise à jour de logobase (l'icône par défaut du sélecteur)
            // pour qu'elle corresponde à celle de "Toutes les boutiques"
            if (b.logo != null) {
              final logoUrl = Environment.getImageUrl(b.logo);
              if (logoUrl != null) logobase = logoUrl;
            }

            // Création d'une nouvelle instance avec le nom concaténé "Dans "
            return Boutique(
              id: b.id,
              name: "Dans toutes les boutiques",
              slug: b.slug,
              description: b.description,
              logo: b.logo,
              codeBoutique: b.codeBoutique,
              contact: b.contact,
              address: b.address,
              email: b.email,
              type: b.type,
              availableVouchersCount: b.availableVouchersCount,
              firstVouchers: b.firstVouchers,
              totalAmount: b.totalAmount,
            );
          }
          return b;
        }).toList();

        filteredBoutiques = boutiques;
        isLoading = false;
      });
      AppLogger.info(
          'Loaded ${boutiques.length} boutiques (with renaming) successfully',
          'ACHETER');
    } catch (e) {
      AppLogger.error('Failed to load boutiques: $e', 'ACHETER');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterBoutiques() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredBoutiques = boutiques.where((boutique) {
        return boutique.name.toLowerCase().contains(query) ||
            (boutique.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  void _selectBoutique(Boutique boutique) {
    setState(() {
      selectedBoutique = boutique;
      selectedVoucherIds.clear(); // Reset selections when changing boutique
      isSearchExpanded = false;
      searchController.clear();
      filteredBoutiques = boutiques;

      urlogo =
          boutique.logoUrl != null ? boutique.logoUrl.toString() : logobase;
      availableVouchers.clear(); // Clear previous vouchers
    });
    AppLogger.userAction('Selected boutique',
        data: {'boutiqueSlug': boutique.slug, 'boutiqueName': boutique.name});

    // Load vouchers for the selected boutique
    _loadVouchersForBoutique(boutique.slug);
  }

  Future<void> _loadVouchersForBoutique(String boutiqueSlug) async {
    if (token == null) return;

    AppLogger.info('Loading vouchers for boutique: $boutiqueSlug', 'ACHETER');
    setState(() {
      isLoadingVouchers = true;
    });

    try {
      final vouchers = await BoutiqueService.getBoutiqueVouchers(
        token: token!,
        boutiqueSlug: boutiqueSlug,
        perPage: 50, // Load more vouchers
      );

      setState(() {
        availableVouchers = vouchers;
        isLoadingVouchers = false;
      });

      AppLogger.info(
          'Loaded ${vouchers.length} vouchers for boutique $boutiqueSlug',
          'ACHETER');
      AppLogger.debug(
          'Voucher types loaded: ${vouchers.map((v) => '${v.libelle}(${v.id}) - ${v.montantBon} FCFA - boutiqueId: ${v.boutiqueId}').join(', ')}',
          'ACHETER');

      // Log universal vs boutique-specific vouchers
      final universalVouchers =
          vouchers.where((v) => v.boutiqueId == 0 || v.boutiqueId == null);
      final boutiqueVouchers =
          vouchers.where((v) => v.boutiqueId != 0 && v.boutiqueId != null);
      AppLogger.debug(
          'Universal vouchers: ${universalVouchers.length}, Boutique-specific vouchers: ${boutiqueVouchers.length}',
          'ACHETER');
    } catch (e) {
      AppLogger.error(
          'Failed to load vouchers for boutique $boutiqueSlug', 'ACHETER', e);
      setState(() {
        isLoadingVouchers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des bons: $e')),
        );
      }
    }
  }

  double _calculateSubtotal() {
    double total = 0.0;
    for (final voucherId in selectedVoucherIds) {
      final voucher = availableVouchers.firstWhere((v) => v.id == voucherId);
      total += voucher.montantBon;
    }
    return total;
  }

  double _calculateFees() {
    // 5% fee as mentioned in requirements
    return _calculateSubtotal() * 0.05;
  }

  double _calculateTotal() {
    return _calculateSubtotal() + _calculateFees();
  }

  int _getTotalVouchers() {
    return selectedVoucherIds.length;
  }

  Future<void> _initiatePayment() async {
    // Validate custom amount
    final montantStr = montantController.text.trim();
    if (montantStr.isEmpty) {
      _showErrorSnackBar('Veuillez entrer un montant');
      return;
    }

    final double? montant = double.tryParse(montantStr.replaceAll(' ', ''));
    if (montant == null || montant < 5000) {
      _showErrorSnackBar('Le montant doit être au moins de 5 000 FCFA');
      return;
    }

    // Validate recipient
    final recipientName = destinataireController.text.trim();

    final recipientPhone = phoneController.text.trim();
    if (recipientPhone.isEmpty) {
      _showErrorSnackBar('Veuillez entrer le numéro du destinataire');
      return;
    }

    // Boutique logic
    // If a boutique is selected, it's specific. If not, it's universal (or enforce selection?)
    // Assuming if boutique is null, it's universal.
    final bool isUniversal = selectedBoutique == null;
    final int? idBoutique = selectedBoutique?.id;
    final int? evenementId = selectedEventType?.id;
    final String moyenPaiement = 'wave';

    AppLogger.info('🛒 Amorce de l\'achat de bon personnalisé', 'ACHETER');

    try {
      setState(() => isLoading = true);

      // URLs de redirection avec schéma assou:// pour une ouverture directe de l'app
      // Note: Le backend ajoutera probablement la référence à la fin de l'URL
      final successUrl = 'assou://payment/success';
      final errorUrl = 'assou://payment/error';

      final request = CustomVoucherPurchaseRequest(
          destinataire: recipientPhone,
          evenementId: evenementId,
          notifierEnvoyeur: notificationValue,
          messagePersonnalise: messageController.text.trim(),
          montantPersonnalise: double.parse(montantStr),
          idBoutique: idBoutique,
          destinataireName: recipientName.isEmpty ? null : recipientName,
          moyenPaiement: moyenPaiement,
          successUrl: successUrl,
          errorUrl: errorUrl);

      // Use the new custom voucher purchase method
      final response = await PaymentService.purchaseCustomVouchers(
        token: token!,
        request: request,
      );

      if (response != null) {
        AppLogger.info(
            '✅ Achat de bon personnalisé initié avec succès', 'ACHETER');

        _currentPaymentReference = response.paiement.reference;

        if (response.waveLaunchUrl != null &&
            response.waveLaunchUrl!.isNotEmpty) {
          AppLogger.info('🌊 Paiement Wave requis', 'ACHETER');
          _showPaymentWaitingDialog(response);
        } else {
          AppLogger.info('✅ Paiement terminé immédiatement', 'ACHETER');
          _handleSuccess(null, reason: 'Succès immédiat confirmé par l\'API');
        }
      } else {
        AppLogger.error('❌ Échec de l\'achat de bon personnalisé', 'ACHETER');
        _showErrorSnackBar('Échec de l\'achat du bon');
      }
    } catch (e) {
      AppLogger.error(
          '❌ Erreur lors de l\'achat de bon personnalisé', 'ACHETER', e);
      _showErrorSnackBar('Erreur lors de l\'achat: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /*void _showPaymentWaitingDialog(VoucherPurchaseResponse response) {
    AppLogger.info('Showing payment waiting dialog', 'ACHETER');

    // Automatically launch Wave payment
    if (response.waveLaunchUrl != null && response.waveLaunchUrl!.isNotEmpty) {
      _launchWavePayment(response.waveLaunchUrl!);

      // Start automatic status checking every 10 seconds
      _startPaymentStatusPolling(response.paiement.reference);
    }

    // Reset dialog dismissal flag
    _dialogDismissed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.payment, color: Color(0xFF2F55E0)),
              SizedBox(width: 8),
              Text('Paiement Wave'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Référence: ${response.paiement.reference}'),
                const SizedBox(height: 8),
                Text(
                    'Montant: ${PriceUtils.formatPrice(response.paiement.montantPaiement)}'),
                const SizedBox(height: 16),
                const Text('Wave a été ouvert. Complétez le paiement.'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  'Vérification automatique en cours...',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500))),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                          'Le statut sera mis à jour automatiquement toutes les 10 secondes.',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _paymentStatusTimer?.cancel();
                Navigator.of(context).pop();
                _handlePaymentFailure();
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                // Copy URL to clipboard for manual testing
                await Clipboard.setData(
                    ClipboardData(text: response.waveLaunchUrl!));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('URL copiée dans le presse-papiers')),
                  );
                }
              },
              child: const Text('Copier URL'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Launch Wave app/URL again
                await _launchWavePayment(response.waveLaunchUrl!);
                // Restart status polling if it was stopped
                _paymentStatusTimer?.cancel();
                _startPaymentStatusPolling(response.paiement.reference);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F55E0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Relancer Wave'),
            ),
            TextButton(
              onPressed: () {
                // Stop polling and close dialog
                _paymentStatusTimer?.cancel();
                Navigator.of(context).pop();
              },
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }*/

  void _showPaymentWaitingDialog(VoucherPurchaseResponse response) {
    AppLogger.info(
        'Affichage de la boîte de dialogue d\'attente de paiement', 'ACHETER');

    // Automatically launch Wave payment
    if (response.waveLaunchUrl != null && response.waveLaunchUrl!.isNotEmpty) {
      _launchWavePayment(response.waveLaunchUrl!);

      // Start automatic status checking every 10 seconds
      _startPaymentStatusPolling(response.paiement.reference);
    }

    // Reset dialog dismissal flag
    _dialogDismissed = false;

    // ⏱️ AUTO TIMEOUT : 5 minutes (300s) max sans paiement pour laisser le temps à l'utilisateur
    _paymentTimeoutTimer?.cancel();
    _paymentTimeoutTimer = Timer(const Duration(seconds: 300), () {
      if (!mounted) return;

      AppLogger.warning(
          '⏳ Délai d\'attente de paiement (5 min) atteint – échec automatique',
          'ACHETER');

      _paymentStatusTimer?.cancel();

      _dismissPaymentDialog().then((_) {
        if (mounted) {
          _handlePaymentFailure(); // 🔥 même popup que "Annuler"
        }
      });
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.payment, color: Color(0xFF2F55E0)),
              SizedBox(width: 8),
              Text('Paiement Wave'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Référence: ${response.paiement.reference}'),
                const SizedBox(height: 8),
                Text(
                  'Montant: ${PriceUtils.formatPrice(response.paiement.montantPaiement)}',
                ),
                const SizedBox(height: 16),
                const Text('Wave a été ouvert. Complétez le paiement.'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vérification automatique en cours...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Le statut sera mis à jour automatiquement toutes les 10 secondes.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _paymentTimeoutTimer?.cancel(); // ⛔ stop timeout
                _paymentStatusTimer?.cancel();
                Navigator.of(context).pop();
                _handlePaymentFailure();
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(
                    ClipboardData(text: response.waveLaunchUrl!));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('URL copiée dans le presse-papiers')),
                  );
                }
              },
              child: const Text('Copier URL'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _launchWavePayment(response.waveLaunchUrl!);
                _paymentStatusTimer?.cancel();
                _startPaymentStatusPolling(response.paiement.reference);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F55E0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Relancer Wave'),
            ),
            TextButton(
              onPressed: () {
                _paymentTimeoutTimer?.cancel();
                _paymentStatusTimer?.cancel();
                Navigator.of(context).pop();
              },
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  void _startPaymentStatusPolling(String reference) {
    if (!mounted) {
      AppLogger.warning(
          '⛔ Tentative de démarrage du polling sur un widget non monté',
          'ACHETER');
      return;
    }

    AppLogger.info(
        '🔄 Démarrage du polling de statut de paiement pour la référence: $reference',
        'ACHETER');

    _statusCheckAttempts = 0;

    _paymentStatusTimer?.cancel(); // sécurité, on annule l’ancien timer

    _paymentStatusTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) async {
      _statusCheckAttempts++;

      AppLogger.debug(
          'Tentative de vérification du statut du paiement $_statusCheckAttempts/$_maxStatusCheckAttempts',
          'ACHETER');

      // Vérifier si le widget existe encore
      if (!mounted) {
        timer.cancel();
        AppLogger.warning(
            '⛔ Polling stopped because widget is no longer mounted', 'ACHETER');
        return;
      }

      await _checkPaymentStatusAutomatically(reference, timer);

      // Vérifier le dépassement du nombre d'essais
      if (_statusCheckAttempts >= _maxStatusCheckAttempts) {
        AppLogger.warning(
            '⏳ La vérification du statut a atteint le nombre maximum d\'essais ($_maxStatusCheckAttempts)',
            'ACHETER');
        timer.cancel();
        if (mounted) {
          _handlePaymentTimeout();
        }
      }
    });
  }

  Future<void> _checkPaymentStatusAutomatically(
    String reference,
    Timer? timer,
  ) async {
    if (!mounted) {
      timer?.cancel();
      return;
    }

    try {
      final voucherPayment = await PaymentService.checkVoucherPaymentStatus(
        token: token!,
        reference: reference,
      );

      if (!mounted) {
        timer?.cancel();
        return;
      }

      if (voucherPayment == null) {
        // En cas de retour null (erreur API), on continue le polling pour la résilience
        AppLogger.debug(
            'Retour API null pour la référence $reference, nouvel essai prochainement...',
            'ACHETER');
        return;
      }

      AppLogger.debug(
          'Résultat du poll: id=${voucherPayment.id}, reference=$reference, etat=${voucherPayment.etat}, isSucceeded=${voucherPayment.isSucceeded}',
          'ACHETER');

      if (voucherPayment.isSucceeded) {
        _handleSuccess(timer,
            reason:
                'Succès confirmé par le serveur (etat=2 ou is_successful=true)');
      } else if (voucherPayment.isFailed) {
        _handleFailure(timer, reason: 'Échec confirmé par le serveur (etat=4)');
      } else if (voucherPayment.isPending ||
          voucherPayment.isInitiated ||
          voucherPayment.isProcessing) {
        AppLogger.debug(
            'Paiement en cours: ${voucherPayment.statusText} (etat=${voucherPayment.etat})',
            'ACHETER');
      } else {
        AppLogger.debug(
            'État non géré (${voucherPayment.etat}), poursuite de la vérification...',
            'ACHETER');
      }
    } catch (e) {
      AppLogger.error(
          'Erreur lors de la vérification automatique: $e', 'ACHETER');
      // On continue le polling malgré l'erreur réseau (résilience face aux problèmes DNS/Socket)
    }
  }

  /// Facteur commun : gérer succès
  Future<void> _handleSuccess(Timer? timer, {required String reason}) async {
    AppLogger.info(
        '✅ [TRACE_SUCCESS] _handleSuccess called - $reason', 'ACHETER');
    timer?.cancel();
    if (!mounted) return;

    // Refresh rewards after successful purchase with a slight delay
    // to ensure backend trigger (which can be async) has finished processing.
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        AppLogger.info('DEBUG [ACHETER] Refreshing rewards...', 'ACHETER');
        context.read<RewardProvider>().refreshAll();
      }
    });

    try {
      await _dismissPaymentDialog();

      // Show success dialog instead of toast
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Green checkmark icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Success message
                    const Text(
                      'Paiement et envoie du bon\neffectués avec succès',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // OK button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushReplacementNamed(context, "/home");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
    } catch (e) {
      AppLogger.error('Error while handling success UI', 'ACHETER', e);
      // Fallback to toast if dialog fails
      if (mounted) {
        ToastHelper.showToast(context,
            title: "Paiement effectué",
            message:
                "Paiement effectué avec succès ! Le bon est maintenant disponible.",
            type: ToastType.success);

        Future.delayed(const Duration(milliseconds: 800), () {
          Navigator.pushReplacementNamed(context, "/home");
        });
      }
    }
  }

  /// Facteur commun : gérer échec
  Future<void> _handleFailure(Timer? timer, {required String reason}) async {
    AppLogger.error('❌ Payment failed - $reason', 'ACHETER');
    timer?.cancel();
    if (!mounted) return;

    try {
      await _dismissPaymentDialog();
      _handlePaymentFailure();
    } catch (e) {
      AppLogger.error('Error while handling failure UI', 'ACHETER', e);
      _handlePaymentFailure();
    }
  }

  /// Cas particulier : fallback en succès
  Future<void> _assumeSuccess(Timer timer, {required String reason}) async {
    AppLogger.info('🤔 Fallback: assuming success - $reason', 'ACHETER');
    timer.cancel();
    if (!mounted) return;

    try {
      await _dismissPaymentDialog();
      _showAnimatedSuccess();
    } catch (e) {
      AppLogger.error('Error during fallback success UI', 'ACHETER', e);
      _showAnimatedSuccess();
    }
  }

  void _handlePaymentTimeout() async {
    if (mounted) {
      await _dismissPaymentDialog();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('Vérification en cours'),
            ],
          ),
          content: const Text(
            'Votre paiement Wave a été traité, mais la vérification du statut prend plus de temps que prévu.\n\n'
            'Si vous avez effectué le paiement avec succès dans Wave, vos bons d\'achat devraient apparaître dans "Mes Bons" sous peu.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to Mes Bons to see purchased vouchers
                Navigator.of(context).pushNamed('/mes-bons');
              },
              child: const Text('Voir Mes Bons'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset form for new purchase
                setState(() {
                  selectedBoutique = null;
                  selectedVoucherIds.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F55E0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Nouveau Achat'),
            ),
          ],
        ),
      );
    }
  }

  void _handlePaymentFailure() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Paiement échoué'),
            ],
          ),
          content: const Text(
            'Votre paiement n\'a pas pu être traité. '
            'Aucun montant n\'a été débité de votre compte.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset form
                setState(() {
                  selectedBoutique = null;
                  selectedVoucherIds.clear();
                });
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _dismissPaymentDialog() async {
    if (mounted && !_dialogDismissed) {
      try {
        // We set the flag first to avoid multiple calls
        _dialogDismissed = true;

        // Use a more robust check before popping
        if (ModalRoute.of(context)?.isCurrent == false) {
          AppLogger.debug('Attempting to dismiss dialog securely', 'ACHETER');
          Navigator.of(context, rootNavigator: true).pop();
        } else {
          AppLogger.debug(
              'No active dialog detected via ModalRoute', 'ACHETER');
          // If we are on the current route, it means the dialog might have been
          // closed by user or wasn't even there.
        }
      } catch (e) {
        AppLogger.error('Dialog dismissal error: $e', 'ACHETER');
      }
    }
  }

  Future<void> _launchWavePayment(String waveUrl) async {
    AppLogger.info('🌊 Launching Wave payment: $waveUrl', 'ACHETER');

    try {
      // Ensure proper URL encoding
      final cleanUrl = waveUrl.replaceAll(' ', '%20');
      final uri = Uri.parse(cleanUrl);
      AppLogger.debug('Parsed URI: $uri', 'ACHETER');
      AppLogger.debug(
          'URI scheme: ${uri.scheme}, host: ${uri.host}, path: ${uri.path}',
          'ACHETER');
      AppLogger.debug('Query parameters: ${uri.queryParameters}', 'ACHETER');

      // First, try to launch with external application mode to prefer Wave app
      bool launched = false;

      try {
        // Try external application first (Wave app)
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        AppLogger.info(
            '✅ Wave payment launched with external app: $launched', 'ACHETER');
      } catch (e) {
        AppLogger.warning('External app launch failed: $e', 'ACHETER');
      }

      // If external app launch failed, try platform default
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
          AppLogger.info(
              '✅ Wave payment launched with platform default: $launched',
              'ACHETER');
        } catch (e) {
          AppLogger.warning('Platform default launch failed: $e', 'ACHETER');
        }
      }

      // If both failed, try in-app web view as final fallback
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
          );
          AppLogger.info(
              '✅ Wave payment opened in web view: $launched', 'ACHETER');
        } catch (e) {
          AppLogger.error('Web view launch also failed: $e', 'ACHETER');
        }
      }

      if (!launched) {
        throw Exception('All launch modes failed');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to launch Wave payment', 'ACHETER', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir Wave: $e\n\nURL: $waveUrl'),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Copier URL',
              onPressed: () async {
                // Copy URL to clipboard for manual testing
                await Clipboard.setData(ClipboardData(text: waveUrl));
                AppLogger.info(
                    'Wave URL copied to clipboard: $waveUrl', 'ACHETER');
              },
            ),
          ),
        );
      }
    }
  }

  void _showSuccessToastAndReload() {
    if (mounted) {
      AppLogger.info(
          '🎉 [TRACE_SUCCESS] _showSuccessToastAndReload called', 'ACHETER');

      // Refresh rewards after successful purchase with a slight delay
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          context.read<RewardProvider>().refreshAll();
        }
      });

      // Show success toast
      /*
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Paiement réussi! Vos bons sont maintenant disponibles.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      */

      // Reset form
      setState(() {
        selectedBoutique = null;
        selectedVoucherIds.clear();
        availableVouchers.clear();
      });

      // Navigate to home and trigger data refresh
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          // Navigate to home with refresh flag
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
            arguments: {'shouldRefresh': true}, // Pass refresh flag
          );
        }
      });
    }
  }

  void _showAnimatedSuccess() async {
    // Refresh rewards after successful purchase
    if (mounted) {
      AppLogger.info(
          '🎉 [TRACE_SUCCESS] _showAnimatedSuccess called', 'ACHETER');
      // Refresh rewards after successful purchase with a slight delay
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          context.read<RewardProvider>().refreshAll();
        }
      });
    }

    try {
      AppLogger.info('🎉 Affichage de l\'animation de succès', 'ACHETER');
      if (mounted) {
        AppLogger.debug('Activation de _showSuccess = true', 'ACHETER');
        setState(() {
          _showSuccess = true;
        });

        AppLogger.debug(
            'Démarrage de l\'animation de succès (avant)', 'ACHETER');
        _successController.forward(from: 0);

        await Future.delayed(
            const Duration(seconds: 3)); // Longer duration for testing

        if (mounted) {
          AppLogger.debug(
              'Démarrage de l\'animation de succès (arrière)', 'ACHETER');
          _successController.reverse();
          await Future.delayed(const Duration(milliseconds: 400));
          if (mounted) {
            AppLogger.debug(
                'Hiding success animation and resetting form', 'ACHETER');
            setState(() {
              _showSuccess = false;
              // Reset form after successful payment
              selectedBoutique = null;
              selectedVoucherIds.clear();
              availableVouchers.clear();
            });
          }
        }
      }
    } catch (e) {
      AppLogger.error('Erreur dans l\'animation de succès', 'ACHETER', e);
      // Fallback: reset state even if animation fails
      if (mounted) {
        setState(() {
          _showSuccess = false;
          selectedBoutique = null;
          selectedVoucherIds.clear();
          availableVouchers.clear();
        });
      }
    }
  }

  // Nouvelle méthode pour vérifier manuellement le statut du paiement
  Future<void> _checkPaymentStatusManually() async {
    if (_currentPaymentReference == null) return;

    AppLogger.info(
        'Déclenchement manuel de la vérification du statut', 'ACHETER');

    setState(() => isLoading = true);

    try {
      final voucherPayment = await PaymentService.checkVoucherPaymentStatus(
        token: token!,
        reference: _currentPaymentReference!,
      );

      if (voucherPayment != null) {
        if (voucherPayment.isSucceeded) {
          _showSuccessToastAndReload();
        } else if (voucherPayment.isFailed ||
            (!voucherPayment.isProcessing && !voucherPayment.isSucceeded)) {
          // Corrected: Unified failure logic with polling
          _handlePaymentFailure();
        } else {
          // Paiement toujours en attente
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Paiement toujours en attente: ${voucherPayment.statusText}'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de vérifier le statut du paiement'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error(
          'Échec de la vérification manuelle du statut', 'ACHETER', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la vérification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasScheme &&
        (uri.isScheme("http") || uri.isScheme("https"));
  }

  void _onEventTypeSelected(EventType? eventType) {
    setState(() {
      selectedEventType = eventType;
    });
  }

  Future<void> _loadEventTypes() async {
    setState(() => isLoadingEventTypes = true);

    try {
      token = await UserService.getAuthToken();

      if (token != null) {
        // Charger depuis l'API
        final apiEventTypes =
            await EventTypeService.getActiveEventTypes(token: token!);

        // Convertir en EventTypeModel
        setState(() {
          eventTypes = apiEventTypes.map((et) {
            return EventType(
                id: et.id,
                nom: et.nom,
                libelle: et.libelle,
                icone: et.icone,
                image: et.image,
                actif: et.actif,
                createdAt: et.createdAt,
                updatedAt: et.updatedAt);
          }).toList();

          isLoadingEventTypes = false;
        });
      }
    } catch (e) {
      print('Erreur chargement événements: $e');
      setState(() => isLoadingEventTypes = false);
    }
  }

  void _checkFormValidity() {
    final isValid =
        _formKey.currentState != null && _formKey.currentState!.validate();

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2F55E0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // optionnel
      appBar: const CustomAppBar(
        title: "Acheter un Bon",
        showBackButton: true, // ou false si tu veux pas de retour
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            onChanged: () {
              // Vérifier la validité à chaque changement
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _checkFormValidity();
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Champ 1: Destinataire
                  ContactPickerWidget(
                    title: 'À qui sera envoyé ce bon',
                    phonePlaceholder: 'Ex: 07 XX XX XX XX',
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    phoneController: phoneController,
                    nameController: destinataireController,
                    // Rempli automatiquement
                    titleIcon: Icons.card_giftcard,
                    titleIconColor: Colors.blueAccent,
                    onContactSelected: (contact) {
                      // Action optionnelle
                      print('✅ Contact sélectionné: ${contact.name}');
                      print('📱 Téléphone: ${contact.phoneNumber}');
                    },
                    //  Vérification du nombre de chiffre dans le phone_number
                    validator: (value) {
                      if (value != null && value.length != 10) {
                        return 'Le numéro doit contenir 10 chiffres';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  /*Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomTextField(
                      label: 'Nom du destinataire',
                      placeholder: 'Entrez le nom du destinataire',
                      inputType: TextInputType.text,
                      controller: destinataireController,
                    ),
                  ),*/

                  const SizedBox(height: 16),

                  // Champ 2: Événement
                  EventTypeSelectorWidget(
                    title: 'Pour quel évènement ?',
                    label: 'Choisir l\'occasion',
                    placeholder: 'Sélectionner un événement',
                    noneOptionLabel: 'Aucune occasion',
                    eventTypes: eventTypes,
                    selectedEventType: selectedEventType,
                    onEventTypeSelected: _onEventTypeSelected,
                    titleIcon: Icons.celebration,
                    titleIconColor: Colors.blueAccent,
                    defaultEventColor: Colors.blue,
                    isLoading: isLoadingEventTypes,
                    isRequired: false,
                    // true si obligatoire
                    showSelectedIcon: true, // Afficher l'icône dans le champ
                  ),

                  const SizedBox(height: 16),

                  // Champ 3: Radio Notification
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomRadioGroup(
                      label: 'Être notifié(e) quand ce bon sera utilisé ?',
                      options: [
                        RadioOption(label: 'Oui', value: true),
                        RadioOption(label: 'Non', value: false),
                      ],
                      selectedValue: notificationValue,
                      onChanged: (value) {
                        setState(() {
                          notificationValue = value!;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Champ 4: Message personnalisé
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomTextField(
                      label: 'Votre message personnalisé (facultatif)',
                      placeholder: 'Tapez votre message ici',
                      inputType: TextInputType.multiline,
                      maxLines: 3,
                      controller: messageController,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Champ 5: Montant du bon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomTextField(
                      label: 'Saisissez le montant du bon en FCFA',
                      hint: 'Entre 5 000 et 500 000 FCFA',
                      placeholder: 'Ex : 20 000',
                      inputType: TextInputType.number,
                      controller: montantController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un montant';
                        }
                        int? montant = int.tryParse(value);
                        if (montant == null ||
                            montant < 5000 ||
                            montant > 500000) {
                          return 'Le montant doit être entre 5 000 et 500 000 FCFA';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Champ 6: Choix de la boutique
                  StoreSelectorWidget(
                    stores: boutiques,
                    selectedStore: selectedBoutique,
                    onStoreSelected: _selectBoutique,
                    defaultLogoUrl:
                        logobase, // Synchronisation de l'icône placeholder
                    placeholder: 'Dans toutes les boutiques',
                    primaryColor: Colors.black54,
                    showDescription: true,
                    isLoading: isLoading,
                    emptyMessage: 'Aucune boutique disponible pour le moment',
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(24),
                  ),

                  const SizedBox(height: 16),

                  // Champ 7: Moyen de paiement
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Moyen de paiement',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          /*decoration: BoxDecoration(
                            color: const Color(0xFF4A90E2).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF4A90E2),
                              width: 2,
                            ),
                          ),*/
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF4A90E2),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Image.asset(
                                "assets/images/nav-logo.png",
                                height: 100,
                                width: 100,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 12),
                              /*const Text(
                                'wave',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                              ),*/
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bouton de validation
                  if (_isFormValid) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _initiatePayment();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF4A90E2).withOpacity(0.3),
                        ),
                        child: const Text(
                          'Acheter avec wave',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tous les champs requis sont remplis ✓',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
