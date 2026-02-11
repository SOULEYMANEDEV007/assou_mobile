import 'package:ASSOU/pages/home/home.dart';
import 'package:ASSOU/widgets/toast_helper.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:local_auth/local_auth.dart';
import '../../data/models/event_type_model.dart';
import '../../data/services/event_type_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/voucher_service.dart';
import '../../data/services/voucher_transfer_service.dart';
import '../../utils/logger.dart';
import '../../utils/price_utils.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_input.dart';
import '../../widgets/custom_app_bar.dart';
import '../../theme/app_theme.dart';

/// Optimisations & corrections principales :
/// 1) Centralisation du style "card" via `_cardDecoration` / `_cardPadding`.
/// 2) Robustesse des montants : `_parseMontant` et `_formatMontant` gèrent
///    double/int/String (formaté) pour éviter `isNegative` sur String.
/// 3) Pré-sélection du bon améliorée : si `selectedVoucherId` est fourni,
///    on tente d'auto-sélectionner après chargement des vouchers API,
///    sinon on retombe proprement sur `widget.bonsActifs`.
/// 4) Moins de duplication et messages d'erreur plus clairs.
/// 5) Typage plus strict pour les listes quand possible.
///
class EnvoyerBonPage extends StatefulWidget {
  final List<dynamic> bonsActifs;
  final int? selectedVoucherId;
  final String? voucherAmount;
  final String? boutiqueName;
  final String? slug;

  const EnvoyerBonPage({
    super.key,
    this.bonsActifs = const [],
    this.selectedVoucherId,
    this.voucherAmount,
    this.boutiqueName,
    this.slug,
  });

  @override
  State<EnvoyerBonPage> createState() => _EnvoyerBonPageState();
}

