class AvatarHelper {
  // Liste d'avatars prédéfinis (URLs d'images d'avatar)
  static const List<String> predefinedAvatars = [
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Felix',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Aneka',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Princess',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Cuddles',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Smokey',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Gizmo',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Midnight',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Baby',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Milo',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Bella',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Charlie',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Lucy',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Max',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Daisy',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Oliver',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Luna',
  ];

  /// Obtenir un avatar aléatoire
  static String getRandomAvatar() {
    return predefinedAvatars[
        DateTime.now().millisecondsSinceEpoch % predefinedAvatars.length];
  }

  /// Obtenir un avatar par index
  static String getAvatarByIndex(int index) {
    if (index >= 0 && index < predefinedAvatars.length) {
      return predefinedAvatars[index];
    }
    return predefinedAvatars[0];
  }
}
