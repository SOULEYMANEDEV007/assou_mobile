import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../../../data/models/event_type_model.dart';

/// Widget réutilisable pour sélectionner un type d'événement
class EventTypeSelectorWidget extends StatefulWidget {
  /// Titre du widget
  final String title;

  /// Label du dropdown
  final String label;

  /// Placeholder du dropdown
  final String placeholder;

  /// Message pour "Aucun événement"
  final String noneOptionLabel;

  /// Liste des types d'événements disponibles
  final List<EventType> eventTypes;

  /// Type d'événement actuellement sélectionné
  final EventType? selectedEventType;

  /// Callback appelé quand un type d'événement est sélectionné
  final Function(EventType?) onEventTypeSelected;

  /// Icône du titre
  final IconData titleIcon;

  /// Couleur de l'icône du titre
  final Color titleIconColor;

  /// Couleur par défaut pour les événements sans couleur
  final Color defaultEventColor;

  /// Indique si le widget est en cours de chargement
  final bool isLoading;

  /// Indique si la sélection est obligatoire
  final bool isRequired;

  /// Padding du container principal
  final EdgeInsets? padding;

  /// Decoration du container principal
  final BoxDecoration? decoration;

  /// Afficher l'icône de l'événement sélectionné dans le champ
  final bool showSelectedIcon;

  const EventTypeSelectorWidget({
    Key? key,
    this.title = 'Pour quel événement ?',
    this.label = 'Choisir l\'occasion',
    this.placeholder = 'Sélectionner un événement',
    this.noneOptionLabel = 'Aucune occasion',
    required this.eventTypes,
    this.selectedEventType,
    required this.onEventTypeSelected,
    this.titleIcon = Icons.celebration,
    this.titleIconColor = Colors.purple,
    this.defaultEventColor = Colors.blue,
    this.isLoading = false,
    this.isRequired = false,
    this.padding,
    this.decoration,
    this.showSelectedIcon = true,
  }) : super(key: key);

  @override
  State<EventTypeSelectorWidget> createState() =>
      _EventTypeSelectorWidgetState();
}

class _EventTypeSelectorWidgetState extends State<EventTypeSelectorWidget> {
  // Default decoration
  BoxDecoration get _defaultDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      );

  EdgeInsets get _defaultPadding => const EdgeInsets.all(20);

  // ==================== COULEUR ====================

  Color _getEventTypeColor(EventType eventType) {
    try {
      final color = eventType.couleur;
      if (color != null && color.isNotEmpty) {
        // Support des formats: #RRGGBB, RRGGBB, 0xFFRRGGBB
        String colorString = color;
        if (colorString.startsWith('#')) {
          colorString = colorString.replaceFirst('#', '0xFF');
        } else if (!colorString.startsWith('0x')) {
          colorString = '0xFF$colorString';
        }
        return Color(int.parse(colorString));
      }
    } catch (e) {
      // Fallback en cas d'erreur de parsing
    }
    return widget.defaultEventColor;
  }

  // ==================== SÉLECTION ====================

  void _onEventTypeChanged(EventType? eventType) {
    widget.onEventTypeSelected(eventType);
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding ?? _defaultPadding,
      decoration: widget.decoration ?? _defaultDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildDropdown(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(widget.titleIcon, color: widget.titleIconColor, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              fontFamily: 'Nunito',
            ),
          ),
        ),
        if (!widget.isRequired)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Optionnel',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                fontFamily: 'Nunito',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdown() {
    if (widget.isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return DropdownButtonFormField2<EventType?>(
      value: widget.selectedEventType,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.placeholder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.titleIconColor, width: 2),
        ),
      ),
      hint: Text(widget.placeholder),
      dropdownStyleData: const DropdownStyleData(
        maxHeight: 300,
        padding: EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      menuItemStyleData: const MenuItemStyleData(
        padding: EdgeInsets.symmetric(horizontal: 16),
      ),
      items: _buildDropdownItems(),
      selectedItemBuilder:
          widget.showSelectedIcon ? null : _buildSelectedItemBuilder,
      onChanged: _onEventTypeChanged,
    );
  }

  Widget? _buildPrefixIcon() {
    if (!widget.showSelectedIcon) {
      return Icon(Icons.event, color: widget.titleIconColor);
    }

    if (widget.selectedEventType != null) {
      final imageUrl = widget.selectedEventType!.imageUrl;

      return Container(
        margin: const EdgeInsets.all(12),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _getEventTypeColor(widget.selectedEventType!).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: (imageUrl != null && imageUrl.isNotEmpty)
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    widget.selectedEventType!.iconData,
                    size: 16,
                    color: widget.titleIconColor,
                  ),
                )
              : Icon(
                  widget.selectedEventType!.iconData,
                  size: 16,
                  color: widget.titleIconColor,
                ),
        ),
      );
    }

    return Icon(Icons.event, color: widget.titleIconColor);
  }

// Modifiez uniquement la méthode _buildDropdownItems dans votre widget original :
  List<DropdownMenuItem<EventType>> _buildDropdownItems() {
    final items = <DropdownMenuItem<EventType>>[];
    final seenIds = <int>{};

    // Option "Aucune occasion" si non obligatoire
    if (!widget.isRequired) {
      items.add(
        DropdownMenuItem<EventType>(
          value: null,
          child: Row(
            children: [
              Icon(Icons.clear, size: 20, color: Colors.grey.shade400),
              const SizedBox(width: 12),
              Text(
                widget.noneOptionLabel,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Options des événements - FILTRER LES DOUBLONS
    for (final eventType in widget.eventTypes) {
      if (!seenIds.contains(eventType.id)) {
        seenIds.add(eventType.id);

        final color = _getEventTypeColor(eventType);
        items.add(
          DropdownMenuItem<EventType>(
            value: eventType,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: (eventType.imageUrl != null &&
                            eventType.imageUrl!.isNotEmpty)
                        ? Image.network(
                            eventType.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              eventType.iconData,
                              size: 18,
                              color: color,
                            ),
                          )
                        : Icon(
                            eventType.iconData,
                            size: 18,
                            color: color, // Use the event color for the icon
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    eventType.libelle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return items;
  }

  /// Builder personnalisé pour l'affichage de l'élément sélectionné
  /// (sans l'icône dans le champ de saisie)
  List<Widget> _buildSelectedItemBuilder(BuildContext context) {
    final allItems = <Widget>[];

    // Option "Aucune occasion"
    if (!widget.isRequired) {
      allItems.add(Text(widget.noneOptionLabel));
    }

    // Options des événements (juste le texte, sans icône)
    allItems.addAll(
      widget.eventTypes.map((eventType) => Text(eventType.libelle)),
    );

    return allItems;
  }
}
