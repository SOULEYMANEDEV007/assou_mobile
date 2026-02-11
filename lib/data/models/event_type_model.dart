import 'package:flutter/material.dart';
import '../../config/environment.dart';

class EventType {
  final int id;
  final String nom;
  final String libelle;
  final String? description;
  final String? couleur;
  final String? icone;
  final String? image;
  final bool actif;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  EventType({
    required this.id,
    required this.nom,
    required this.libelle,
    this.description,
    this.couleur,
    this.icone,
    this.image,
    required this.actif,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // ==================== JSON ====================

  factory EventType.fromJson(Map<String, dynamic> json) {
    // Debug log for icon
    // print('Parsing EventType ${json['id']}: icone=${json['icone']}');

    return EventType(
      id: json['id'],
      nom: json['nom'],
      libelle: json['libelle'],
      description: json['description'],
      couleur: json['couleur'],
      icone: json['icone']?.toString().trim() ?? "", // Ensure string and trim
      image: json['image'],
      actif: json['actif'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'libelle': libelle,
      'description': description,
      'couleur': couleur,
      'icone': icone,
      'image': image,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  // ==================== IDENTITÉ (IMPORTANT) ====================
  // Un EventType est identifié UNIQUEMENT par son id
  // -> indispensable pour Dropdown, Set, Map, comparaison

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EventType && other.id == id;

  @override
  int get hashCode => id.hashCode;

  // ==================== DEBUG ====================

  @override
  String toString() {
    return 'EventType(id: $id, nom: $nom, libelle: $libelle, icone: $icone, image: $image)';
  }

  // ==================== UI HELPERS ====================

  /// URL de l'image de l'événement
  String? get imageUrl => Environment.getImageUrl(image);

  /// Convertit la couleur hexadécimale en Color Flutter
  Color? get colorValue {
    if (couleur == null || couleur!.isEmpty) return null;
    try {
      String hex = couleur!.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex'; // alpha par défaut
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }

  /// Icône à afficher (emoji)
  @Deprecated('Use iconData instead')
  String get displayIcon {
    if (icone == null || icone!.isEmpty) return '🎁';

    const iconMap = {
      'cake': '🎂',
      'building-office': '🏢',
      'party': '🎉',
      'star': '⭐',
      'heart': '❤️',
      'baby': '👶',
      'gift': '🎁',
      'academic-cap': '🎓',
      'users': '👥',
    };

    return iconMap[icone] ?? icone!;
  }

  /// Icône Flutter (Material Icons)
  IconData get iconData {
    // print('Getting icon for key: "$icone"'); // Debug print

    if (icone == null || icone!.isEmpty) return Icons.card_giftcard;

    final key = icone!.toLowerCase().trim();

    const iconMap = {
      'cake': Icons.cake,
      'building-office': Icons.location_city,
      'party': Icons.celebration,
      'star': Icons.star,
      'heart': Icons.favorite,
      'baby': Icons.child_friendly,
      'gift': Icons.card_giftcard,
      'academic-cap': Icons.school,
      'users': Icons.group,
      'home': Icons.home,
      'work': Icons.work,
      'business': Icons.business,
      'celebration': Icons.celebration,
    };

    return iconMap[key] ?? Icons.card_giftcard;
  }
}