class _EnvoyerBonPageState extends State<EnvoyerBonPage>
    with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _contactSearchController =
      TextEditingController();

  // State
  Map<String, dynamic>? _selectedVoucher;
  EventType? _selectedEventType;
  List<EventType> _eventTypes = [];
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  List<Map<String, dynamic>> _activeVouchers = []; // now typed
  bool _isLoadingEventTypes = true;
  bool _isLoadingContacts = false;
  bool _isSending = false;
  bool _contactsPermissionGranted = false;
  bool _contactsPermissionRequested = false;
  bool _showContactSearch = false;

  // Animation
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  // Common UI constants
  final EdgeInsets _cardPadding = const EdgeInsets.all(20);
  final BoxDecoration _cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      const BoxShadow(
        color: Colors.black12,
        blurRadius: 10,
        offset: Offset(0, 2),
      ),
    ],
  );

  @override
  void initState() {
    super.initState();

    // If user passed a selectedVoucherId with voucherAmount, create a minimal
    // selected voucher placeholder (montant_bon kept numeric when possible)
    if (widget.selectedVoucherId != null) {
      _selectedVoucher = {
        'id': widget.selectedVoucherId,
        'slug': widget.slug,
        'montant_bon': _parseMontant(widget.voucherAmount),
      };
    }

    _initAnimations();
    _loadEventTypes();
    _loadActiveVouchers();
    _contactSearchController.addListener(_filterContacts);
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    _contactSearchController.dispose();
    super.dispose();
  }

  // ---------------------------
  // Helpers for montant parsing
  // ---------------------------
  double _parseMontant(dynamic value) {
    // Try to return a numeric value (double). Accepts int, double, or strings like "10000", "10.000", "10,000", "10000 FCFA", or formatted via PriceUtils.
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();

    if (value is String) {
      // Remove currency and non-numeric chars except dot or comma
      var cleaned = value.replaceAll(RegExp(r'[^\d.,-]'), '');

      // If contains both '.' and ',' assume '.' is thousand separator and ',' is decimal (EU), else manage typical cases
      if (cleaned.contains('.') && cleaned.contains(',')) {
        // remove thousand separators (.) and replace decimal comma with dot
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else if (cleaned.contains(',') && !cleaned.contains('.')) {
        // treat comma as decimal separator (e.g., "10,5")
        cleaned = cleaned.replaceAll(',', '.');
      } else {
        // remove thousand separators (commonly '.') if any occurs and more than 3 digits groups
        // e.g. "10.000" -> "10000"
        cleaned = cleaned.replaceAll('.', '');
      }

      final parsed = double.tryParse(cleaned);
      return parsed ?? 0.0;
    }

    return 0.0;
  }

  String _formatMontant(dynamic value, {bool showCurrency = true}) {
    // Use PriceUtils when possible (it expects a string with the raw number)
    final numeric = _parseMontant(value);
    // If PriceUtils.formatPrice exists and expects a string without currency, pass it; else fallback to intl
    try {
      final str = numeric
          .toInt()
          .toString(); // price utils usually expects integer string
      return PriceUtils.formatPrice(str, showCurrency: showCurrency);
    } catch (_) {
      // fallback using intl
      final f = NumberFormat('#,###', 'fr_FR');
      final formatted = f.format(numeric.round());
      return showCurrency ? '$formatted FCFA' : formatted;
    }
  }

  // ---------------------------
  // Loaders
  // ---------------------------
  Future<void> _loadEventTypes() async {
    try {
      final token = await UserService.getAuthToken();
      if (token != null) {
        final types = await EventTypeService.getActiveEventTypes(token: token);
        if (mounted) {
          setState(() {
            _eventTypes = types;
            _isLoadingEventTypes = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _eventTypes = [];
            _isLoadingEventTypes = false;
          });
        }
      }
    } catch (e, st) {
      AppLogger.error(
          'Failed to load event types', 'SEND_VOUCHER_PAGE , $e, $st');
      if (mounted) {
        setState(() {
          _eventTypes = [];
          _isLoadingEventTypes = false;
        });
      }
    }
  }

  Future<void> _loadActiveVouchers() async {
    try {
      final token = await UserService.getAuthToken();
      if (token == null) throw Exception('Token non trouvé');

      final vouchers = await VoucherService.getMyActiveVouchers(token);

      final converted = vouchers.map<Map<String, dynamic>>((voucher) {
        // Ensure montant_bon is numeric
        final montant = voucher.montantBon.toDouble();
        return {
          'id': voucher.id,
          'slug': voucher.slug,
          'montant_bon': montant,
          'boutique': {
            'name': voucher.boutique?.name ?? 'Boutique universelle',
            'logo': voucher.boutique?.logo,
            'slug': voucher.boutique?.slug,
          },
          'bon_achat': {
            'libelle': voucher.bon?.libelle ?? 'Bon universel',
            'montant_bon': voucher.bon?.montantBon.toInt() ?? montant.toInt(),
            'boutique': {
              'name': voucher.bon?.boutique?.name ??
                  voucher.boutique?.name ??
                  'Boutique universelle',
              'slug': voucher.bon?.boutique?.slug ?? voucher.boutique?.slug,
            },
          },
          'date_expire': voucher.dateExpire?.toIso8601String(),
          'etat': voucher.etat,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _activeVouchers = converted;
        });

        // Try to preselect if needed
        _preSelectVoucher();
      }
    } catch (e, st) {
      AppLogger.error(
          'Failed to load active vouchers', 'SEND_VOUCHER_PAGE , $e, $st');

      if (mounted) {
        // fallback to provided `widget.bonsActifs` (ensure numeric amounts)
        final fallback = widget.bonsActifs.map<Map<String, dynamic>>((bon) {
          return {
            'id': bon['id'],
            'slug': bon['slug'],
            'montant_bon': _parseMontant(bon['montant_bon']),
            'etat': bon['etat'] ?? 1,
            'boutique': bon['boutique'] ?? {},
            'bon_achat': bon['bon_achat'] ?? {},
          };
        }).toList();

        setState(() {
          _activeVouchers = fallback;
        });

        _preSelectVoucher();
      }
    }
  }

  void _preSelectVoucher() {
    // Try to auto-select voucher by widget.selectedVoucherId if present
    if (widget.selectedVoucherId != null && _activeVouchers.isNotEmpty) {
      final found = _activeVouchers.firstWhere(
        (v) => v['id'] == widget.selectedVoucherId,
        orElse: () => {},
      );

      if (found.isNotEmpty) {
        setState(() {
          _selectedVoucher = found;
        });
        AppLogger.info(
            'Auto-selected voucher id ${found['id']}', 'ENVOYER_BON_PRESELECT');
        return;
      }
    }

    // If user passed voucherAmount and slug but the voucher was not found in API,
    // ensure _selectedVoucher is consistent (we already set it in initState but ensure montant numeric)
    if (_selectedVoucher != null && _selectedVoucher!['montant_bon'] != null) {
      _selectedVoucher!['montant_bon'] =
          _parseMontant(_selectedVoucher!['montant_bon']);
    }
  }

  // ---------------------------
  // Contacts & Permissions
  // ---------------------------
  Future<void> _requestContactsPermission() async {
    if (_contactsPermissionGranted) {
      await _loadContacts();
      return;
    }

    if (_contactsPermissionRequested) return;

    setState(() {
      _contactsPermissionRequested = true;
      _isLoadingContacts = true;
    });

    try {
      final status = await Permission.contacts.request();
      if (status.isGranted) {
        setState(() {
          _contactsPermissionGranted = true;
        });
        await _loadContacts();
      } else {
        setState(() {
          _contactsPermissionGranted = false;
          _contactsPermissionRequested = false;
          _isLoadingContacts = false;
        });

        final isDeniedPermanently = status.isPermanentlyDenied;
        final message = isDeniedPermanently
            ? 'Accès aux contacts refusé de façon permanente. Activez dans les paramètres.'
            : 'Autorisation d\'accès aux contacts refusée. Saisissez le numéro manuellement.';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: isDeniedPermanently ? Colors.red : Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              duration: Duration(seconds: isDeniedPermanently ? 5 : 3),
              action: isDeniedPermanently
                  ? SnackBarAction(
                      label: 'Paramètres',
                      textColor: Colors.white,
                      onPressed: () => openAppSettings(),
                    )
                  : null,
            ),
          );
        }
      }
    } catch (e, st) {
      AppLogger.error('Failed to request contacts permission',
          'SEND_VOUCHER_PAGE , $e, $st');
      setState(() {
        _contactsPermissionGranted = false;
        _contactsPermissionRequested = false;
        _isLoadingContacts = false;
      });
    }
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoadingContacts = true;
    });

    try {
      if (!_contactsPermissionGranted) {
        throw Exception('Permission refusée pour accéder aux contacts');
      }

      final deviceContacts =
          await FlutterContacts.getContacts(withProperties: true);

      final validContacts = <Contact>[];
      for (final c in deviceContacts) {
        if (c.phones.isNotEmpty) {
          final name =
              c.displayName.isNotEmpty ? c.displayName : 'Contact sans nom';
          final phone = c.phones.first.number.replaceAll(' ', '');
          if (phone.isNotEmpty) {
            validContacts.add(Contact(name: name, phoneNumber: phone));
          }
        }
      }

      if (mounted) {
        setState(() {
          _contacts = validContacts;
          _filteredContacts = validContacts;
          _isLoadingContacts = false;
        });
      }
    } catch (e, st) {
      AppLogger.error(
          'Failed to load contacts from device', 'SEND_VOUCHER_PAGE , $e, $st');

      // fallback to small mock list to keep the UX functional
      final fallback = [
        Contact(name: "Jean Dupont", phoneNumber: "0701020304"),
        Contact(name: "Marie Martin", phoneNumber: "0705060708"),
      ];
      if (mounted) {
        setState(() {
          _contacts = fallback;
          _filteredContacts = fallback;
          _isLoadingContacts = false;
        });
      }
    }
  }

  void _filterContacts() {
    final q = _contactSearchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _contacts.where((c) {
        return c.name.toLowerCase().contains(q) || c.phoneNumber.contains(q);
      }).toList();
    });
  }

  void _selectContact(Contact contact) {
    setState(() {
      _phoneController.text = contact.phoneNumber;
      _showContactSearch = false;
    });
    _contactSearchController.clear();
  }

  // ---------------------------
  // Send voucher
  // ---------------------------
  Future<void> _sendVoucher() async {
    if (_isSending) return;

    if (_phoneController.text.trim().isEmpty || _selectedVoucher == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final token = await UserService.getAuthToken();
      if (token == null) {
        throw Exception('Session expirée');
      }

      final proceed = await _showSecurityConfirmation();
      if (!proceed) {
        setState(() => _isSending = false);
        return;
      }

      final slug = _selectedVoucher!['slug']?.toString();
      if (slug == null || slug.isEmpty) {
        throw Exception('Voucher slug manquant');
      }

      final result = await VoucherTransferService.sendVoucherByPhone(
        token: token,
        voucherSlug: slug,
        recipientPhone: _phoneController.text.trim(),
        eventTypeId: _selectedEventType?.id,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      );

      if (result.success == true) {
        AppLogger.info(
            'Voucher transfer completed successfully', 'SEND_VOUCHER_PAGE');
        ToastHelper.showToast(
          title: "Envoie de bon",
          context,
          message:
              "Bon envoyé avec succès ! Le destinataire recevra une notification WhatsApp",
          type: ToastType.success,
        );

        Future.delayed(const Duration(milliseconds: 800), () {
          Navigator.pushReplacementNamed(context, "/home");
        });
      } else {
        AppLogger.warning(
            'Voucher transfer failed: ${result.message}', 'SEND_VOUCHER_PAGE');
        ToastHelper.showToast(
          title: "Envoie de bon",
          context,
          message: result.message ?? "Erreur lors de l'envoi du bon",
          type: ToastType.error,
        );
      }
    } catch (e, st) {
      AppLogger.error('Failed to send voucher', 'SEND_VOUCHER_PAGE , $e, $st');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<bool> _showSecurityConfirmation() async {
    final localAuth = LocalAuthentication();

    try {
      final canCheckBiometrics = await localAuth.canCheckBiometrics;
      final isDeviceSupported = await localAuth.isDeviceSupported();

      AppLogger.info(
          'Biometric: canCheck=$canCheckBiometrics, supported=$isDeviceSupported',
          'ENVOYER_BON');

      if (canCheckBiometrics && isDeviceSupported) {
        final available = await localAuth.getAvailableBiometrics();
        if (available.isNotEmpty) {
          try {
            final didAuth = await localAuth.authenticate(
              localizedReason: 'Confirmez l\'envoi de votre bon d\'achat',
              options: const AuthenticationOptions(
                  biometricOnly: true, stickyAuth: true),
            );
            if (didAuth) return true;
          } catch (e) {
            AppLogger.warning('Biometric auth error: $e', 'ENVOYER_BON');
          }
        }
      }
    } catch (e, st) {
      AppLogger.error('Biometric setup error', 'ENVOYER_BON $e $st');
    }

    // Fallback dialog
    final montantText = _selectedVoucher != null
        ? _formatMontant(_selectedVoucher!['montant_bon'])
        : '—';

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.security, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(child: Text('Confirmation de sécurité')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Vous êtes sur le point d\'envoyer un bon d\'achat.'),
                const SizedBox(height: 8),
                Text('Destinataire: ${_phoneController.text}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Montant: $montantText',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Confirmez-vous cette action ?'),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning),
                child: const Text('Confirmer',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Color _getEventTypeColor(EventType eventType) {
    try {
      final color = eventType.couleur;
      if (color != null && color.isNotEmpty) {
        return Color(int.parse(color.replaceFirst('#', '0xFF')));
      }
    } catch (_) {}
    return Colors.blue;
  }

  // ---------------------------
  // Build
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: "Envoyer un Bon", showBackButton: true),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhoneSection(),
              const SizedBox(height: 24),
              _buildVoucherSelection(),
              const SizedBox(height: 24),
              _buildEventTypeSelection(),
              const SizedBox(height: 24),
              _buildMessageInput(),
              const SizedBox(height: 32),
              _buildSendButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneSection() {
    return Container(
      padding: _cardPadding,
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text('Destinataire',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppInput(
            controller: _phoneController,
            label: 'Numéro de téléphone',
            hint: 'Ex: 0707070707',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone,
          ),
          const SizedBox(height: 12),
          if (!_contactsPermissionRequested)
            AppButton(
              text: 'Choisir depuis les contacts',
              onPressed: _requestContactsPermission,
              type: ButtonType.outline,
              icon: Icons.contacts,
            )
          else if (_isLoadingContacts)
            const Center(child: CircularProgressIndicator())
          else if (_contactsPermissionGranted)
            Column(
              children: [
                AppButton(
                  text: _showContactSearch
                      ? 'Masquer les contacts'
                      : 'Choisir depuis les contacts',
                  onPressed: () =>
                      setState(() => _showContactSearch = !_showContactSearch),
                  type: ButtonType.outline,
                  icon: _showContactSearch ? Icons.expand_less : Icons.contacts,
                ),
                if (_showContactSearch) ...[
                  const SizedBox(height: 16),
                  AppInput(
                    controller: _contactSearchController,
                    label: 'Rechercher un contact',
                    hint: 'Tapez le nom ou numéro...',
                    prefixIcon: Icons.search,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredContacts.length,
                      itemBuilder: (context, index) {
                        final c = _filteredContacts[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: Text(
                                c.name.isNotEmpty
                                    ? c.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(color: Colors.blue)),
                          ),
                          title: Text(c.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(c.phoneNumber),
                          onTap: () => _selectContact(c),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildVoucherSelection() {
    return Container(
      padding: _cardPadding,
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.card_giftcard, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Expanded(
                child: Text('Bon à envoyer',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 16),
          // If a voucher was passed via navigation (selectedVoucherId), show read-only
          if (widget.selectedVoucherId != null && _selectedVoucher != null)
            Center(
              child: Text(
                _formatMontant(_selectedVoucher!['montant_bon']),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            )
          else
            DropdownButtonFormField2<Map<String, dynamic>>(
              value: _selectedVoucher,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Sélectionner un bon',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon:
                    const Icon(Icons.card_giftcard, color: Colors.green),
              ),
              dropdownStyleData: const DropdownStyleData(
                maxHeight: 220,
                padding: EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              items: _activeVouchers
                  .where((b) => (b['etat'] ?? 1) == 1)
                  .map((bon) {
                final text = _formatMontant(bon['montant_bon']);
                return DropdownMenuItem<Map<String, dynamic>>(
                    value: bon, child: Text(text));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVoucher = value;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEventTypeSelection() {
    return Container(
      padding: _cardPadding,
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.celebration, color: Colors.purple, size: 24),
            SizedBox(width: 8),
            Expanded(
                child: Text('Occasion (optionnel)',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 16),
          if (_isLoadingEventTypes)
            const Center(child: CircularProgressIndicator())
          else
            DropdownButtonFormField2<EventType>(
              value: _selectedEventType,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Choisir l\'occasion',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: _selectedEventType != null
                    ? Container(
                        margin: const EdgeInsets.all(12),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _getEventTypeColor(_selectedEventType!)
                              .withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _selectedEventType!.iconData,
                          size: 16,
                          color: _getEventTypeColor(_selectedEventType!),
                        ),
                      )
                    : const Icon(Icons.event, color: Colors.purple),
              ),
              hint: const Text('Choisir l\'occasion'),
              dropdownStyleData: const DropdownStyleData(
                maxHeight: 220,
                padding: EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              items: [
                const DropdownMenuItem<EventType>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.clear, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Aucune occasion'),
                    ],
                  ),
                ),
                ..._eventTypes.map((et) {
                  return DropdownMenuItem<EventType>(
                    value: et,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _getEventTypeColor(et).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            et.iconData,
                            size: 18,
                            color: _getEventTypeColor(et),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            et.libelle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              // 👇 On met à jour le champ sélectionné, mais on n’affiche pas l’icône du menu sélectionné dans le champ
              selectedItemBuilder: (context) {
                return [
                  // Premier élément : valeur null
                  const Text('Aucune occasion'),
                  // Ensuite les éléments réels
                  ..._eventTypes.map((et) => Text(et.libelle)),
                ];
              },

              onChanged: (val) {
                setState(() => _selectedEventType = val);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: _cardPadding,
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.message, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Expanded(
                child: Text('Message personnel (optionnel)',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 16),
          AppInput(
            controller: _messageController,
            label: 'Votre message',
            hint: 'Ajouter un message personnalisé...',
            maxLines: 3,
            prefixIcon: Icons.edit,
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: AppButton(
        text: _isSending ? 'Envoi en cours...' : 'Envoyer le Bon',
        onPressed: _isSending ? null : _sendVoucher,
        type: ButtonType.primary,
        isLoading: _isSending,
      ),
    );
  }
}

// Simple contact model for demonstration
class Contact {
  final String name;
  final String phoneNumber;

  Contact({required this.name, required this.phoneNumber});
}
