import 'package:flutter/material.dart';
import '../../data/services/boutique_service.dart';
import '../../data/services/voucher_service.dart';
import '../../data/services/payment_service.dart';
import '../../data/models/boutique_model.dart';
import '../../data/models/bon_achat_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/services/user_service.dart';
import '../../data/services/payment_wave_service.dart'; // <-- Ajouté
import '../../utils/logger.dart';
import '../home/home.dart';
import '../mes-bons/mes_bons.dart';
import '../profil/profil.dart';
import '../payment/payment_screen.dart';

// Cette page permet d'acheter des bons dans différentes boutiques
class AcheterBonPage extends StatefulWidget {
  const AcheterBonPage({super.key});

  @override
  State<AcheterBonPage> createState() => _AcheterBonPageState();
}

class _AcheterBonPageState extends State<AcheterBonPage>
    with SingleTickerProviderStateMixin {
  List<Boutique> boutiques = [];
  List<BonAchat> availableVouchers = [];
  String? selectedBoutiqueId;
  Map<int, int> quantites = {};
  Map<int, int> montants = {};
  final Map<String, Map<int, int>> bonsParBoutique = {};
  bool isLoading = false;
  String? token;

  int? selectedBonId;

  bool _showSuccess = false;
  late AnimationController _successController;
  late Animation<double> _successScale;

  // Ajout pour la barre de navigation
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    AppLogger.info('Initializing AcheterBonPage', 'ACHETER');
    _initializeData();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
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
    _successController.dispose();
    super.dispose();
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
        boutiques = list;
        isLoading = false;
      });
      AppLogger.info('Loaded ${list.length} boutiques successfully', 'ACHETER');
      AppLogger.debug(
          'Boutiques: ${list.map((b) => '${b.id}:${b.name}').join(', ')}',
          'ACHETER');
    } catch (e) {
      AppLogger.error('Failed to load boutiques: $e', 'ACHETER');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectBoutique(String boutiqueId) async {
    if (token == null) return;

    AppLogger.userAction('Selected boutique', data: {'boutiqueId': boutiqueId});

    try {
      setState(() {
        selectedBoutiqueId = boutiqueId;
        isLoading = true;
      });

      final vouchers = await VoucherService.getVouchersByBoutique(
        token: token!,
        boutiqueId: boutiqueId,
      );

      final availableVouchers = vouchers.toList();
      setState(() {
        this.availableVouchers = availableVouchers;
        quantites = {};
        isLoading = false;
        selectedBonId = null;
      });

      AppLogger.info(
          'Loaded ${availableVouchers.length} available vouchers for boutique $boutiqueId',
          'ACHETER');
      AppLogger.debug(
          'Available vouchers: ${availableVouchers.map((v) => '${v.id}:${v.montantBon}FCFA').join(', ')}',
          'ACHETER');
    } catch (e) {
      AppLogger.error(
          'Failed to load vouchers for boutique $boutiqueId', 'ACHETER', e);
      setState(() {
        availableVouchers = [];
        quantites = {};
        isLoading = false;
        selectedBonId = null;
      });
    }
  }

  Map<int, int> getQuantitesParId() {
    return Map<int, int>.from(quantites);
  }

  Map<int, int> getQuantitesTotales() {
    return Map<int, int>.from(quantites);
  }

  double getTotalMontant() {
    double total = 0;
    quantites.forEach((voucherId, quantity) {
      final voucher = availableVouchers.firstWhere(
        (v) => v.id == voucherId,
        orElse: () => BonAchat(
            id: 0,
            slug: '',
            libelle: '',
            montantBon: 0,
            boutiqueId: 0,
            status: 0,
            fraisFixe: 0,
            fraisEnPourcentage: 0),
      );
      if (voucher.id != 0) {
        total += voucher.calculateTotalCost(quantity);
      }
    });
    return total;
  }

  double getFrais() {
    double totalFees = 0;
    quantites.forEach((voucherId, quantity) {
      final voucher = availableVouchers.firstWhere(
        (v) => v.id == voucherId,
        orElse: () => BonAchat(
            id: 0,
            slug: '',
            libelle: '',
            montantBon: 0,
            boutiqueId: 0,
            status: 0,
            fraisFixe: 0,
            fraisEnPourcentage: 0),
      );
      if (voucher.id != 0) {
        totalFees += voucher.calculateFees(quantity);
      }
    });
    return totalFees;
  }

  // Nouvelle méthode pour initier le paiement Wave et ouvrir l'app Wave
  /*Future<void> _initierEtOuvrirPaiementWave() async {
    AppLogger.info('Démarrage du paiement Wave', 'ACHETER');
    try {
      setState(() {
        isLoading = true;
      });

      final List<Map<String, int>> bonsAchat = quantites.entries
          .map((entry) => {
                "id_bon_achat": entry.key,
                "quantite": entry.value,
              })
          .toList();

      final montantTotal = getTotalMontant().toInt();

      // Appel à l'API pour obtenir le lien Wave
      final response = await VoucherService.initierPaiementWave(
        bonsAchat,
        montantTotal,
        null,
      );

      final String? waveUrl = response["wave_launch_url"];

      setState(() {
        isLoading = false;
      });

      if (waveUrl != null) {
        // Utilisation du PaymentWaveService pour ouvrir l'app Wave
        await PaymentWaveService.launchWavePayment(
          context: context,
          waveLaunchUrl: waveUrl,
          montantTotal: montantTotal.toString(),
        );
        // Après retour, afficher un bouton pour valider le paiement
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Validation du paiement'),
              content: const Text(
                  "Après avoir effectué le paiement sur Wave, cliquez sur le bouton ci-dessous pour valider votre achat."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _validerPaiementDirect();
                  },
                  child: const Text("J'ai payé, valider"),
                ),
              ],
            );
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "Erreur lors de l'initiation du paiement Wave (lien manquant)")),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Erreur lors de l'initiation ou de l'ouverture du paiement Wave")),
        );
      }
    }
  }*/
  Future<void> _initierEtOuvrirPaiementWave() async {
    AppLogger.info('🛒 Démarrage du paiement Wave', 'ACHETER');
    try {
      setState(() => isLoading = true);

      // 1. Préparation des données avec logging détaillé
      AppLogger.info('📋 Preparing voucher data for payment', 'ACHETER');
      AppLogger.info('   • Raw quantities map: $quantites', 'ACHETER');
      
      final bonsAchat = quantites.entries
          .map((e) => {"id_bon_achat": e.key, "quantite": e.value})
          .toList();

      AppLogger.info('   • Prepared voucher list: $bonsAchat', 'ACHETER');

      final montantTotal = getTotalMontant().toInt();
      final totalFees = getFrais();
      
      AppLogger.info('💰 Payment calculation details:', 'ACHETER');
      AppLogger.info('   • Total amount: $montantTotal FCFA', 'ACHETER');
      AppLogger.info('   • Total fees: $totalFees FCFA', 'ACHETER');
      AppLogger.info('   • Selected boutique ID: $selectedBoutiqueId', 'ACHETER');
      AppLogger.info('   • Number of different vouchers: ${quantites.length}', 'ACHETER');
      
      // Log each voucher with its details
      AppLogger.info('🎫 Selected vouchers breakdown:', 'ACHETER');
      quantites.forEach((voucherId, quantity) {
        final voucher = availableVouchers.firstWhere(
          (v) => v.id == voucherId,
          orElse: () => BonAchat(
            id: 0, slug: '', libelle: 'Unknown', montantBon: 0, 
            boutiqueId: 0, status: 0, fraisFixe: 0, fraisEnPourcentage: 0
          ),
        );
        if (voucher.id != 0) {
          final totalCost = voucher.calculateTotalCost(quantity);
          AppLogger.info('   • Voucher ${voucher.id} (${voucher.libelle}): ${quantity}x ${voucher.montantBon}FCFA = ${totalCost}FCFA', 'ACHETER');
        }
      });

      // Validation avant appel API
      if (montantTotal <= 0) {
        throw Exception("Le montant total doit être supérieur à 0");
      }

      // 2. Appel API avec logging
      AppLogger.info('🚀 Calling VoucherService.initierPaiementWave...', 'ACHETER');
      final response = await VoucherService.initierPaiementWave(
        bonsAchat,
        montantTotal,
        null,
      );

      AppLogger.info('📥 Received response from API:', 'ACHETER');
      AppLogger.info('   • Response type: ${response.runtimeType}', 'ACHETER');
      AppLogger.info('   • Response keys: ${response.keys.toList()}', 'ACHETER');

      // 3. Vérification de la réponse
      // Correction : response est probablement un Map<String, dynamic>
      // On vérifie le code HTTP dans response['statusCode'] ou response['code'] selon l'API
      final int statusCode = response['statusCode'] ?? response['code'] ?? 200;
      if (statusCode < 200 || statusCode >= 300) {
        throw Exception("Erreur API (HTTP $statusCode)");
      }

      // Correction : response['data'] contient les données
      final responseData = response['data'] ?? {};
      final waveUrl = responseData['wave_launch_url'];
      //final montantPaiement =
      //responseData['data']?['paiement']?['montant_paiement'];
      final montantPaiement = responseData['paiement']?['montant_paiement'];
      print('montant de paiement du bon: $montantPaiement');

      // LOG pour debug : afficher le contenu de responseData et montantPaiement
      print('DEBUG: responseData = $responseData');
      print('DEBUG: montant_paiement (Wave) = $montantPaiement');

      AppLogger.debug('DEBUG: responseData = $responseData', 'ACHETER');
      AppLogger.debug(
          'DEBUG: montant_paiement (Wave) = $montantPaiement', 'ACHETER');

      // 4. Validation des données
      if (waveUrl == null || waveUrl.isEmpty) {
        throw Exception("URL Wave manquante dans la réponse");
      }

      if (montantPaiement == null || montantPaiement <= 0) {
        throw Exception(
            "Montant invalide dans l'URL Wave: $montantPaiement XOF");
      }

      // 5. Journalisation
      AppLogger.debug("URL Wave: $waveUrl");
      AppLogger.debug("Montant: $montantPaiement XOF");

      // 6. Lancement du paiement
      await PaymentWaveService.launchWavePayment(
        context: context,
        waveLaunchUrl: waveUrl,
        montantTotal: montantPaiement.toString(),
      );

      // 7. Confirmation post-paiement
      final shouldValidate = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('Validation du paiement'),
              content: const Text(
                  "Après avoir effectué le paiement sur Wave, confirmez-vous avoir payé ?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text("Oui, j'ai payé"),
                ),
              ],
            ),
          ) ??
          false;

      if (shouldValidate) {
        await _navigateToPaymentScreen(waveUrl, responseData);
      }
    } catch (e) {
      AppLogger.error("Erreur Wave: ${e.toString()}", 'ACHETER');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _validerPaiementDirect() async {
    AppLogger.info('Starting direct payment validation', 'ACHETER');
    AppLogger.debug('Payment quantities: $quantites', 'ACHETER');

    final List<Map<String, int>> bonsAchat = quantites.entries
        .map((entry) => {
              "id_bon_achat": entry.key,
              "quantite": entry.value,
            })
        .toList();

    final List<VoucherPurchase> purchases = quantites.entries
        .map((entry) => VoucherPurchase(
              voucherId: entry.key,
              quantity: entry.value,
            ))
        .toList();

    AppLogger.debug(
        'Prepared purchases: ${purchases.map((p) => '${p.voucherId}:${p.quantity}').join(', ')}',
        'ACHETER');
    AppLogger.debug('Total amount: ${getTotalMontant()} FCFA', 'ACHETER');
    AppLogger.debug('Total fees: ${getFrais()} FCFA', 'ACHETER');

    try {
      final response = await PaymentService.createPayment(
        token: token!,
        vouchers: purchases,
      );

      final success = response.success;

      if (success) {
        AppLogger.info('Payment successful', 'ACHETER');
        AppLogger.userAction(
          'Payment completed',
          data: {
            'total_amount': getTotalMontant(),
            'total_fees': getFrais(),
            'voucher_count': purchases.length,
            'boutique_id': selectedBoutiqueId,
          },
        );
        print("Quantités par id: ${getQuantitesParId()}");
        _showAnimatedSuccess();
      } else {
        AppLogger.error('Payment failed', 'ACHETER');
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Échec de l\'achat')));
        }
      }
    } catch (e) {
      AppLogger.error('Payment service error', 'ACHETER', e);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur lors du paiement')));
      }
    }
  }

  /// Navigate to dedicated PaymentScreen with deep link handling
  Future<void> _navigateToPaymentScreen(String waveUrl, Map<String, dynamic> paymentData) async {
    AppLogger.info('Navigating to PaymentScreen', 'ACHETER');
    
    final paymentReference = paymentData['paiement']?['reference'] ?? 'UNKNOWN';
    
    AppLogger.userAction('Payment screen navigation', data: {
      'reference': paymentReference,
      'amount': paymentData['paiement']?['montant_paiement'],
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          waveUrl: waveUrl,
          paymentReference: paymentReference,
          paymentData: paymentData['paiement'] ?? {},
        ),
      ),
    );
  }

  void _showAnimatedSuccess() async {
    AppLogger.debug('Showing animated success message', 'ACHETER');
    setState(() {
      _showSuccess = true;
    });
    _successController.forward(from: 0);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      _successController.reverse();
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() {
        _showSuccess = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (index == 1) {
      // On est déjà sur Acheter, rien à faire
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MesBonsPage()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfilPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quantitesTotales = getQuantitesTotales();
    final total = getTotalMontant();
    final frais = getFrais();
    final montantTotal = total;

    const Color titreBleu = Colors.blue;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text('Acheter un Bon'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Choix du supermarché / boutique - Card Design
                    Container(
                      margin: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '1. Choix du supermarché / boutique',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: titreBleu,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 16),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: boutiques.length,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                itemBuilder: (ctx, i) {
                                  final boutique = boutiques[i];
                                  final slug = boutique.slug;
                                  final name = boutique.name;
                                  final selected = slug == selectedBoutiqueId;
                                  return Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8),
                                    child: GestureDetector(
                                      onTap: () {
                                        if (selectedBoutiqueId != null) {
                                          bonsParBoutique[selectedBoutiqueId!] =
                                              Map<int, int>.from(quantites);
                                        }
                                        _selectBoutique(slug);
                                      },
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 200),
                                        curve: Curves.easeInOut,
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          gradient: selected
                                              ? LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Color(0xFF2F55E0),
                                                    Color(0xFF1E40AF),
                                                  ],
                                                )
                                              : null,
                                          color: selected ? null : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: selected
                                                ? Color(0xFF2F55E0)
                                                : Colors.grey.shade200,
                                            width: selected ? 2 : 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: selected
                                                  ? Color(0xFF2F55E0)
                                                      .withOpacity(0.3)
                                                  : Colors.grey
                                                      .withOpacity(0.1),
                                              spreadRadius: selected ? 2 : 1,
                                              blurRadius: selected ? 12 : 6,
                                              offset:
                                                  Offset(0, selected ? 4 : 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // Store icon
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: selected
                                                    ? Colors.white
                                                        .withOpacity(0.2)
                                                    : Color(0xFF2F55E0)
                                                        .withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.store_outlined,
                                                color: selected
                                                    ? Colors.white
                                                    : Color(0xFF2F55E0),
                                                size: 20,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            // Store name
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 4),
                                              child: Text(
                                                name,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: selected
                                                      ? Colors.white
                                                      : Color(0xFF1E293B),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                  letterSpacing: 0.3,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            // Selection indicator
                                            if (selected) ...[
                                              SizedBox(height: 4),
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Choix des Bons - Card Design
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '2. Choix des Bons',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: titreBleu,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 16),
                            if (availableVouchers.isEmpty)
                              Container(
                                height: 100,
                                alignment: Alignment.center,
                                child: Text(
                                  'Sélectionnez une boutique pour voir les bons disponibles',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else
                              GridView.count(
                                crossAxisCount: 3,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                childAspectRatio: 1.1,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                children: availableVouchers.map((voucher) {
                                  final qte = quantites[voucher.id] ?? 0;
                                  final isSelected = qte > 0;
                                  return GestureDetector(
                                    onTap: () => setState(() {
                                      quantites[voucher.id] = qte + 1;
                                    }),
                                    onLongPress: () => setState(() {
                                      if (qte > 0) {
                                        quantites[voucher.id] = qte - 1;
                                        if (quantites[voucher.id] == 0) {
                                          quantites.remove(voucher.id);
                                        }
                                      }
                                    }),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Color(0xFF2F55E0).withOpacity(0.1)
                                            : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? Color(0xFF2F55E0)
                                              : Colors.grey.shade300,
                                          width: isSelected ? 3 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${(voucher.montantBon / 1000).toStringAsFixed(0)}.000',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isSelected
                                                  ? Color(0xFF2F55E0)
                                                  : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            'FCFA',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 10,
                                              color: isSelected
                                                  ? Color(0xFF2F55E0)
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          // Quantity selector with +/- buttons
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              // Minus button
                                              GestureDetector(
                                                onTap: qte > 0
                                                    ? () => setState(() {
                                                          quantites[voucher
                                                              .id] = qte - 1;
                                                          if (quantites[
                                                                  voucher.id] ==
                                                              0) {
                                                            quantites.remove(
                                                                voucher.id);
                                                          }
                                                        })
                                                    : null,
                                                child: Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color: qte > 0
                                                        ? Color(0xFF2F55E0)
                                                        : Colors.grey.shade300,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Icon(
                                                    Icons.remove,
                                                    size: 16,
                                                    color: qte > 0
                                                        ? Colors.white
                                                        : Colors.grey.shade500,
                                                  ),
                                                ),
                                              ),
                                              // Quantity display
                                              Container(
                                                width: 32,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '$qte',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: isSelected
                                                        ? Color(0xFF2F55E0)
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              // Plus button
                                              GestureDetector(
                                                onTap: () => setState(() {
                                                  quantites[voucher.id] =
                                                      qte + 1;
                                                }),
                                                child: Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFF2F55E0),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Icon(
                                                    Icons.add,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Quantité des bons choisis - Card Design
                    if (quantites.isNotEmpty)
                      Container(
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '3. Quantité des bons choisis',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: titreBleu,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 16),
                              ...quantites.entries.map((e) {
                                final voucherId = e.key;
                                final qte = e.value;
                                final voucher = availableVouchers.firstWhere(
                                  (v) => v.id == voucherId,
                                  orElse: () => BonAchat(
                                      id: 0,
                                      slug: '',
                                      libelle: 'Unknown',
                                      montantBon: 0,
                                      boutiqueId: 0,
                                      status: 0,
                                      fraisFixe: 0,
                                      fraisEnPourcentage: 0),
                                );
                                final totalLigne =
                                    voucher.calculateTotalCost(qte);
                                return Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Bon ${(voucher.montantBon / 1000).toStringAsFixed(0)}.000 FCFA',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              'Quantité: $qte',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${totalLigne.toStringAsFixed(0)} FCFA',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2F55E0),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),

                    // Résumé du paiement - Card Design
                    Container(
                      margin: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  color: titreBleu,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Résumé du paiement',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: titreBleu,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            if (total > 0) ...[
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Sous-total',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '${(total - frais).toInt()} FCFA',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Frais de service',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '${frais.toInt()} FCFA',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Divider(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total à payer',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          '${montantTotal.toInt()} FCFA',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2F55E0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),
                            ],
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    (total > 0 && !isLoading && token != null)
                                        ? () async {
                                            print(quantites);
                                            // Rediriger vers l'application Wave si installée
                                            await _initierEtOuvrirPaiementWave();
                                          }
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF2F55E0),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: isLoading
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Traitement...',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.shopping_cart, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            total > 0
                                                ? 'Acheter maintenant'
                                                : 'Sélectionnez des bons',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_showSuccess)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              alignment: Alignment.center,
              child: ScaleTransition(
                scale: _successScale,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        "Bravo achat réussi avec succès!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
