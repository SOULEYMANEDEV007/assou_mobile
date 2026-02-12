import 'package:ASSOU/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/services/profile_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_input.dart';
import '../../widgets/numeric_password_field.dart';
import '../../widgets/toast_helper.dart';
import '../auth/login_screen.dart';

class EnhancedProfilPage extends StatefulWidget {
  const EnhancedProfilPage({super.key});

  @override
  State<EnhancedProfilPage> createState() => _EnhancedProfilPageState();
}

enum AppLink {
  business('https://assou.app/business', 'Business'),
  cgu('https://assou.app/cgu/', 'Conditions Générales d’Utilisation'),
  privacy('https://assou.app/politique-de-confidentialite/',
      'Politique de confidentialité'),
  support(
      "https://api.whatsapp.com/send/?phone=2250565651111&text&type=phone_number&app_absent=0",
      'Support via WhatsApp');

  final String url;
  final String title;

  const AppLink(this.url, this.title);
}

class _EnhancedProfilPageState extends State<EnhancedProfilPage>
    with TickerProviderStateMixin {
  User? user;
  bool isLoading = false;
  bool _isLoggingOut = false;
  bool _notificationEnabled = true;
  bool _darkModeEnabled = false;
  String _appVersion = 'Loading...';

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Controllers pour garder les valeurs saisies même après setState
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initControllers();
    _loadUserData();
    _loadDarkModePreference();
    _getAppVersion();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  void _initControllers() {
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
  }

  void _updateControllersFromUser(User? u) {
    firstNameController.text = u?.firstName ?? '';
    lastNameController.text = u?.lastName ?? '';
    emailController.text = u?.email ?? '';
    phoneController.text = u?.phoneNumber ?? '';
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkModeEnabled = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> _saveDarkModePreference(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
  }

  Future<void> _getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });

    print("_appVersion : $_appVersion");
  }

  Future<void> _launchUrl(String url, String title) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      if (mounted) {
        _showErrorDialog('Erreur', 'Lien invalide pour $title');
      }
      return;
    }

    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showErrorDialog('Erreur', 'Impossible d\'ouvrir le lien vers $title');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erreur', 'Échec lors de l\'ouverture du lien $title');
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);

    try {
      User? localUser = await UserService.getCurrentUser();
      if (localUser != null) {
        setState(() => user = localUser);
        _updateControllersFromUser(localUser);
      }

      var data = await ProfileService.getProfilData();
      if (data?['user'] != null) {
        User updatedUser = User.fromJson(data!['user']);
        await UserService.updateUser(updatedUser);
        setState(() => user = updatedUser);
        _updateControllersFromUser(updatedUser);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Erreur'),
            content: Text('Erreur de chargement: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: const CustomAppBar(
        title: "Profil et reglages",
        showBackButton: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildContent(context, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 32),
              _buildProfileHeader(isDark),
              const SizedBox(height: 32),
              _buildAccountSection(isDark),
              const SizedBox(height: 24),
              _buildNotificationsSection(isDark),
              const SizedBox(height: 24),
              //_buildAppSettingsSection(isDark),
              const SizedBox(height: 24),
              _buildLinksSection(isDark),
              const SizedBox(height: 32),
              _buildLogoutButton(),
              const SizedBox(height: 24),
              _buildFooterSection(isDark),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    final name = user?.fullName ?? 'Utilisateur';
    final email = user?.email ?? 'email@exemple.com';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        boxShadow: isDark ? null : AppShadows.sm,
        border: isDark ? Border.all(color: AppColors.darkBorder) : null,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _showEditProfileModal,
            child: Stack(
              children: [
                Hero(
                  tag: 'profile_avatar',
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isDark ? AppColors.darkSurface : AppColors.surface,
                        width: 2,
                      ),
                    ),
                    child:
                        const Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF000000), // Noir pur
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : const Color(
                          0xFF444444), // Gris foncé pour meilleure visibilité
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(bool isDark) {
    return _buildSection(
      title: 'Compte',
      isDark: isDark,
      children: [
        _buildSettingsTile(
          icon: Icons.person_outline,
          title: 'Modifier le profil',
          subtitle: 'Changer nom, email, téléphone',
          onTap: _showEditProfileModal,
          isDark: isDark,
        ),
        _buildSettingsTile(
          icon: Icons.lock_outline,
          title: 'Changer le mot de passe',
          subtitle: 'Mettre à jour votre mot de passe',
          onTap: _showChangePasswordModal,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(bool isDark) {
    return _buildSection(
      title: 'Notifications',
      isDark: isDark,
      children: [
        _buildSettingsTile(
          icon: Icons.notifications_outlined,
          title: 'Paramètres de notification',
          subtitle: 'Gérer vos notifications',
          isDark: isDark,
          trailing: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Switch.adaptive(
              value: _notificationEnabled,
              onChanged: (value) {
                setState(() => _notificationEnabled = value);
              },
              activeColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  /*Widget _buildAppSettingsSection(bool isDark) {
    return _buildSection(
      title: 'Paramètres de l\'app',
      isDark: isDark,
      children: [
        _buildSettingsTile(
          icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          title: 'Mode sombre',
          subtitle: isDark ? 'Passer au mode clair' : 'Passer au mode sombre',
          isDark: isDark,
          trailing: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Switch.adaptive(
              value: _darkModeEnabled,
              onChanged: (value) async {
                setState(() => _darkModeEnabled = value);
                await _saveDarkModePreference(value);

                // Show restart message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Mode sombre activé. Redémarrez l\'app pour l\'appliquer complètement.'
                            : 'Mode clair activé. Redémarrez l\'app pour l\'appliquer complètement.',
                      ),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              activeColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
*/
  Widget _buildSection({
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        boxShadow: isDark ? null : AppShadows.sm,
        border: isDark ? Border.all(color: AppColors.darkBorder) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: child,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : const Color(0xFF000000), // Noir pur
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : const Color(0xFF555555), // Plus sombre
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: _isLoggingOut ? null : _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isLoggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.logout, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _isLoggingOut ? 'Déconnexion...' : 'Déconnexion',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileModal() {
    // On met à jour les controllers avec les dernières valeurs de l'utilisateur
    _updateControllersFromUser(user);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEditProfileModal(),
    );
  }

  void _showChangePasswordModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildChangePasswordModal(),
    );
  }

  Widget _buildEditProfileModal() {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppBorderRadius.xl),
              topRight: Radius.circular(AppBorderRadius.xl),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Text(
                      'Modifier le profil',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF000000),
                              ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      AppInput(
                        controller: firstNameController,
                        label: 'Prénom',
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        controller: lastNameController,
                        label: 'Nom de famille',
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        controller: emailController,
                        label: 'Email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        controller: phoneController,
                        label: 'Numéro de téléphone',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.number,
                        readOnly: true,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Annuler',
                              onPressed: () => Navigator.pop(context),
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: Colors.blue.shade500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppButton(
                              text: 'Enregistrer',
                              isLoading: isLoading,
                              onPressed: isLoading
                                  ? null
                                  : () => _handleSaveProfile(
                                        firstNameController.text,
                                        lastNameController.text,
                                        emailController.text,
                                        phoneController.text,
                                      ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChangePasswordModal() {
    String? validateConfirmPassword(String? value) {
      if (value == null || value.isEmpty) {
        return 'Confirmation obligatoire';
      }
      if (value != newPasswordController.text) {
        return 'Les mots de passe ne correspondent pas';
      }
      return null;
    }

    String? validatePassword(String? value) {
      if (value == null || value.isEmpty) {
        return 'Mot de passe obligatoire';
      }
      if (value.length < 4 || value.length > 4) {
        return 'Le mot de passe doit contenir uniquement 4 caractères';
      }
      return null;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppBorderRadius.xl),
              topRight: Radius.circular(AppBorderRadius.xl),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Text(
                      'Changer le mot de passe',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF000000),
                              ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        NumericPasswordField(
                          controller: currentPasswordController,
                          hint: 'Mot de passe',
                          length: 4, // taille du mot de passe
                        ),
                        const SizedBox(height: 16),
                        NumericPasswordField(
                          controller: newPasswordController,
                          hint: 'Mot de passe',
                          length: 4, // taille du mot de passe
                        ),
                        const SizedBox(height: 16),
                        NumericPasswordField(
                          controller: confirmPasswordController,
                          confirmController: newPasswordController,
                          hint: 'Mot de passe',
                          length: 4, // taille du mot de passe
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: 'Annuler',
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppButton(
                                text: 'Mettre à jour',
                                isLoading: isLoading,
                                onPressed: () => {
                                  if (_formKey.currentState!.validate())
                                    {
                                      _handleChangePassword(
                                        currentPasswordController.text,
                                        newPasswordController.text,
                                        confirmPasswordController.text,
                                      )
                                    }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSaveProfile(
    String firstName,
    String lastName,
    String email,
    String phone,
  ) async {
    if (firstName.isEmpty || lastName.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Champs manquants'),
          content: const Text('Veuillez remplir tous les champs obligatoires'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      final token = await UserService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception("Session expirée - Veuillez vous reconnecter");
      }

      final response = await AuthService.updateProfile(
        token: token,
        userId: user?.id ?? 0,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        phoneNumber: phone.trim(),
      );

      if (response.success) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        ToastHelper.showToast(context,
            title: "Mise a jour du profil",
            message: "Profil mis à jour avec succès",
            type: ToastType.success);

        _loadUserData();
      } else {
        throw Exception(response.message ?? "Échec de la mise à jour");
      }
    } catch (e) {
      if (!mounted) return;

      ToastHelper.showToast(context,
          title: "Erreur lors de la mise a jour du profil",
          message:
              "Un problème est survenu lors de la mise a jour du profil : ${e.toString()}",
          type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleChangePassword(
    String current,
    String newPass,
    String confirm,
  ) async {
    setState(() => isLoading = true);

    try {
      final token = await UserService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception("Session expirée - Veuillez vous reconnecter");
      }

      final response = await AuthService.changePassword(
        token: token,
        currentPassword: current,
        newPassword: newPass,
      );

      if (response.success) {
        Navigator.pop(context);
        ToastHelper.showToast(context,
            title: "Mise à jour du mot de passe",
            message: "Mot de passe mis à jour avec succès",
            type: ToastType.success);

        AuthService.logout();
      } else {
        throw Exception(response.message ?? "Échec de la mise à jour");
      }
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(context,
          title: "Mise à jour du mot de passe",
          message:
              "Un problème est survenu lors de la modification du mot de passe",
          type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    // Prevent multiple logout attempts
    if (_isLoggingOut) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      final token = await UserService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception("Session expirée");
      }

      final response = await AuthService.logout();

      if (!response.success) {
        throw Exception(response.message ?? "Erreur serveur");
      }

      await UserService.clearUserData();
      await AuthService.clearToken();

      if (!mounted) return;

      ToastHelper.showToast(context,
          title: "Deconnection de utilisateur",
          message: "Déconnexion réussie !",
          type: ToastType.success);

      Future.delayed(const Duration(milliseconds: 1000), () {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
      });

      // // Show success toast
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: const Text('Déconnexion réussie'),
      //     backgroundColor: Colors.green,
      //     behavior: SnackBarBehavior.floating,
      //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      //     duration: const Duration(seconds: 1),
      //   ),
      // );
      //
      // // Navigate after a short delay
      // await Future.delayed(const Duration(milliseconds: 500));
      // if (!mounted) return;
      //
      // Navigator.of(context).pushAndRemoveUntil(
      //   MaterialPageRoute(
      //       builder: (context) =>
      //           const RegisterPage.PageConnexionInscription(initialTab: 1)),
      //   (Route<dynamic> route) => false,
      // );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });

        // Show error toast
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de la déconnexion'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildLinksSection(bool isDark) {
    return _buildSection(
      title: 'Liens utiles',
      isDark: isDark,
      children: [
        _buildSettingsTile(
          icon: Icons.business_outlined,
          title: 'Comment ajouter une boutique sur ASSOU ?',
          subtitle: 'Rejoignez notre réseau de partenaires',
          onTap: () => _launchUrl(AppLink.business.url, AppLink.business.title),
          isDark: isDark,
          trailing: const Icon(Icons.open_in_new, size: 16),
        ),
        _buildSettingsTile(
          icon: Icons.description_outlined,
          title: 'Conditions Générales d\'Utilisation',
          subtitle: 'Consultez nos conditions d\'usage',
          onTap: () => _launchUrl(AppLink.cgu.url, AppLink.cgu.title),
          isDark: isDark,
          trailing: const Icon(Icons.open_in_new, size: 16),
        ),
        _buildSettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Politique de confidentialité',
          subtitle: 'Découvrez comment nous protégeons vos données',
          onTap: () => _launchUrl(AppLink.privacy.url, AppLink.privacy.title),
          isDark: isDark,
          trailing: const Icon(Icons.open_in_new, size: 16),
        ),
        _buildSettingsTile(
          icon: Icons.call,
          title: 'Service client',
          subtitle: 'Contactez notre support pour toute aide',
          onTap: () => _launchUrl(AppLink.support.url, AppLink.support.title),
          isDark: isDark,
          trailing: const Icon(Icons.open_in_new, size: 16),
        ),
      ],
    );
  }

  Widget _buildFooterSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        boxShadow: isDark ? null : AppShadows.sm,
        border: isDark ? Border.all(color: AppColors.darkBorder) : null,
      ),
      child: Column(
        children: [
          Icon(
            Icons.mobile_friendly,
            size: 48,
            color: AppColors.primary.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Text(
                'ASSOU',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Un produit de KOSEH GROUP',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Version $_appVersion',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '© ${DateTime.now().year} ASSOU. Tous droits réservés.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.textTertiary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
