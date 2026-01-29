import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/input.dart';
import '../../../../shared/widgets/link.dart';
import '../../../../shared/widgets/selection_tile.dart';
import '../../../product/presentation/providers/product_provider.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/domain/entities/entities.dart';

/// Page de recherche avec onglets Articles/Membres
///
/// Cette page affiche une barre de recherche avec suggestions en temps réel.
/// Les suggestions sont affichées pendant la frappe avec le widget SelectionTile.
class SearchingPage extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchingPage({super.key, this.initialQuery});

  @override
  ConsumerState<SearchingPage> createState() => _SearchingPageState();
}

class _SearchingPageState extends ConsumerState<SearchingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Suggestions pour l'onglet Articles
  List<String> _suggestions = [];

  // Suggestions pour l'onglet Membres
  List<User> _memberSuggestions = [];

  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Écouter les changements du champ de recherche
    _searchController.addListener(_onSearchChanged);

    // Pré-remplir le champ de recherche si une requête initiale est fournie
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        _searchController.text = widget.initialQuery!;
        // Déclencher la recherche automatiquement
        _performSearch(widget.initialQuery!);
      }
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Appelé à chaque changement dans le champ de recherche
  void _onSearchChanged() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _memberSuggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Simuler une recherche avec délai (debounce)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (query == _searchController.text.trim()) {
        // Lancer la recherche en fonction de l'onglet actif
        if (_tabController.index == 0) {
          // Onglet Articles
          _performSearch(query);
        } else {
          // Onglet Membres
          _performMemberSearch(query);
        }
      }
    });
  }

  /// Effectue la recherche et met à jour les suggestions
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    try {
      final queryLower = query.toLowerCase();

      // Récupérer les catégories et sous-catégories depuis Firestore
      final categoriesSnapshot = await ref
          .read(productRepositoryProvider)
          .getAllCategories();
      final subcategoriesSnapshot = await ref
          .read(productRepositoryProvider)
          .getAllSubcategories();

      final Set<String> uniqueSuggestions = {};

      // Ajouter les catégories qui matchent
      for (final category in categoriesSnapshot) {
        if (category.name.toLowerCase().contains(queryLower)) {
          uniqueSuggestions.add(category.name);
        }
      }

      // Ajouter les sous-catégories qui matchent
      for (final subcategory in subcategoriesSnapshot) {
        if (subcategory.name.toLowerCase().contains(queryLower)) {
          uniqueSuggestions.add(subcategory.name);
        }
      }

      setState(() {
        _suggestions = uniqueSuggestions.toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
    }
  }

  /// Effectue la recherche de membres par username
  ///
  /// Cette méthode recherche les utilisateurs dont le username
  /// correspond à la requête et met à jour [_memberSuggestions].
  Future<void> _performMemberSearch(String query) async {
    if (query.isEmpty) return;

    try {
      // Récupérer le repository d'authentification
      final authRepository = ref.read(authRepositoryProvider);

      // Rechercher les utilisateurs par username
      final users = await authRepository.searchUsersByUsername(query);

      setState(() {
        _memberSuggestions = users;
        _isSearching = false;
      });
    } catch (e) {
      // En cas d'erreur, afficher une liste vide
      setState(() {
        _memberSuggestions = [];
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Barre de recherche
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.scaffoldBackgroundColor,
              child: Row(
                children: [
                  // Champ de recherche
                  Expanded(
                    child: Input(
                      type: InputType.text,
                      placeholder: l10n.searchArticlesPlaceholder,
                      controller: _searchController,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Bouton Fermer
                  Link(
                    text: l10n.closeButton,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Onglets
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.searchArticlesTab),
                Tab(text: l10n.searchMembersTab),
              ],
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.textTheme.bodySmall?.color,
            ),

            // Contenu des onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Onglet Articles
                  _buildArticlesTab(context, l10n),

                  // Onglet Membres
                  _buildMembersTab(context, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit l'onglet de recherche d'articles
  Widget _buildArticlesTab(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    // Afficher un message si la recherche est vide
    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.searchTyping,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    // Afficher un loader pendant la recherche
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    // Afficher un message si aucun résultat
    if (_suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.searchNoResults,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    // Afficher les suggestions
    return ListView.builder(
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];

        return SelectionTile(
          label: suggestion,
          onTap: () {
            // Naviguer vers la page de résultats de recherche
            context.push('/search-results', extra: suggestion);
          },
          // Utiliser une flèche de suggestion (nord-ouest)
          trailingIcon: Icons.north_west,
        );
      },
    );
  }

  /// Construit l'onglet de recherche de membres
  ///
  /// Affiche les résultats de recherche d'utilisateurs avec :
  /// - Photo de profil (ou avatar générique avec initiale)
  /// - Username
  /// - Flèche de navigation
  Widget _buildMembersTab(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    // Afficher le message initial (avant toute saisie)
    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Recherchez des membres par leur nom d\'utilisateur',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    // Afficher un loader pendant la recherche
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    // Afficher un message si aucun résultat
    if (_memberSuggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun membre trouvé',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    // Afficher les résultats de recherche
    return ListView.builder(
      itemCount: _memberSuggestions.length,
      itemBuilder: (context, index) {
        final user = _memberSuggestions[index];

        return ListTile(
          // Avatar avec photo de profil ou initiale
          leading: CircleAvatar(
            radius: 20,
            backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? NetworkImage(user.photoUrl!)
                : null,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: user.photoUrl == null || user.photoUrl!.isEmpty
                ? Text(
                    user.username.isNotEmpty
                        ? user.username[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          title: Text(user.username, style: theme.textTheme.bodyLarge),
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          onTap: () {
            // TODO: Naviguer vers la page de profil de l'utilisateur
            // Pour le moment, on peut juste afficher le username
            context.push('/profile/${user.uid}');
          },
        );
      },
    );
  }
}
