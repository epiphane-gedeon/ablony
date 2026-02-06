import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../../shared/widgets/link.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/entities.dart';
import '../../../messages/application/providers/message_providers.dart';
import '../../../messages/domain/models/participant_details.dart';
import '../../../messages/domain/models/product_details.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import 'package:ablony/features/make_offer_feature/presentation/widgets/make_offer_bottom_sheet.dart';

/// Page de détail d'un produit
class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentImageIndex =
      0; // Index de l'image actuellement affichée dans le carrousel
  bool _isDescriptionExpanded =
      false; // État d'expansion de la description du produit
  Product? _product; // Produit actuellement affiché
  bool _isLoading = true; // Indicateur de chargement du produit principal
  User? _seller; // Données du vendeur (récupérées depuis Firestore)
  bool _isLoadingSeller =
      true; // Indicateur de chargement des données du vendeur
  String? _subcategoryName; // Nom de la sous-catégorie finale
  List<Product> _sellerProducts = []; // Liste des autres produits du vendeur
  List<Product> _similarProducts =
      []; // Liste des produits similaires (même sous-catégorie)
  bool _isLoadingTabData =
      true; // Indicateur de chargement des produits des onglets

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProduct();
  }

  /// Charge les données du produit depuis Firestore
  ///
  /// Cette méthode :
  /// 1. Récupère le produit par son ID
  /// 2. Charge les données du vendeur
  /// 3. Déclenche le chargement des produits des onglets
  Future<void> _loadProduct() async {
    try {
      final repository = ref.read(productRepositoryProvider);
      final product = await repository.getProductById(widget.productId);

      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
        });

        // Charger les données du vendeur
        _loadSeller(product.sellerId);

        // Charger le nom de la sous-catégorie
        _loadSubcategoryName(product.subcategoryId);

        // Charger les produits du vendeur et similaires
        _loadTabData(product);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Charge les données du vendeur depuis Firestore
  ///
  /// Récupère les informations complètes du vendeur (username, photo, etc.)
  /// pour les afficher dans la section profil du vendeur
  Future<void> _loadSeller(String sellerId) async {
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final seller = await authRepository.getUserById(sellerId);

      if (mounted) {
        setState(() {
          _seller = seller;
          _isLoadingSeller = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSeller = false;
        });
      }
    }
  }

  /// Charge le nom de la sous-catégorie depuis Firestore
  ///
  /// Récupère le nom de la sous-catégorie finale pour l'afficher
  /// dans la section "Catégorie" des détails du produit
  Future<void> _loadSubcategoryName(String subcategoryId) async {
    try {
      final categoryRepository = ref.read(categoryRepositoryProvider);
      final subcategory = await categoryRepository.getSubcategoryById(
        subcategoryId,
      );

      if (mounted) {
        setState(() {
          _subcategoryName = subcategory.name;
        });
      }
    } catch (e) {
      // En cas d'erreur, on laisse _subcategoryName à null
    }
  }

  /// Charge les produits à afficher dans les onglets
  ///
  /// Cette méthode charge :
  /// 1. Les autres produits du même vendeur (onglet "Dressing du membre")
  /// 2. Les produits de la même sous-catégorie (onglet "Articles similaires")
  ///
  /// Note : Le produit actuel est exclu des deux listes
  Future<void> _loadTabData(Product product) async {
    try {
      final repository = ref.read(productRepositoryProvider);

      // Charger les produits du vendeur (excluant le produit actuel)
      final sellerProducts = await repository.getProductsBySeller(
        product.sellerId,
      );
      final filteredSellerProducts = sellerProducts
          .where((p) => p.id != product.id)
          .toList();

      // Charger les produits similaires (même sous-catégorie, excluant le produit actuel)
      final categoryProducts = await repository.getProductsByCategory(
        categoryId: product.categoryId,
        subcategoryId: product.subcategoryId,
      );
      final filteredSimilarProducts = categoryProducts
          .where((p) => p.id != product.id)
          .toList();

      if (mounted) {
        setState(() {
          _sellerProducts = filteredSellerProducts;
          _similarProducts = filteredSimilarProducts;
          _isLoadingTabData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTabData = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_product == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text('Produit introuvable', style: theme.textTheme.titleLarge),
            ],
          ),
        ),
      );
    }

    final product = _product!;
    final images = product.imageUrls.isNotEmpty
        ? product.imageUrls
        : ['https://picsum.photos/400/600'];

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Carousel d'images
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 500,
                  child: Stack(
                    children: [
                      PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Image.network(
                            images[index],
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                      // Indicateur d'images (3 points)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            images.length,
                            (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Icône favoris avec nombre
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.favorite_border,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${product.favoritesCount}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Contenu
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      Text(
                        product.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Taille / État / Marque
                      Row(
                        children: [
                          // Taille
                          if (product.primarySizeValue != null) ...[
                            Text(
                              ref
                                      .watch(
                                        attributeLabelProvider((
                                          attributeId:
                                              product.primarySizeAttributeId!,
                                          value: product.primarySizeValue,
                                        )),
                                      )
                                      .value ??
                                  '',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(' · ', style: theme.textTheme.bodyMedium),
                          ],

                          // État
                          Text(
                            ref
                                    .watch(
                                      attributeLabelProvider((
                                        attributeId: 'condition',
                                        value: product.condition.index,
                                      )),
                                    )
                                    .value ??
                                product.condition.label,
                            style: theme.textTheme.bodyMedium,
                          ),

                          // Marque (si elle existe)
                          if (product.primaryBrandValue != null) ...[
                            Text(' · ', style: theme.textTheme.bodyMedium),
                            Link(
                              text:
                                  ref
                                      .watch(
                                        attributeLabelProvider((
                                          attributeId:
                                              product.primaryBrandAttributeId!,
                                          value: product.primaryBrandValue,
                                        )),
                                      )
                                      .value ??
                                  product.primaryBrandValue.toString(),
                              onTap: () {
                                // TODO: Rediriger vers la page de la marque
                              },
                              underline: true,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Prix
                      Text(
                        '${product.price.toStringAsFixed(2)} €',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${(product.price * 1.05).toStringAsFixed(2)} € ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            'Inclut la Protection acheteurs',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Icon(
                            Icons.verified_user,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Section Description
                      Text(
                        'Description',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Texte de la description (tronqué ou complet selon l'état)
                      Text(
                        _isDescriptionExpanded
                            ? product
                                  .description // Affiche toute la description
                            : product.description.length > 100
                            ? '${product.description.substring(0, 100)}...' // Tronque à 100 caractères
                            : product
                                  .description, // Description courte affichée en entier
                        style: theme.textTheme.bodyMedium,
                      ),

                      // Bouton "plus" pour afficher/masquer les détails du produit
                      Link(
                        text: 'plus',
                        onTap: () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                        },
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 16),

                      // Sections détaillées du produit (affichées après avoir cliqué sur "plus")
                      if (_isDescriptionExpanded) ...[
                        const Divider(height: 32),

                        // Catégorie finale (sous-catégorie)
                        _buildDetailRow(
                          theme,
                          'Catégorie',
                          _subcategoryName ?? product.subcategoryId,
                          showArrow: true,
                        ),
                        const Divider(height: 1),

                        // Taille
                        _buildDetailRow(
                          theme,
                          'Taille',
                          product.primarySizeValue != null
                              ? ref
                                        .watch(
                                          attributeLabelProvider((
                                            attributeId:
                                                product.primarySizeAttributeId!,
                                            value: product.primarySizeValue,
                                          )),
                                        )
                                        .value ??
                                    'Non spécifiée'
                              : 'Non spécifiée',
                          showArrow: true,
                        ),
                        const Divider(height: 1),

                        // État
                        _buildDetailRow(
                          theme,
                          'État',
                          ref
                                  .watch(
                                    attributeLabelProvider((
                                      attributeId: 'condition',
                                      value: product.condition.index,
                                    )),
                                  )
                                  .value ??
                              product.condition.label,
                          showArrow: true,
                        ),
                        const Divider(height: 1),

                        // Couleur
                        if (product.attributes['color'] != null)
                          _buildDetailRow(
                            theme,
                            'Couleur',
                            ref
                                    .watch(
                                      attributeLabelProvider((
                                        attributeId: 'color',
                                        value: product.attributes['color'],
                                      )),
                                    )
                                    .value ??
                                product.attributes['color'].toString(),
                            showArrow: false,
                          ),
                        if (product.attributes['color'] != null)
                          const Divider(height: 1),

                        // Date d'ajout
                        _buildDetailRow(
                          theme,
                          'Ajouté',
                          _formatTimeSince(product.createdAt),
                          showArrow: false,
                        ),

                        const SizedBox(height: 16),
                      ],

                      // Bouton traduire
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.language, size: 20),
                        label: const Text('Clique ici pour traduire'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section Profil du vendeur
                      _isLoadingSeller
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _seller != null
                          ? Row(
                              children: [
                                // Avatar du vendeur
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: _seller!.photoUrl != null
                                      ? NetworkImage(_seller!.photoUrl!)
                                      : null,
                                  child: _seller!.photoUrl == null
                                      ? Text(
                                          _seller!.username[0].toUpperCase(),
                                          style: theme.textTheme.titleLarge,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),

                                // Informations du vendeur (username + évaluations)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _seller!.username,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      // TODO: Ajouter les vraies évaluations depuis Firestore
                                      Row(
                                        children: [
                                          Row(
                                            children: List.generate(
                                              5,
                                              (index) => Icon(
                                                index < 4
                                                    ? Icons.star
                                                    : Icons.star_half,
                                                size: 16,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '(0)', // TODO: Afficher le vrai nombre d'évaluations
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Bouton Message pour contacter le vendeur
                                SecondaryButton(
                                  text: 'Message',
                                  onPressed: () async {
                                    final currentUser = ref
                                        .read(authStateProvider)
                                        .value;
                                    if (currentUser == null) return;

                                    // Vérifier si une conversation existe déjà
                                    final messageRepo = ref.read(
                                      messageRepositoryProvider,
                                    );
                                    String? conversationId = await messageRepo
                                        .findConversation(
                                          userId1: currentUser.uid,
                                          userId2: _product!.sellerId,
                                          productId: _product!.id,
                                        );

                                    // Si pas de conversation, la créer
                                    if (conversationId == null) {
                                      final authRepo = ref.read(
                                        authRepositoryProvider,
                                      );
                                      final buyer = await authRepo.getUserById(
                                        currentUser.uid,
                                      );
                                      final seller = await authRepo.getUserById(
                                        _product!.sellerId,
                                      );

                                      conversationId = await messageRepo
                                          .createConversation(
                                            buyerId: buyer.uid,
                                            sellerId: seller.uid,
                                            buyerDetails: ParticipantDetails(
                                              name: buyer.username,
                                              avatar: buyer.photoUrl,
                                            ),
                                            sellerDetails: ParticipantDetails(
                                              name: seller.username,
                                              avatar: seller.photoUrl,
                                            ),
                                            productId: _product!.id,
                                            productDetails: ProductDetails(
                                              title: _product!.title,
                                              price: _product!.price,
                                              image:
                                                  _product!.imageUrls.isNotEmpty
                                                  ? _product!.imageUrls.first
                                                  : null,
                                              sellerId: seller.uid,
                                            ),
                                          );
                                    }

                                    // Rediriger vers la conversation
                                    if (context.mounted) {
                                      context.push('/chat/$conversationId');
                                    }
                                  },
                                  isFullWidth: false,
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                      const SizedBox(height: 12),

                      // Badges
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.flash_on, size: 16),
                            label: const Text('Publie activement'),
                            backgroundColor: theme.colorScheme.primary
                                .withOpacity(0.1),
                            side: BorderSide.none,
                          ),
                          Chip(
                            avatar: const Icon(Icons.send, size: 16),
                            label: const Text('Envoie rapidement'),
                            backgroundColor: theme.colorScheme.primary
                                .withOpacity(0.1),
                            side: BorderSide.none,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Frais de Protection
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_user,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Frais de Protection acheteurs',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pour tout achat effectué par le biais du bouton Acheter, nous appliquons des frais couvrant notre Protection acheteurs.',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Onglets
                      TabBar(
                        controller: _tabController,
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: theme.textTheme.bodySmall?.color,
                        indicatorColor: theme.colorScheme.primary,
                        tabs: const [
                          Tab(text: 'Dressing du membre'),
                          Tab(text: 'Articles similaires'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Contenu des onglets
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 600,
                  child: _isLoadingTabData
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildProductGrid(theme, _sellerProducts),
                            _buildProductGrid(theme, _similarProducts),
                          ],
                        ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // Bouton retour (fixe en haut à gauche)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.5),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // Menu 3 points (fixe en haut à droite)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.5),
              child: IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.white),
                onPressed: () {},
              ),
            ),
          ),

          // Boutons d'action fixes en bas de l'écran
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Bouton "Faire une offre" (action secondaire)
                  Expanded(
                    child: SecondaryButton(
                      text: 'Faire une offre',
                      onPressed: () {
                        if (_product != null) {
                          MakeOfferBottomSheet.show(context, _product!);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Bouton "Acheter" (action principale)
                  Expanded(
                    child: PrimaryButton(
                      text: 'Acheter',
                      onPressed: () {
                        // TODO: Rediriger vers la page de paiement
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une ligne de détail avec label et valeur
  ///
  /// [theme] Le thème de l'application
  /// [label] Le label à gauche (ex: "Catégorie", "Taille")
  /// [value] La valeur à droite
  /// [showArrow] Si true, affiche une flèche à droite (pour indiquer que c'est cliquable)
  Widget _buildDetailRow(
    ThemeData theme,
    String label,
    String value, {
    bool showArrow = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          Row(
            children: [
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              if (showArrow) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: theme.textTheme.bodySmall?.color,
                  size: 20,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Formate le temps écoulé depuis la création du produit
  ///
  /// Retourne une chaîne comme "Il y a 2 heures", "Il y a 3 jours", etc.
  String _formatTimeSince(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years ${years == 1 ? 'an' : 'ans'}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} ${difference.inDays == 1 ? 'jour' : 'jours'}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} ${difference.inHours == 1 ? 'heure' : 'heures'}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'}';
    } else {
      return 'À l\'instant';
    }
  }

  /// Construit la grille de produits pour les onglets
  ///
  /// Cette méthode affiche une grille de produits (2 colonnes) avec :
  /// - Un message "Aucun produit disponible" si la liste est vide
  /// - Une grille de ProductCard sinon
  ///
  /// [theme] Le thème de l'application pour le style
  /// [products] La liste des produits à afficher
  Widget _buildProductGrid(ThemeData theme, List<Product> products) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: products.isEmpty
          // Affiche un message si aucun produit n'est disponible
          ? Center(
              child: Text(
                'Aucun produit disponible',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            )
          // Affiche la grille de produits
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 colonnes
                childAspectRatio: 0.5, // Ratio hauteur/largeur de chaque carte
                crossAxisSpacing: 12, // Espacement horizontal entre les cartes
                mainAxisSpacing: 16, // Espacement vertical entre les cartes
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onTap: () {
                    context.push('/product/${product.id}');
                  },
                );
              },
            ),
    );
  }
}
