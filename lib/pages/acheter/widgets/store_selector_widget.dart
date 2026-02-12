import 'package:flutter/material.dart';

import '../../../data/models/boutique_model.dart';

/// Widget réutilisable pour sélectionner une boutique avec recherche
class StoreSelectorWidget extends StatefulWidget {
  /// Titre du widget
  final String title;

  /// Liste des boutiques disponibles
  final List<Boutique> stores;

  /// Boutique actuellement sélectionnée
  final Boutique? selectedStore;

  /// Callback appelé quand une boutique est sélectionnée
  final Function(Boutique) onStoreSelected;

  /// Placeholder quand aucune boutique n'est sélectionnée
  final String placeholder;

  /// URL du logo par défaut
  final String defaultLogoUrl;

  /// Couleur primaire du thème
  final Color primaryColor;

  /// Icône du titre
  final IconData? titleIcon;

  /// Afficher la description dans les résultats
  final bool showDescription;

  /// Padding du container principal
  final EdgeInsets? padding;

  /// Margin du container principal
  final EdgeInsets? margin;

  /// Indique si le widget est en cours de chargement
  final bool isLoading;

  /// Message à afficher quand aucune boutique n'est disponible
  final String emptyMessage;

  const StoreSelectorWidget({
    super.key,
    this.title = 'Choix du supermarché / boutique',
    required this.stores,
    this.selectedStore,
    required this.onStoreSelected,
    this.placeholder = 'Sélectionner une boutique',
    this.defaultLogoUrl =
        'https://res.cloudinary.com/dmlozs3uk/image/upload/v1758204981/istockphoto-1174549062-612x612_ajteum.jpg',
    this.primaryColor = const Color(0xFF2F55E0),
    this.titleIcon,
    this.showDescription = true,
    this.padding,
    this.margin,
    this.isLoading = false,
    this.emptyMessage = 'Aucune boutique disponible',
  });

  @override
  State<StoreSelectorWidget> createState() => _StoreSelectorWidgetState();
}

class _StoreSelectorWidgetState extends State<StoreSelectorWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Boutique> _filteredStores = [];
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _filteredStores = widget.stores;
    _searchController.addListener(_filterStores);
  }

  @override
  void didUpdateWidget(StoreSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mettre à jour la liste filtrée si les boutiques changent
    if (oldWidget.stores != widget.stores) {
      _filteredStores = widget.stores;
      _filterStores();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==================== FILTRAGE ====================

  void _filterStores() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredStores = widget.stores;
      } else {
        _filteredStores = widget.stores.where((store) {
          final matchName = store.name.toLowerCase().contains(query);
          final matchDescription =
              store.description?.toLowerCase().contains(query) ?? false;
          return matchName || matchDescription;
        }).toList();
      }
    });
  }

  // ==================== SÉLECTION ====================

  void _selectStore(Boutique store) {
    widget.onStoreSelected(store);
    setState(() {
      _isSearchExpanded = false;
      _searchController.clear();
      _filteredStores = widget.stores;
    });
  }

  // ==================== VALIDATION URL ====================

  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasScheme &&
        (uri.isScheme("http") || uri.isScheme("https"));
  }

  String _getLogoUrl(Boutique? store) {
    if (store != null && _isValidUrl(store.logoUrl)) {
      return store.logoUrl!;
    }
    return widget.defaultLogoUrl;
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildStoreSelector(),
            if (_isSearchExpanded) ...[
              const SizedBox(height: 12),
              _buildSearchField(),
              const SizedBox(height: 8),
              _buildStoreList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (widget.titleIcon != null) ...[
          Icon(widget.titleIcon, color: widget.primaryColor, size: 24),
          const SizedBox(width: 8),
        ],
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
      ],
    );
  }

  Widget _buildStoreSelector() {
    if (widget.isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
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

    return GestureDetector(
      onTap: () {
        if (widget.stores.isNotEmpty) {
          setState(() {
            _isSearchExpanded = !_isSearchExpanded;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            _buildStoreLogo(),
            const SizedBox(width: 12),
            Expanded(child: _buildStoreText()),
            Icon(
              _isSearchExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreLogo() {
    return ClipOval(
      child: Image.network(
        _getLogoUrl(widget.selectedStore),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.network(
            widget.defaultLogoUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback ultime: icône
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.store,
                  color: widget.primaryColor,
                  size: 24,
                ),
              );
            },
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoreText() {
    return Text(
      widget.selectedStore?.name ?? widget.placeholder,
      style: TextStyle(
        fontSize: 14,
        color: widget.selectedStore != null ? Colors.black87 : Colors.grey[600],
        fontWeight:
            widget.selectedStore != null ? FontWeight.w500 : FontWeight.normal,
        fontFamily: 'Nunito',
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Rechercher une boutique...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      autofocus: true,
    );
  }

  Widget _buildStoreList() {
    if (_filteredStores.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            _searchController.text.isEmpty
                ? widget.emptyMessage
                : 'Aucune boutique trouvée pour "${_searchController.text}"',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontFamily: 'Nunito',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _filteredStores.length,
        itemBuilder: (context, index) {
          final store = _filteredStores[index];
          final isSelected = widget.selectedStore?.slug == store.slug;

          return ListTile(
            leading: _buildStoreListLogo(store, isSelected),
            title: Text(
              store.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? widget.primaryColor : Colors.black87,
                fontFamily: 'Nunito',
              ),
            ),
            subtitle: widget.showDescription && store.description != null
                ? Text(
                    store.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontFamily: 'Nunito',
                    ),
                  )
                : null,
            onTap: () => _selectStore(store),
            selected: isSelected,
            selectedTileColor: widget.primaryColor.withOpacity(0.05),
          );
        },
      ),
    );
  }

  Widget _buildStoreListLogo(Boutique store, bool isSelected) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isSelected
            ? widget.primaryColor.withOpacity(0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipOval(
        child: Image.network(
          _getLogoUrl(store),
          width: 30,
          height: 30,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.store,
              color: isSelected ? widget.primaryColor : Colors.grey,
              size: 20,
            );
          },
        ),
      ),
    );
  }
}
