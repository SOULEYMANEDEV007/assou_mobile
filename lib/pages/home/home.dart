import 'package:ASSOU/pages/recompenses/recompense.dart';
import 'package:ASSOU/widgets/toast_helper.dart';
import '../../config/environment.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:ASSOU/data/models/bon_achat_model.dart';
import 'package:ASSOU/data/models/expired_bon.dart';
import 'package:ASSOU/data/services/voucher_service.dart';
import 'package:ASSOU/pages/mes-bons/mes_bons.dart';
import 'package:ASSOU/pages/acheter/acheter.dart';
import 'package:ASSOU/pages/profil/enhanced_profil.dart';
import 'package:ASSOU/utils/logger.dart';
import 'package:ASSOU/utils/price_utils.dart';
import '../../services/inactivity_service.dart';
import '../../data/models/user_model.dart';
import '../../data/services/user_service.dart';
import '../../data/services/home_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:async';

import '../Register/pin_login_screen.dart';
import '../feature/notification/page/notification_page.dart';
import 'package:ASSOU/pages/feature/notification/service/notification_service.dart'
    show NotificationService;
import 'package:ASSOU/data/services/notification_service.dart' as api;
import 'package:ASSOU/data/services/banner_ad_service.dart';

// Popup pour demander l'autorisation d'accès aux contacts
Future<bool?> showContactPermissionDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Accès aux contacts",
          style: TextStyle(fontFamily: 'Nunito')),
      content: const Text(
          "Autorisez-vous l'application à accéder à vos contacts pour envoyer un bon ?",
          style: TextStyle(fontFamily: 'Nunito')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Refuser", style: TextStyle(fontFamily: 'Nunito')),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child:
              const Text("Autoriser", style: TextStyle(fontFamily: 'Nunito')),
        ),
      ],
    ),
  );
}

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  final bool showBottomNav;

  const HomePage({super.key, this.arguments, this.showBottomNav = true});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int _selectedIndex = 0;
  User? _currentUser;
  bool _isLoading = true;
  List<Map<String, dynamic>> _carouselImages = [];
  int _currentCarouselIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  NotificationService notificationService = NotificationService();

  // Home data
  Map<String, dynamic>? _accueilData;
  List<dynamic>? _bonsActifs;
  List<ExpiredBon>? _bonsExpires;

  // Auto-refresh timer
  Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(minutes: 60);

  @override
  void initState() {
    super.initState();

    InactivityService().startTracking(() {
      if (!mounted) return;
      ToastHelper.showToast(
        context,
        title: "Déconnexion utilisateur",
        message: "Reconnectez-vous !",
        type: ToastType.success,
      );

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        UserService.logout();

        Navigator.of(context, rootNavigator: true)
            .popUntil((route) => route.isFirst);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PinLoginScreen()),
        );
      });
    });

    _loadUserData();
    _loadAccueilData();
    _loadCarouselData(); // Charger les données du carousel
    _startAutoRefresh();
    _checkAndHandleRefreshArguments();
  }

  // Méthode pour charger les données du carousel
  Future<void> _loadCarouselData() async {
    try {
      AppLogger.info('Loading dynamic carousel data', 'HOME_UI');

      final banners = await BannerAdService.getActiveBanners();

      if (mounted) {
        setState(() {
          if (banners.isNotEmpty) {
            _carouselImages = banners
                .map((b) => {
                      'id': b.id, // For tracking
                      'image_url': b.image,
                      'title': b.title,
                      'subtitle': b.subtitle,
                      'link': b.link,
                      'type': b.link != null && b.link!.isNotEmpty
                          ? 'external'
                          : 'none',
                    })
                .toList();
          } else {
            _carouselImages = [];
          }
        });

        // Track impressions for loaded banners
        for (var banner in banners) {
          BannerAdService.trackImpression(banner.id);
        }
      }
    } catch (e) {
      AppLogger.error('Failed to load dynamic carousel data', 'HOME_UI', e);
    }
  }

  void _checkAndHandleRefreshArguments() {
    final arguments = widget.arguments;
    if (arguments != null && arguments['shouldRefresh'] == true) {
      AppLogger.info(
          'Refresh flag detected in HomePage arguments, refreshing data',
          'HOME_REFRESH');
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _loadAccueilData();
          _loadCarouselData();
        }
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted && _selectedIndex == 0) {
        _loadAccueilData();
        _loadCarouselData();
      }
    });
  }

  Future<List<PaiementBon>> _getActiveVouchersFromAPI(String token) async {
    try {
      AppLogger.info(
          'Loading active vouchers from myActiveVouchers API', 'HOME_API');
      return await VoucherService.getMyActiveVouchers(token,
          page: 1, perPage: 50);
    } catch (e) {
      AppLogger.error('Failed to get active vouchers from API', 'HOME_API', e);
      return [];
    }
  }

  Future<List<ExpiredBon>> _getExpiringSoonVouchersFromAPI(String token) async {
    try {
      AppLogger.info(
          'Loading expiring vouchers from myExpiringSoonVouchers API',
          'HOME_API');
      return await VoucherService.getMyExpiringVouchers(token);
    } catch (e) {
      AppLogger.error(
          'Failed to get expiring vouchers from API', 'HOME_API', e);
      return [];
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      AppLogger.info('Loading notification count...', 'NOTIFICATION_COUNT');
      final token = await UserService.getAuthToken();
      if (token == null) {
        AppLogger.warning(
            'No auth token found for notification count', 'NOTIFICATION_COUNT');
        NotificationService.notificationCount.value = 0;
        return;
      }

      final count = await api.NotificationService.getUnreadCount(token: token);
      AppLogger.info('Notification count loaded: $count', 'NOTIFICATION_COUNT');
      NotificationService.notificationCount.value = count;
    } catch (e) {
      AppLogger.error('Failed to load notification count', 'HOME_DATA', e);
      // Keep the current value instead of resetting to 0
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = await UserService.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des données utilisateur: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAccueilData() async {
    try {
      final token = await UserService.getAuthToken();
      if (token == null) {
        throw Exception('Token d\'authentification non trouvé');
      }

      final results = await Future.wait([
        HomeService.getAccueilData(),
        _getActiveVouchersFromAPI(token),
        _getExpiringSoonVouchersFromAPI(token),
        _loadNotificationCount(),
      ]);

      if (mounted) {
        setState(() {
          final accueilResult = results[0] as Map<String, dynamic>;
          if (accueilResult['success']) {
            _accueilData = accueilResult['data'];
          }

          final activeVouchersList = results[1] as List<PaiementBon>;
          _bonsActifs = activeVouchersList.map((voucher) {
            return {
              'id': voucher.id,
              'slug': voucher.slug,
              'montant_bon': voucher.montantBon,
              'boutique': {
                'name': voucher.boutique?.name ??
                    voucher.bon?.boutique?.name ??
                    'Boutique inconnue',
                'logo': voucher.boutique?.logo ?? voucher.bon?.boutique?.logo,
                'slug': voucher.boutique?.slug ?? voucher.bon?.boutique?.slug,
              },
              'bon_achat': {
                'libelle': voucher.bon?.libelle ?? 'Bon inconnu',
                'montant_bon': voucher.bon?.montantBon ?? voucher.montantBon,
                'boutique': {
                  'name': voucher.bon?.boutique?.name ?? 'Boutique inconnue',
                  'slug': voucher.bon?.boutique?.slug,
                },
              },
              'date_expire': voucher.dateExpire?.toIso8601String(),
              'etat': voucher.etat,
            };
          }).toList();
          AppLogger.info(
              'Loaded ${_bonsActifs?.length ?? 0} active vouchers from API',
              'HOME_DATA');

          final expiringVouchersList = results[2] as List<ExpiredBon>;
          _bonsExpires = expiringVouchersList;
        });
      }
    } catch (e) {
      AppLogger.error(
          'Erreur lors du chargement des données d\'accueil', 'HOME_DATA', e);
    }
  }

  Future<void> _handleRefresh() async {
    AppLogger.info('Manual pull-to-refresh triggered', 'HOME_REFRESH');
    await Future.wait([
      _loadUserData(),
      _loadAccueilData(),
      _loadCarouselData(),
      _loadNotificationCount(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF3380fe),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: const Color(0xFF3380fe),
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeContent(),
              const AcheterBonPage(showBottomNav: false),
              const MesBonsPage(showBottomNav: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Stack(
      children: [
        // Layer 1: Background
        Column(
          children: [
            // Top Blue Section
            Container(
              height: 175, // Hauteur ajustée pour couper au milieu de la carte
              color: const Color(0xFF3380fe),
            ),
            // Bottom White Section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Layer 2: Main Content Flow
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header Row (Welcome + Icons)
              _buildHeaderTopRow(),

              // Spacer for the Account Card overlap
              const SizedBox(height: 260),

              // Content area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Quick Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildQuickActionsRow(),
                    ),
                    const SizedBox(height: 20),

                    // Carousel
                    if (_carouselImages.isNotEmpty)
                      _buildCarouselSlider()
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          width: double.infinity,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              "Aucune promotion disponible",
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),

                    // Logo & Footer
                    Image.asset(
                      "assets/images/logo_assou.png",
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    const Text(
                      "Un produit KOSEH GROUP",
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Layer 3: Account Card (Centered & Overlapping)
        Positioned(
          top: 100, // Ajuster pour chevaucher
          left: 40, // Reduced width (increased margin)
          right: 40,
          child: _buildAccountCard(),
        ),

        // Layer 4: Help Button (Bottom Right)
        Positioned(
          bottom:
              70, // Remonté pour être en face du logo (Logo height ~100 + text, bottom offset approx)
          right: 20,
          child: GestureDetector(
            onTap: () async {
              try {
                const url = 'https://assou.app/#FAQ';
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
              } catch (e) {
                ToastHelper.showToast(context,
                    title: "Erreur",
                    message: "Impossible d'ouvrir le lien d'aide",
                    type: ToastType.error);
              }
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.question_mark_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderTopRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _currentUser != null && _currentUser!.firstName.isNotEmpty
                  ? 'Bienvenue ${_currentUser!.firstName}'
                  : "Bienvenue Chez Assou",
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              // Notification bell
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NotificationPage()));
                },
                child: Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications,
                        color: Color(0xFF3B82F6),
                        size: 22,
                      ),
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: NotificationService.notificationCount,
                      builder: (context, count, _) {
                        return Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Profile icon
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EnhancedProfilPage()));
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF3B82F6),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard() {
    final activeCount = _bonsActifs?.length ?? 0;

    double totalAmountValue = 0.0;
    if (_bonsActifs != null && _bonsActifs!.isNotEmpty) {
      for (var voucher in _bonsActifs!) {
        if (voucher is Map<String, dynamic>) {
          final amount = voucher['montant_bon'] ??
              voucher['montant_bon'] ??
              voucher['amount'] ??
              voucher['bon']?['montant_bon'] ??
              voucher['bon_achat']?['montant_bon'] ??
              0;
          if (amount is num) {
            totalAmountValue += amount.toDouble();
          } else if (amount is String) {
            totalAmountValue += double.tryParse(amount) ?? 0.0;
          }
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
          0), // Retirer le padding global pour que le trait touche les bords
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5a99ff),
            Color(0xFF5a99ff),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          // Bordure blanche ajoutée
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 16),
            child: const Text(
              "VOTRE COMPTE",
              style: TextStyle(
                fontFamily: 'Nunito',
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          Container(
            // Ligne de séparation blanche
            width: double.infinity, // Prend toute la largeur
            height: 1.5, // Épaisseur du trait
            color: Colors.white, // Couleur blanche
            margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 30), // Increased height for bottom section
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$activeCount bon(s) utilisable(s)',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  PriceUtils.formatPrice(totalAmountValue),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Nouvelle méthode pour le carousel slider
  Widget _buildCarouselSlider() {
    return Column(
      children: [
        CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: 160.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: true,
            enlargeFactor: 0.2,
            viewportFraction: 0.9,
            aspectRatio: 2.0,
            onPageChanged: (index, reason) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
          ),
          items: _carouselImages.map((item) {
            return Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () async {
                    _onCarouselItemTap(item);
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Image principale
                          if (item['image_url'] != null)
                            Image.network(
                              Environment.getImageUrl(item['image_url'])!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),

                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.5),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          // Texte sur l'image
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (item['title'] != null)
                                  Text(
                                    item['title'],
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 4,
                                          color: Colors.black54,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (item['subtitle'] != null)
                                  Text(
                                    item['subtitle'],
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 4,
                                          color: Colors.black54,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 12),

        // Indicateurs de page
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _carouselImages.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _carouselController.animateToPage(entry.key),
              child: Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentCarouselIndex == entry.key
                      ? const Color(0xFF2196F3)
                      : Colors.grey[300],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Méthode pour gérer le tap sur un élément du carousel
  void _onCarouselItemTap(Map<String, dynamic> item) async {
    try {
      final id = item['id'];
      if (id != null) {
        BannerAdService.trackClick(id); // Suivi du clic
      }

      final link = item['link'];
      final type = item['type'] ?? 'external'; // 'external', 'internal', 'none'

      if (link != null && link.isNotEmpty) {
        if (type == 'external') {
          try {
            final Uri uri = Uri.parse(link);
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            ToastHelper.showToast(context,
                title: "Erreur",
                message: "Impossible d'ouvrir le lien",
                type: ToastType.error);
          }
        } else if (type == 'internal') {
          // Navigation interne
          // TODO: Implémenter la navigation interne selon le lien
          AppLogger.info('Internal navigation to: $link', 'HOME_UI');
          ToastHelper.showToast(context,
              title: "Navigation",
              message: "Fonctionnalité à venir",
              type: ToastType.info);
        }
      }
    } catch (e) {
      AppLogger.error('Failed to handle carousel tap', 'HOME_UI', e);
      ToastHelper.showToast(context,
          title: "Erreur",
          message: "Impossible d'ouvrir ce contenu",
          type: ToastType.error);
    }
  }

  Widget _buildQuickActionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildRoundActionButton(
          image: "assets/images/seller.png",
          label: "Acheter\n& Envoyer",
          color: const Color(0xFF558B2F), // Vert clair foncé
          fontWeight: FontWeight.bold,
          fontSize: 14,
          fontFamily: 'Nunito',
          onTap: () {
            Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (context) => const AcheterBonPage(),
              ),
            );
          },
        ),
        _buildRoundActionButton(
          image: "assets/images/mesbons.png",
          label: "Mes bons",
          color: const Color(0xFF0277BD), // Bleu clair foncé
          fontWeight: FontWeight.bold,
          fontSize: 14,
          fontFamily: 'Nunito',
          onTap: () async {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (context) => const MesBonsPage(),
              ),
            );
            if (result == true) {
              await _loadAccueilData();
            }
          },
        ),
        _buildRoundActionButton(
          image: "assets/images/cadeau.png",
          label: "Récompenses",
          color: const Color.fromARGB(255, 245, 209, 5), // Jaune foncé
          fontWeight: FontWeight.bold,
          fontSize: 14,
          fontFamily: 'Nunito',
          onTap: () async {
            // Navigation vers récompenses
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (context) => const RecompensesPage(),
              ),
            );
            /*ToastHelper.showToast(context,
                title: "Récompenses",
                message: "Fonctionnalité à venir",
                type: ToastType.info);*/
          },
        ),
      ],
    );
  }

  Widget _buildRoundActionButton({
    required String image,
    required String label,
    required Color color,
    VoidCallback? onTap,
    required FontWeight fontWeight,
    required String fontFamily,
    required int fontSize,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                image,
                height: 45, // Taille optimisée pour le cercle
                width: 45,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: fontSize.toDouble(),
                fontWeight: fontWeight,
                color: const Color(
                    0xFF000000), // Noir pur pour visibilité maximale
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
