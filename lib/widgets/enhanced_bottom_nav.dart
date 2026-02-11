import 'package:flutter/material.dart';
import '../pages/home/home.dart';
import '../pages/acheter/acheter.dart';
import '../pages/mes-bons/mes_bons.dart';
import '../pages/profil/enhanced_profil.dart';

class EnhancedBottomNav extends StatelessWidget {
  final int currentIndex;
  
  const EnhancedBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
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
              context: context,
              icon: Icons.home,
              label: 'Accueil',
              index: 0,
              isSelected: currentIndex == 0,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.shopping_cart,
              label: 'Acheter',
              index: 1,
              isSelected: currentIndex == 1,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.card_giftcard,
              label: 'Mes bons',
              index: 2,
              isSelected: currentIndex == 2,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.person,
              label: 'Profil',
              index: 3,
              isSelected: currentIndex == 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    // Enhanced darker blue color and bigger icons as requested
    const Color selectedColor = Color(0xFF2F55E0); // Darker blue
    const Color unselectedColor = Colors.grey;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(context, index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? selectedColor : unselectedColor,
                size: isSelected ? 32 : 28, // Bigger icons - increased by 2pts as required
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? selectedColor : unselectedColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, // Bold text as required
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return; // Don't navigate if already on the page
    
    Widget targetPage;
    switch (index) {
      case 0:
        targetPage = const HomePage();
        break;
      case 1:
        targetPage = const AcheterBonPage();
        break;
      case 2:
        targetPage = const MesBonsPage();
        break;
      case 3:
        targetPage = const EnhancedProfilPage();
        break;
      default:
        return;
    }
    
    // For home screen, replace the stack. For others, push to allow back navigation.
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => targetPage),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetPage),
      );
    }
  }
}
