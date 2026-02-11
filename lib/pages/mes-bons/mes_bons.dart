import 'package:ASSOU/pages/mes-bons/scanner_voucher/use_scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:ASSOU/utils/logger.dart';
import 'package:ASSOU/utils/price_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/environment.dart';
import '../../data/services/payment_service.dart';
import '../../data/services/voucher_service.dart';
import '../../data/models/bon_achat_model.dart';
import '../../data/services/user_service.dart';
import '../../data/models/user_model.dart';
import '../../widgets/custom_app_bar.dart';
import 'voucher_details_page.dart';

class MesBonsPage extends StatefulWidget {
  final bool showBottomNav;

  const MesBonsPage({super.key, this.showBottomNav = true});

  @override
  State<MesBonsPage> createState() => _MesBonsPageState();
}

class _MesBonsPageState extends State<MesBonsPage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  int _selectedFilter = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  final int _perPage = 50;
  final ScrollController _scrollController = ScrollController();

  // Separate pagination state for each tab
  final Map<int, int> _tabPages = {0: 1, 1: 1, 2: 1};
  final Map<int, bool> _tabHasMore = {0: true, 1: true, 2: true};

  final List<String> _filters = ["Utilisables", "Utilisés", "Envoyés"];

  // Listes pour stocker les données de chaque onglet
  List<PaiementBon> _bonsUtilisables = [];
  List<PaiementBon> _bonsUtilises = [];
  List<PaiementBon> _bonsEnvoyes = [];

  final PaymentService paymentService = PaymentService();
  bool isLoadingRelance = false;

  // Current user for receiver-aware status checking
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _initPage();
  }

  Future<void> _initPage() async {
    await _loadCurrentUser();
    if (mounted) {
      _clearAllDataAndRefresh();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await UserService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load current user', 'MES_BONS_PAGE', e);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _clearAllDataAndRefresh();
    }
  }

  @override
  bool get wantKeepAlive => false;

  void _clearAllDataAndRefresh() {
    if (mounted) {
      setState(() {
        _bonsUtilisables.clear();
        _bonsUtilises.clear();
        _bonsEnvoyes.clear();
        _selectedFilter = 0;
        _isLoading = false;
        _isLoadingMore = false;
        // Reset pagination for all tabs
        _tabPages[0] = 1;
        _tabPages[1] = 1;
        _tabPages[2] = 1;
        _tabHasMore[0] = true;
        _tabHasMore[1] = true;
        _tabHasMore[2] = true;
      });
      _rafraichirDonnees();
    }
  }

  Future<void> _chargerDonnees() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final token = await UserService.getAuthToken();
      if (token == null) {
        throw Exception('Token d\'authentification non trouvé');
      }

      // Charger les bons utilisables (actifs + reçus actifs)
      final bonsActifs = await VoucherService.getMyActiveVouchers(token,
          page: 1, perPage: _perPage);
      final bonsRecus = await VoucherService.getMyReceivedVouchers(token,
          page: 1, perPage: _perPage);

      // Combiner et dédupliquer
      final utilisables = <PaiementBon>[];
      final seenIds = <int>{};

      for (final bon in [...bonsActifs, ...bonsRecus]) {
        if (!seenIds.contains(bon.id) &&
            !bon.isExpired &&
            bon.dateAchat != null && // 🔥 Only show paid vouchers
            bon.isActiveForUser(_currentUser?.id) &&
            (bon.receiverId == _currentUser?.id || bon.receiverId == null)) {
          utilisables.add(bon);
          seenIds.add(bon.id);
        }
      }

      if (mounted) {
        setState(() {
          _bonsUtilisables = utilisables;
          _tabHasMore[0] = utilisables.length >= _perPage;
          _tabPages[0] = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print("Erreur chargement données: $e");
    }
  }

  Future<void> _chargerBonsUtilises() async {
    if (_bonsUtilises.isNotEmpty) return;
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final token = await UserService.getAuthToken();
      if (token == null) throw Exception('Token non trouvé');

      final tousBons =
          await VoucherService.getMyVouchers(token, page: 1, perPage: _perPage);
      final utilises = tousBons.where((bon) {
        return bon.dateAchat != null && // 🔥 Only show paid vouchers
            bon.isUtiliseForUser(_currentUser?.id) &&
            (bon.receiverId == _currentUser?.id || bon.receiverId == null);
      }).toList();

      if (mounted) {
        setState(() {
          _bonsUtilises = utilises;
          _tabHasMore[1] = utilises.length >= _perPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print("Erreur chargement bons utilisés: $e");
    }
  }

  Future<void> _chargerBonsEnvoyes() async {
    if (_bonsEnvoyes.isNotEmpty) return;
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final token = await UserService.getAuthToken();
      if (token == null) throw Exception('Token non trouvé');

      final bonsEnvoyesExplicit = await VoucherService.getMySentVouchers(token,
          page: 1, perPage: _perPage);
      final bonsActifs = await VoucherService.getMyActiveVouchers(token,
          page: 1, perPage: _perPage);

      // Combiner et filtrer : l'utilisateur doit être l'expéditeur et il doit y avoir un autre destinataire
      final envoyes = <PaiementBon>[];
      final seenIds = <int>{};

      for (final bon in [...bonsEnvoyesExplicit, ...bonsActifs]) {
        if (!seenIds.contains(bon.id) &&
            bon.dateAchat != null && // 🔥 Only show paid vouchers
            bon.senderId == _currentUser?.id &&
            bon.receiverId != _currentUser?.id &&
            bon.receiverId != null) {
          envoyes.add(bon);
          seenIds.add(bon.id);
        }
      }

      if (mounted) {
        setState(() {
          _bonsEnvoyes = envoyes;
          _tabHasMore[2] = envoyes.length >= _perPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print("Erreur chargement bons envoyés: $e");
    }
  }

  Future<void> _rafraichirDonnees() async {
    // Clear all data
    _bonsUtilisables.clear();
    _bonsUtilises.clear();
    _bonsEnvoyes.clear();

    // Reset pagination
    for (int i = 0; i < _tabPages.length; i++) {
      _tabPages[i] = 1;
      _tabHasMore[i] = true;
    }

    // Load initial data
    await _chargerDonnees();

    // Refresh current tab if not "Utilisables"
    if (_selectedFilter != 0) {
      try {
        final token = await UserService.getAuthToken();
        if (token != null) {
          switch (_selectedFilter) {
            case 1: // Utilisés
              await _chargerBonsUtilises();
              break;
            case 2: // Envoyés
              await _chargerBonsEnvoyes();
              break;
          }
        }
      } catch (e) {
        AppLogger.error('Failed to refresh current tab data', 'MES_BONS', e);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        (_tabHasMore[_selectedFilter] ?? false)) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !(_tabHasMore[_selectedFilter] ?? false)) return;

    final currentTabPage = _tabPages[_selectedFilter]! + 1;

    if (mounted) {
      setState(() {
        _isLoadingMore = true;
        _tabPages[_selectedFilter] = currentTabPage;
      });
    }

    try {
      final token = await UserService.getAuthToken();
      if (token == null) {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
            _tabPages[_selectedFilter] = currentTabPage - 1;
          });
        }
        return;
      }

      List<PaiementBon> newVouchers = [];

      switch (_selectedFilter) {
        case 0: // Utilisables
          final actifs = await VoucherService.getMyActiveVouchers(token,
              page: currentTabPage, perPage: _perPage);
          final recus = await VoucherService.getMyReceivedVouchers(token,
              page: currentTabPage, perPage: _perPage);

          final seenIds = _bonsUtilisables.map((b) => b.id).toSet();
          for (final bon in [...actifs, ...recus]) {
            if (!seenIds.contains(bon.id) &&
                !bon.isExpired &&
                bon.isActiveForUser(_currentUser?.id) &&
                (bon.receiverId == _currentUser?.id ||
                    bon.receiverId == null)) {
              newVouchers.add(bon);
            }
          }
          break;
        case 1: // Utilisés
          final tous = await VoucherService.getMyVouchers(token,
              page: currentTabPage, perPage: _perPage);
          newVouchers = tous.where((bon) {
            return bon.dateAchat != null && // 🔥 Only show paid vouchers
                bon.isUtiliseForUser(_currentUser?.id) &&
                (bon.receiverId == _currentUser?.id || bon.receiverId == null);
          }).toList();
          break;
        case 2: // Envoyés
          final explicitEnvoyes = await VoucherService.getMySentVouchers(token,
              page: currentTabPage, perPage: _perPage);
          final actifsEnvoyes = await VoucherService.getMyActiveVouchers(token,
              page: currentTabPage, perPage: _perPage);

          final currentIds = _bonsEnvoyes.map((b) => b.id).toSet();
          for (final bon in [...explicitEnvoyes, ...actifsEnvoyes]) {
            if (!currentIds.contains(bon.id) &&
                bon.dateAchat != null && // 🔥 Only show paid vouchers
                bon.senderId == _currentUser?.id &&
                bon.receiverId != _currentUser?.id &&
                bon.receiverId != null) {
              newVouchers.add(bon);
              currentIds.add(bon.id);
            }
          }
          break;
      }

      if (mounted) {
        setState(() {
          if (newVouchers.length < _perPage) {
            _tabHasMore[_selectedFilter] = false;
          }

          switch (_selectedFilter) {
            case 0:
              _bonsUtilisables.addAll(newVouchers);
              break;
            case 1:
              _bonsUtilises.addAll(newVouchers);
              break;
            case 2:
              _bonsEnvoyes.addAll(newVouchers);
              break;
          }

          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _tabPages[_selectedFilter] = currentTabPage - 1;
        });
      }
      print("Erreur load more: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: "Mes Bons",
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: _rafraichirDonnees,
        child: CustomScrollView(
          controller: _scrollController,
          physics: (_isLoading || _filters.isEmpty)
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Nouvelle barre d'onglets style tabs
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: Row(
                  children: List.generate(_filters.length, (index) {
                    return Expanded(
                      child: _buildFilterTab(
                          _filters[index], _selectedFilter == index, index),
                    );
                  }),
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: true,
              child: _isLoading ? _buildLoadingWidget() : _buildFilterContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildFilterTab(String label, bool isSelected, int index) {
    return GestureDetector(
      onTap: () async {
        if (index == _selectedFilter) return;

        if (mounted) {
          setState(() {
            _selectedFilter = index;
            _isLoading = true;
          });
        }

        // Reset scroll position
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }

        // Load data for selected tab
        try {
          final token = await UserService.getAuthToken();
          if (token == null) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            return;
          }

          switch (index) {
            case 0: // Utilisables
              if (_bonsUtilisables.isEmpty) {
                await _chargerDonnees();
              } else {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
              break;
            case 1: // Utilisés
              if (_bonsUtilises.isEmpty) {
                await _chargerBonsUtilises();
              } else {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
              break;
            case 2: // Envoyés
              if (_bonsEnvoyes.isEmpty) {
                await _chargerBonsEnvoyes();
              } else {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
              break;
          }
        } catch (e) {
          print('Erreur changement onglet: $e');
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterContent() {
    List<PaiementBon> bonsAfficher = [];
    String messageVide = "";

    switch (_selectedFilter) {
      case 0:
        bonsAfficher = _bonsUtilisables;
        messageVide = "Aucun bon utilisable pour le moment.";
        break;
      case 1:
        bonsAfficher = _bonsUtilises;
        messageVide = "Aucun bon utilisé pour le moment.";
        break;
      case 2:
        bonsAfficher = _bonsEnvoyes;
        messageVide = "Aucun bon envoyé pour le moment.";
        break;
    }

    if (bonsAfficher.isEmpty) {
      return Center(
        child: Text(
          messageVide,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...bonsAfficher.map((paiementBon) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: _buildVoucherCard(paiementBon),
            );
          }).toList(),
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(PaiementBon paiementBon) {
    final bon = paiementBon.bon;

    // Use data from BonAchat if available, otherwise fallback to PaiementBon direct fields
    final double amount = bon?.montantBon ?? paiementBon.montantBon;
    final String montant = PriceUtils.formatPrice(amount);

    final bool isUniversal =
        paiementBon.isUniversal || (bon?.isUniversal ?? false);

    final String boutiqueLabel = isUniversal
        ? "Assou"
        : "${bon?.boutique?.name ?? paiementBon.boutique?.name ?? 'Boutique'}";
    final String utilisationText =
        isUniversal ? "Toutes les boutiques" : boutiqueLabel;

    // Transfer Logic: Determine if this is a gift received or a gift sent
    final bool isSentByMe = paiementBon.senderId == _currentUser?.id;
    final bool isReceivedByMe = paiementBon.receiverId == _currentUser?.id;

    // Name Sources
    final String? donorName = paiementBon.donateur?.fullName;
    final String? recipientName =
        paiementBon.receiver?.fullName ?? paiementBon.destinataireName;

    // Label Logic
    String? transferLabel;
    if (isReceivedByMe &&
        donorName != null &&
        donorName != _currentUser?.fullName) {
      //transferLabel = "De: $donorName";
    } else if (isSentByMe && recipientName != null) {
      //transferLabel = "À: $recipientName";
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Icon + Shop Name (Aligned vertically as per mockup)
          Column(
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Builder(
                    builder: (context) {
                      // MODIFICATION (09/02/2026): Utilisation du logo local Assou pour les bons universels
                      // On garde la logique originale en commentaire au cas où on voudrait repasser par une URL distante/DB
                      /*
                      final logoUrl = isUniversal
                          ? "https://res.cloudinary.com/dmlozs3uk/image/upload/v1758204981/istockphoto-1174549062-612x612_ajteum.jpg"
                          : (bon?.boutiqueLogoUrl ?? paiementBon.boutique?.logoUrl);
                      */
                      final logoUrl = isUniversal
                          ? "assets/images/mesbons.png"
                          : (bon?.boutiqueLogoUrl ??
                              paiementBon.boutique?.logoUrl);
                      final eventImageUrl =
                          bon?.fullImageUrl ?? paiementBon.event?.imageUrl;

                      return _buildVoucherImage(
                        boutiqueLogoUrl: logoUrl,
                        fallbackIcon: paiementBon.event?.iconData,
                        isCircular: false,
                        width: 65,
                        height: 65,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 70,
                child: Text(
                  boutiqueLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),

          // Right: Content + Buttons Row
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PriceUtils.formatPrice(amount, showCurrency: true),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'Nunito',
                        color: Color(0xFF666666),
                      ),
                      children: [
                        const TextSpan(text: "Utilisation de ce bon : "),
                        TextSpan(
                          text: utilisationText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (transferLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      transferLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Nunito',
                        color: isSentByMe
                            ? Colors.blue.shade800
                            : Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Buttons Row
                Row(
                  children: [
                    if (_selectedFilter == 0 &&
                        paiementBon.isActiveForUser(_currentUser?.id))
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () => _utiliserCeBonNouveau(
                              context,
                              PriceUtils.formatPrice(amount),
                              utilisationText,
                              bonId: paiementBon.id,
                              paiementBon: paiementBon,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3380fe),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                            child: const Text("Utiliser",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ),
                    if (_selectedFilter == 0 &&
                        paiementBon.isActiveForUser(_currentUser?.id))
                      const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VoucherDetailsPage(
                                  description:
                                      bon?.libelle ?? "Bon d'achat Assou",
                                  imageUrl: bon?.fullImageUrl ??
                                      paiementBon.event?.imageUrl,
                                  recipientName:
                                      paiementBon.donateur?.fullName ??
                                          paiementBon.destinataireName,
                                  recipientPhone:
                                      paiementBon.donateur?.phoneNumber ??
                                          paiementBon.recipientPhone,
                                  partnerName: paiementBon.receiver?.fullName,
                                  partnerPhone:
                                      paiementBon.receiver?.phoneNumber,
                                  boutiqueName: isUniversal
                                      ? "Toutes les boutiques"
                                      : (bon?.boutique?.name ??
                                          paiementBon.boutique?.name ??
                                          "Boutique"),
                                  // MODIFICATION: Logo local pour 'Toutes les boutiques'
                                  // URL distante mise en commentaire pour maintenance
                                  /*
                                  boutiqueLogoUrl: isUniversal
                                      ? "https://res.cloudinary.com/dmlozs3uk/image/upload/v1758204981/istockphoto-1174549062-612x612_ajteum.jpg"
                                      : (bon?.boutiqueLogoUrl ?? paiementBon.boutique?.logoUrl),
                                  */
                                  boutiqueLogoUrl: isUniversal
                                      ? "assets/images/mesbons.png"
                                      : (bon?.boutiqueLogoUrl ??
                                          paiementBon.boutique?.logoUrl),
                                  eventIcon: paiementBon.event?.iconData,
                                  donatorName: donorName ?? recipientName,
                                  userId: _currentUser?.id,
                                  usersId: paiementBon.userId,
                                  senderId: paiementBon.senderId,
                                  codeBon: paiementBon.codeBon,
                                  montantBon: amount,
                                  etatReceiver: paiementBon.etatReceiver,
                                  etat: paiementBon.etat,
                                  personal_message:
                                      paiementBon.personal_message,
                                  dateExpire: paiementBon.dateExpire,
                                  dateUsage: paiementBon.dateUsage,
                                  dateAchat: paiementBon.dateAchat,
                                  dateExpiration: paiementBon.dateExpiration,
                                  joursAvantExpiration:
                                      paiementBon.joursAvantExpiration,
                                  joursDepuisExpiration:
                                      paiementBon.joursDepuisExpiration,
                                  currentTab: _selectedFilter,
                                  hasThanked: paiementBon.has_thanked,
                                  paiementBonId: paiementBon.id,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3380fe),
                            side: const BorderSide(
                                color: Color(0xFF3380fe), width: 1),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                          child: const Text("Détails",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherImage({
    String? boutiqueLogoUrl,
    IconData? fallbackIcon,
    bool isCircular = true,
    double? width,
    double? height,
  }) {
    String? imageToDisplay;

    // Only use boutique logo, do NOT use event images as fallback
    if (boutiqueLogoUrl != null && boutiqueLogoUrl.isNotEmpty) {
      if (!boutiqueLogoUrl.contains('test_path')) {
        imageToDisplay = boutiqueLogoUrl;
      }
    }

    final double finalWidth = width ?? 64;
    final double finalHeight = height ?? 64;

    Widget buildFallback() {
      return Container(
        width: finalWidth,
        height: finalHeight,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isCircular ? finalWidth / 2 : 0),
        ),
        child: Icon(
          fallbackIcon ?? Icons.card_giftcard,
          color: Colors.white,
          size: 32,
        ),
      );
    }

    if (imageToDisplay != null) {
      // MODIFICATION: Prise en charge des assets locaux (ex: logo Assou)
      if (imageToDisplay.startsWith("assets/")) {
        final imageWidget = Image.asset(
          imageToDisplay,
          width: finalWidth,
          height: finalHeight,
          fit: BoxFit.contain, // Contain pour éviter de couper le logo Assou
          errorBuilder: (context, error, stackTrace) => buildFallback(),
        );
        return isCircular ? ClipOval(child: imageWidget) : imageWidget;
      }

      final imageWidget = Image.network(
        Environment.getImageUrl(imageToDisplay) ?? "",
        width: finalWidth,
        height: finalHeight,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => buildFallback(),
      );
      return isCircular ? ClipOval(child: imageWidget) : imageWidget;
    }

    return buildFallback();
  }

  Future<void> _utiliserCeBonNouveau(
    BuildContext context,
    String montant,
    String magasin, {
    int? bonId,
    PaiementBon? paiementBon,
  }) async {
    if (paiementBon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur : Données du bon manquantes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (paiementBon.isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ce bon a expiré'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UseScannerPage(idPaiementBon: paiementBon.id.toString()),
      ),
    );

    if (mounted) {
      _rafraichirDonnees();
    }
  }

  Future<void> _launchWaveUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception("Impossible d'ouvrir l'URL: $url");
    }
  }

  Future<void> _relancerPaiement(
      BuildContext context, PaiementBon paiementBon) async {
    if (mounted) {
      setState(() => isLoadingRelance = true);
    }

    try {
      String? token = await UserService.getAuthToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vous devez être connecté")),
        );
        return;
      }

      final response = await paymentService.relanceBon(
        token: token,
        bonId: paiementBon.id,
      );

      if (response.success && response.data != null) {
        final payment = response.data!;
        final url = payment.waveLaunchUrl;

        if (url != null) {
          await _launchWaveUrl(url);
          await PaymentService.checkVoucherPaymentStatusRelance(
            token: token,
            reference: payment.paiement.reference,
            context: context,
          );
        }
      }
    } catch (e) {
      print("Erreur relance paiement: $e");
    } finally {
      if (mounted) {
        setState(() => isLoadingRelance = false);
      }
    }
  }
}
