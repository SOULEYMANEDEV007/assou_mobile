import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/services/profile_service.dart';
import '../../data/services/user_service.dart';
import '../../data/models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/auth_service.dart';
import '../../helpers/avatar_helper.dart';

// Pour la navigation, on importe les pages nécessaires
import 'package:ASSOU/pages/home/home.dart';
import 'package:ASSOU/pages/acheter/acheter.dart';
// import 'package:ASSOU/pages/scanner/scanner.dart'; // décommenter si tu as la page
import 'package:ASSOU/pages/mes-bons/mes_bons.dart';
// Ajout import pour register

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  User? user;
  bool isLoading = false;
  bool _notificationEnabled = true;
  File? _profileImage;
  String? _selectedAvatarUrl; // URL de l'avatar sélectionné
  int _selectedIndex = 4; // 4 = Profil

  @override
  void initState() {
    super.initState();
    loadLocalUser();
    loadProfileFromServer();
  }

  // Affiche les infos locales immédiatement
  void loadLocalUser() async {
    User? localUser = await UserService.getCurrentUser();
    setState(() {
      user = localUser;
    });
  }

  // Met à jour les infos avec le serveur en arrière-plan
  void loadProfileFromServer() async {
    try {
      var data = await ProfileService.getProfilData();
      if (data?['user'] != null) {
        User updatedUser = User.fromJson(data!['user']);
        await UserService.updateUser(updatedUser);
        setState(() {
          user = updatedUser;
        });
      }
    } catch (e) {
      // ignore erreur réseau
    }
  }

  void _editProfile() async {
    String newFirstName = user?.firstName ?? '';
    String newLastName = user?.lastName ?? '';
    String newEmail = user?.email ?? '';
    String newPhone = user?.phoneNumber ?? '';

    TextEditingController firstNameController =
        TextEditingController(text: newFirstName);
    TextEditingController lastNameController =
        TextEditingController(text: newLastName);
    TextEditingController emailController =
        TextEditingController(text: newEmail);
    TextEditingController phoneController =
        TextEditingController(text: newPhone);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Modifier le profil"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: "Prénom"),
                ),
                TextField(
                  controller: lastNameController,
                  decoration:
                      const InputDecoration(labelText: "Nom de famille"),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "Téléphone"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Annuler"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Enregistrer"),
              onPressed: () async {
                // Debug 1 - Vérification des données avant envoi
                print("🔄 Données à envoyer :");
                print("Prénom: ${firstNameController.text}");
                print("Nom: ${lastNameController.text}");
                print("Email: ${emailController.text}");
                print("Téléphone: ${phoneController.text}");

                setState(() => isLoading = true);

                try {
                  // Debug 2 - Avant appel API
                  print("⏳ Appel API en cours...");

                  var response = await ProfileService.updateProfile(
                    firstName: firstNameController.text,
                    lastName: lastNameController.text,
                    email: emailController.text,
                    phone: phoneController.text,
                  );

                  // Debug 3 - Réponse brute de l'API
                  print("✅ Réponse API RECUE:");
                  print("Succès: ${response['success']}");
                  print("Message: ${response['message']}");
                  print("Data: ${response['data']?.toString() ?? 'null'}");

                  if (response['success'] == true && response['data'] != null) {
                    User updatedUser = User.fromJson(response['data']['user']);

                    // Debug 4 - Données après conversion
                    print("🔄 Utilisateur mis à jour:");
                    print(updatedUser.toString());

                    await UserService.updateUser(updatedUser);
                    setState(() {
                      user = updatedUser;
                      isLoading = false;
                    });
                  } else {
                    // Debug 5 - Erreur API
                    print("❌ Erreur dans la réponse API");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(response['message'] ?? "Erreur inconnue")),
                    );
                  }
                } catch (e, stackTrace) {
                  // Debug 6 - Erreur de communication
                  print("❌ ERREUR FATALE:");
                  print(e.toString());
                  print("Stack trace:");
                  print(stackTrace.toString());

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erreur réseau: ${e.toString()}")),
                  );
                } finally {
                  setState(() => isLoading = false);
                  Navigator.pop(context);
                  // Debug 7 - Fin du processus
                  print("🏁 Processus terminé");
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _changePassword() async {
    TextEditingController oldPass = TextEditingController();
    TextEditingController newPass = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Changer le mot de passe"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPass,
              decoration:
                  const InputDecoration(labelText: "Ancien mot de passe"),
              obscureText: true,
            ),
            TextField(
              controller: newPass,
              decoration:
                  const InputDecoration(labelText: "Nouveau mot de passe"),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Enregistrer"),
            onPressed: () {
              // Ici tu peux ajouter la logique d'appel API pour changer le mot de passe
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _selectLanguage() async {
    String selectedLang = 'fr';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Language"),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Français'),
                value: 'fr',
                groupValue: selectedLang,
                onChanged: (val) => setState(() => selectedLang = val!),
              ),
              RadioListTile<String>(
                title: const Text('English'),
                value: 'en',
                groupValue: selectedLang,
                onChanged: (val) => setState(() => selectedLang = val!),
              ),
              RadioListTile<String>(
                title: const Text('Español'),
                value: 'es',
                groupValue: selectedLang,
                onChanged: (val) => setState(() => selectedLang = val!),
              ),
              RadioListTile<String>(
                title: const Text('Deutsch'),
                value: 'de',
                groupValue: selectedLang,
                onChanged: (val) => setState(() => selectedLang = val!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Enregistrer"),
            onPressed: () {
              // Ici tu peux sauvegarder la langue choisie
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    print("🔵 _pickProfileImage called");
    // Show dialog to choose between gallery and avatar
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choisir une photo de profil"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text("Choisir depuis la galerie"),
              onTap: () async {
                print("🔵 Gallery option tapped");
                Navigator.pop(context);
                await _uploadFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: const Text("Choisir un avatar"),
              onTap: () async {
                print("🔵 Avatar option tapped");
                Navigator.pop(context);
                await _selectAvatar();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFromGallery() async {
    print("📸 _uploadFromGallery called");
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    print("📸 Picked file: ${pickedFile?.path}");
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
        _selectedAvatarUrl = null; // Clear avatar if photo is selected
      });
      print("📸 Profile image set, calling _updateProfilePhoto");

      // Upload the photo immediately
      await _updateProfilePhoto();
    } else {
      print("📸 No file picked");
    }
  }

  Future<void> _selectAvatar() async {
    print("👤 _selectAvatar called");
    String? selectedAvatar;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choisir un avatar"),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: AvatarHelper.predefinedAvatars.length,
            itemBuilder: (context, index) {
              final avatarUrl = AvatarHelper.predefinedAvatars[index];
              return GestureDetector(
                onTap: () {
                  print("👤 Avatar selected: $avatarUrl");
                  selectedAvatar = avatarUrl;
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedAvatarUrl == avatarUrl
                          ? Colors.blue
                          : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(48),
                    child: Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, size: 40);
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    print("👤 Dialog closed, selectedAvatar: $selectedAvatar");
    if (selectedAvatar != null) {
      setState(() {
        _selectedAvatarUrl = selectedAvatar;
        _profileImage = null; // Clear local image if avatar is selected
      });
      print("👤 State updated, calling _updateProfilePhoto");

      // Update profile with selected avatar
      await _updateProfilePhoto();
    } else {
      print("👤 No avatar selected");
    }
  }

  Future<void> _updateProfilePhoto() async {
    print("🔄 _updateProfilePhoto called");
    print("🔄 _profileImage: $_profileImage");
    print("🔄 _selectedAvatarUrl: $_selectedAvatarUrl");

    setState(() => isLoading = true);

    try {
      String? photoData;

      if (_profileImage != null) {
        print("🔄 Converting image to base64...");
        // Convert image to base64
        final bytes = await _profileImage!.readAsBytes();
        photoData = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        print("🔄 Base64 length: ${photoData.length}");
      } else if (_selectedAvatarUrl != null) {
        print("🔄 Using avatar URL");
        // Use avatar URL directly
        photoData = _selectedAvatarUrl;
      }

      print("🔄 photoData is null: ${photoData == null}");
      if (photoData != null) {
        print("🔄 Calling ProfileService.updateProfile with photo data");
        var response = await ProfileService.updateProfile(
          photo: photoData,
        );

        print("🔄 Response received:");
        print("   - success: ${response['success']}");
        print("   - message: ${response['message']}");
        print("   - data: ${response['data']}");

        if (response['success'] == true && response['data'] != null) {
          print("🔄 Parsing user data...");
          User updatedUser = User.fromJson(response['data']['user']);
          print("🔄 Updated user photo: ${updatedUser.photo}");
          await UserService.updateUser(updatedUser);
          setState(() {
            user = updatedUser;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Photo de profil mise à jour")),
            );
          }
        } else {
          print("🔄 Update failed: ${response['message']}");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'] ?? "Erreur")),
            );
          }
        }
      } else {
        print("🔄 photoData is null, nothing to update");
      }
    } catch (e, stackTrace) {
      print("🔄 ERROR: $e");
      print("🔄 Stack trace: $stackTrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: ${e.toString()}")),
        );
      }
    } finally {
      setState(() => isLoading = false);
      print("🔄 _updateProfilePhoto completed");
    }
  }

  // Helper method to get the profile image
  ImageProvider? _getProfileImage() {
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    } else if (_selectedAvatarUrl != null) {
      return NetworkImage(_selectedAvatarUrl!);
    } else if (user?.photo != null && user!.photo!.isNotEmpty) {
      return NetworkImage(user!.photo!);
    }
    return null;
  }

  // Ajout de la barre de navigation identique à home.dart
  Widget _buildRoundedNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.home,
              label: 'Accueil',
              index: 0,
            ),
            _buildNavItem(
              icon: Icons.shopping_cart,
              label: 'Acheter',
              index: 1,
            ),
            // _buildNavItem(
            //   icon: Icons.qr_code_scanner,
            //   label: 'Scanner',
            //   index: 2,
            // ),
            _buildNavItem(
              icon: Icons.card_giftcard,
              label: 'Mes bons',
              index: 3,
            ),
            _buildNavItem(
              icon: Icons.person,
              label: 'Profil',
              index: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      {required IconData icon, required String label, required int index}) {
    final bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedIndex == index) return;
          setState(() {
            _selectedIndex = index;
          });
          // Navigation vers la bonne page
          switch (index) {
            case 0:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
              break;
            case 1:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AcheterBonPage()),
              );
              break;
            // case 2:
            //   Navigator.of(context).pushReplacement(
            //     MaterialPageRoute(builder: (context) => ScannerPage()),
            //   );
            //   break;
            case 3:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const MesBonsPage()),
              );
              break;
            case 4:
              // On est déjà sur la page Profil
              break;
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color.fromARGB(255, 47, 85, 224)
                    : Colors.grey,
                size: isSelected ? 32 : 28,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color.fromARGB(255, 47, 85, 224)
                      : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? 'Nom';
    final email = user?.email ?? 'Email';
    //final phone = user?.phone_number ?? 'Téléphone';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Profil et Réglages",
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: _pickProfileImage,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 48,
                                  backgroundImage: _getProfileImage(),
                                  child: _getProfileImage() == null
                                      ? const Icon(Icons.person, size: 48)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.camera_alt,
                                        size: 18, color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            name,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700]),
                          ),
                        ),
                        Center(
                          child: Text(
                            email,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                        /*Center(
                          child: Text(
                            //phone,
                            //style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),*/
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text("Compte",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _editProfile,
                                child: Container(
                                  width: double.infinity,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Modifier le profil",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500)),
                                      SizedBox(height: 2),
                                      Text("Changer nom, email, téléphone",
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _changePassword,
                                child: Container(
                                  width: double.infinity,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text("Changer le mot de passe",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500)),
                                ),
                              ),
                              // Language Selection option is hidden
                              // GestureDetector(
                              //   onTap: _selectLanguage,
                              //   child: Container(
                              //     width: double.infinity,
                              //     margin: EdgeInsets.symmetric(vertical: 4),
                              //     padding: EdgeInsets.all(12),
                              //     decoration: BoxDecoration(
                              //       color: Colors.grey.shade200,
                              //       borderRadius: BorderRadius.circular(12),
                              //     ),
                              //     child: Text("Sélection de langue",
                              //         style: TextStyle(
                              //             fontWeight: FontWeight.w500)),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text("Notifications",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                        child: Text(
                                            "Paramètres de notification",
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500))),
                                    // Supprimer le Switch et ne garder que la grande icône toggle
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _notificationEnabled =
                                              !_notificationEnabled;
                                        });
                                      },
                                      child: Icon(
                                        _notificationEnabled
                                            ? Icons.toggle_on
                                            : Icons.toggle_off,
                                        color: _notificationEnabled
                                            ? Colors.blue
                                            : Colors.grey,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              _logout(),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (isLoading) ...[
                          const SizedBox(height: 16),
                          const CircularProgressIndicator(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Ajout de la barre de navigation en bas
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildRoundedNavigationBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 200,
          height: 48,
          child: ElevatedButton(
            onPressed: () async {
              try {
                await AuthService.logout();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (Route<dynamic> route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de la déconnexion'),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 29, 118, 234),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              "Déconnexion",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
}
