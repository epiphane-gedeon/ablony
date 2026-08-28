import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../../shared/widgets/link.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../product_fav/presentation/providers/product_fav_provider.dart';
import '../../../product_fav/presentation/widgets/fav_toggle.dart';
import '../../domain/entities/entities.dart';
import '../../../messages/application/providers/message_providers.dart';
import '../../../messages/domain/models/participant_details.dart';
import '../../../messages/domain/models/product_details.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../providers/paginated_products_provider.dart';
import '../../../reviews/presentation/widgets/star_rating.dart';
import '../../../receipt/presentation/providers/receipt_provider.dart';
import '../../../reports/presentation/widgets/report_product_dialog.dart';
import '../../../share/domain/models/shareable_content.dart';
import '../../../share/presentation/services/share_service.dart';
import 'package:ablony/features/make_offer_feature/presentation/widgets/make_offer_bottom_sheet.dart';
import 'package:ablony/features/sell/presentation/widgets/sell_bottom_sheet.dart';
import '../widgets/boost_bottom_sheet.dart';

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
          .where(
            (p) =>
                p.id != product.id &&
                !p.isSold &&
                !p.isReserved &&
                !p.isHidden,
          )
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
              Text(
                AppLocalizations.of(context)!.productNotFound,
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
        ),
      );
    }

    final product = _product!;
    final currentUser = ref.watch(authStateProvider).value;
    final isSeller = currentUser != null && currentUser.uid == product.sellerId;

    final favoriteCountAsync = ref.watch(
      productFavoriteCountProvider(product.id),
    );
    final favoriteCount = favoriteCountAsync.value ?? product.favoritesCount;
    final images = product.imageUrls.isNotEmpty
        ? product.imageUrls
        : ['https://picsum.photos/400/600'];

    // Accessible via un lien partagé (cf. lib/features/share/) : lancée à
    // froid, cette page peut être la toute première route, sans rien en
    // dessous dans la pile. Un back (bouton ou geste système) doit alors
    // ramener à l'accueil plutôt que laisser un écran noir / quitter l'app.
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        body: ContentContainer(
          applyPadding: false,
          maxWidth: ContentWidth.standard,
          child: Stack(
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
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
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
                          // Toggle favoris (uniquement pour les acheteurs)
                          if (!isSeller)
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
                                    FavToggle(productId: product.id, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$favoriteCount',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.white),
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
                                              attributeId: product
                                                  .primarySizeAttributeId!,
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
                                              attributeId: product
                                                  .primaryBrandAttributeId!,
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
                            '${product.price.toStringAsFixed(2)} FCFA',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${(product.price * 1.05).toStringAsFixed(2)} FCFA ${AppLocalizations.of(context)!.priceIncl} ',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Icon(
                                Icons.verified_user,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.subtotalForBuyer,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Section Description
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.productDescriptionTitle,
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
                            text: _isDescriptionExpanded
                                ? AppLocalizations.of(context)!.readLess
                                : AppLocalizations.of(context)!.readMore,
                            onTap: () {
                              setState(() {
                                _isDescriptionExpanded =
                                    !_isDescriptionExpanded;
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
                              AppLocalizations.of(context)!.productCategory,
                              _subcategoryName ?? product.subcategoryId,
                              showArrow: true,
                            ),
                            const Divider(height: 1),

                            // Taille
                            _buildDetailRow(
                              theme,
                              AppLocalizations.of(context)!.productSize,
                              product.primarySizeValue != null
                                  ? ref
                                            .watch(
                                              attributeLabelProvider((
                                                attributeId: product
                                                    .primarySizeAttributeId!,
                                                value: product.primarySizeValue,
                                              )),
                                            )
                                            .value ??
                                        AppLocalizations.of(
                                          context,
                                        )!.notSpecified
                                  : AppLocalizations.of(context)!.notSpecified,
                              showArrow: true,
                            ),
                            const Divider(height: 1),

                            // État
                            _buildDetailRow(
                              theme,
                              AppLocalizations.of(context)!.productCondition,
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
                                AppLocalizations.of(context)!.productColor,
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
                              AppLocalizations.of(context)!.productAddedDate,
                              _formatTimeSince(context, product.createdAt),
                              showArrow: false,
                            ),

                            const SizedBox(height: 16),
                          ],

                          // Bouton traduire
                          if (!isSeller) ...[
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.language, size: 20),
                              label: Text(
                                AppLocalizations.of(context)!.clickToTranslate,
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Section Profil du vendeur (cachée si c'est le vendeur lui-même)
                          if (!isSeller) ...[
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
                                      // Avatar du vendeur (cliquable → profil public)
                                      GestureDetector(
                                        onTap: () => context.push(
                                          '/profile/${_seller!.uid}',
                                        ),
                                        child: CircleAvatar(
                                          radius: 24,
                                          backgroundImage:
                                              _seller!.photoUrl != null
                                              ? NetworkImage(_seller!.photoUrl!)
                                              : null,
                                          child: _seller!.photoUrl == null
                                              ? Text(
                                                  _seller!.username[0]
                                                      .toUpperCase(),
                                                  style: theme
                                                      .textTheme
                                                      .titleLarge,
                                                )
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Informations du vendeur (username + évaluations — cliquables)
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => context.push(
                                            '/profile/${_seller!.uid}',
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _seller!.username,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              StarRatingDisplay(
                                                rating: _seller!.rating,
                                                reviewsCount:
                                                    _seller!.reviewsCount,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Bouton Message pour contacter le vendeur
                                      SecondaryButton(
                                        text: AppLocalizations.of(
                                          context,
                                        )!.messageButton,
                                        onPressed: () async {
                                          final currentUser = ref
                                              .read(authStateProvider)
                                              .value;
                                          if (currentUser == null) return;

                                          final messageRepo = ref.read(
                                            messageRepositoryProvider,
                                          );
                                          String? conversationId =
                                              await messageRepo
                                                  .findConversation(
                                                    userId1: currentUser.uid,
                                                    userId2: _product!.sellerId,
                                                    productId: _product!.id,
                                                  );

                                          if (conversationId == null) {
                                            final authRepo = ref.read(
                                              authRepositoryProvider,
                                            );
                                            final buyer = await authRepo
                                                .getUserById(currentUser.uid);
                                            final seller = await authRepo
                                                .getUserById(
                                                  _product!.sellerId,
                                                );

                                            conversationId = await messageRepo
                                                .createConversation(
                                                  buyerId: buyer.uid,
                                                  sellerId: seller.uid,
                                                  buyerDetails:
                                                      ParticipantDetails(
                                                        name: buyer.username,
                                                        avatar: buyer.photoUrl,
                                                      ),
                                                  sellerDetails:
                                                      ParticipantDetails(
                                                        name: seller.username,
                                                        avatar: seller.photoUrl,
                                                      ),
                                                  productId: _product!.id,
                                                  productDetails:
                                                      ProductDetails(
                                                        title: _product!.title,
                                                        price: _product!.price,
                                                        image:
                                                            _product!
                                                                .imageUrls
                                                                .isNotEmpty
                                                            ? _product!
                                                                  .imageUrls
                                                                  .first
                                                            : null,
                                                        sellerId: seller.uid,
                                                      ),
                                                );
                                          }

                                          if (context.mounted) {
                                            context.push(
                                              '/chat/$conversationId',
                                            );
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
                                  label: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.activelyPublishes,
                                  ),
                                  backgroundColor: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                  side: BorderSide.none,
                                ),
                                Chip(
                                  avatar: const Icon(Icons.send, size: 16),
                                  label: Text(
                                    AppLocalizations.of(context)!.sendsQuickly,
                                  ),
                                  backgroundColor: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                  side: BorderSide.none,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Frais de Protection
                          if (!isSeller) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.1,
                                ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.buyerProtectionTitle,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.buyerProtectionDescription,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Onglets
                          TabBar(
                            controller: _tabController,
                            labelColor: theme.colorScheme.primary,
                            unselectedLabelColor:
                                theme.textTheme.bodySmall?.color,
                            indicatorColor: theme.colorScheme.primary,
                            tabs: [
                              Tab(
                                text: AppLocalizations.of(
                                  context,
                                )!.membersWardrobe,
                              ),
                              Tab(
                                text: AppLocalizations.of(
                                  context,
                                )!.similarItems,
                              ),
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
                    onPressed: () => Navigator.of(context).canPop()
                        ? Navigator.of(context).pop()
                        : context.go('/home'),
                  ),
                ),
              ),

              // Menu 3 points (fixe en haut à droite) - différent selon vendeur/acheteur
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: isSeller
                      ? PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_horiz,
                            color: Colors.white,
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'vendu':
                                _handleMarkAsSold(context, ref, product.id);
                                break;
                              case 'reserve':
                                _handleMarkAsReserved(
                                  context,
                                  ref,
                                  product.id,
                                  !product.isReserved,
                                );
                                break;
                              case 'modifier':
                                SellBottomSheet.show(
                                  context,
                                  initialProduct: product,
                                );
                                break;
                              case 'masquer':
                                _handleToggleHidden(
                                  context,
                                  ref,
                                  product.id,
                                  !product.isHidden,
                                );
                                break;
                              case 'supprimer':
                                _handleDeleteProduct(context, ref, product.id);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            // Vendre/réserver n'a plus de sens une fois le
                            // produit déjà vendu.
                            if (!product.isSold) ...[
                              PopupMenuItem(
                                value: 'vendu',
                                child: Text(
                                  AppLocalizations.of(context)!.markAsSold,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'reserve',
                                child: Text(
                                  product.isReserved
                                      ? AppLocalizations.of(
                                          context,
                                        )!.cancelReservation
                                      : AppLocalizations.of(
                                          context,
                                        )!.markAsReserved,
                                ),
                              ),
                            ],
                            PopupMenuItem(
                              value: 'modifier',
                              child: Text(AppLocalizations.of(context)!.edit),
                            ),
                            // Masquer/republier n'a d'intérêt que pour une
                            // annonce encore en vente.
                            if (!product.isSold)
                              PopupMenuItem(
                                value: 'masquer',
                                child: Text(
                                  product.isHidden
                                      ? AppLocalizations.of(context)!.unhide
                                      : AppLocalizations.of(context)!.hide,
                                ),
                              ),
                            PopupMenuItem(
                              value: 'supprimer',
                              child: Text(
                                AppLocalizations.of(context)!.deleteProduct,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        )
                      : PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_horiz,
                            color: Colors.white,
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'partager':
                                _shareProduct(context, product);
                                break;
                              case 'signaler':
                                ReportProductDialog.show(
                                  context,
                                  productId: product.id,
                                  productTitle: product.title,
                                  sellerId: product.sellerId,
                                );
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'partager',
                              child: Row(
                                children: [
                                  const Icon(Icons.share, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    AppLocalizations.of(context)!.shareProduct,
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'signaler',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.flag_outlined,
                                    size: 20,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    AppLocalizations.of(context)!.reportProduct,
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                  child: isSeller
                      ? (product.isSold
                            // Vue Vendeur, article vendu : code QR de remise en main propre
                            ? _buildSellerDeliveryButton(
                                context,
                                ref,
                                product,
                                currentUser.uid,
                              )
                            // Vue Vendeur, article en vente : Booster + Partager
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PrimaryButton(
                                    text: AppLocalizations.of(
                                      context,
                                    )!.boostProduct,
                                    onPressed: () {
                                      BoostBottomSheet.show(context, product);
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  SecondaryButton(
                                    text: AppLocalizations.of(
                                      context,
                                    )!.shareProduct,
                                    icon: Icons.share,
                                    onPressed: () =>
                                        _shareProduct(context, product),
                                  ),
                                ],
                              ))
                      : (product.isSold
                            // Vue Acheteur, article vendu : confirmer la réception (si c'est bien son achat)
                            ? _buildBuyerDeliveryButton(
                                context,
                                ref,
                                product,
                                currentUser?.uid,
                              )
                            // Vue Acheteur, article réservé : ni offre ni achat possible
                            : product.isReserved
                            ? PrimaryButton(
                                text: AppLocalizations.of(
                                  context,
                                )!.productReserved,
                                onPressed: null,
                              )
                            // Vue Acheteur, annonce masquée : accès via un ancien lien
                            // direct uniquement, ni offre ni achat possible
                            : product.isHidden
                            ? PrimaryButton(
                                text: AppLocalizations.of(
                                  context,
                                )!.productUnavailable,
                                onPressed: null,
                              )
                            // Vue Acheteur, article en vente : Faire une offre + Acheter
                            : Row(
                                children: [
                                  Expanded(
                                    child: SecondaryButton(
                                      text: AppLocalizations.of(
                                        context,
                                      )!.makeOffer,
                                      onPressed: () {
                                        if (_product != null) {
                                          MakeOfferBottomSheet.show(
                                            context,
                                            _product!,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: PrimaryButton(
                                      text: AppLocalizations.of(
                                        context,
                                      )!.buyNow,
                                      onPressed: () {
                                        if (_product != null) {
                                          context.push(
                                            '/payment',
                                            extra: _product,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bouton "Afficher le code QR" côté vendeur, une fois l'article vendu.
  /// L'acheteur scanne ce code pour confirmer la réception et débloquer
  /// le paiement (pendingAmount → availableAmount).
  Widget _buildSellerDeliveryButton(
    BuildContext context,
    WidgetRef ref,
    Product product,
    String sellerId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final receiptAsync = ref.watch(
      receiptForSellerProvider((product.id, sellerId)),
    );

    return receiptAsync.when(
      data: (receipt) {
        if (receipt == null || receipt.qrCodeId == null) {
          return PrimaryButton(
            text: l10n.showDeliveryQrButton,
            onPressed: null,
          );
        }
        return PrimaryButton(
          text: receipt.deliveryConfirmed
              ? l10n.deliveryAlreadyConfirmed
              : l10n.showDeliveryQrButton,
          icon: Icons.qr_code,
          onPressed: () => context.push(
            '/delivery/show-qr',
            extra: {
              'qrCodeId': receipt.qrCodeId,
              'deliveryConfirmed': receipt.deliveryConfirmed,
            },
          ),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stack) =>
          PrimaryButton(text: l10n.showDeliveryQrButton, onPressed: null),
    );
  }

  /// Bouton "Confirmer la réception" côté acheteur, une fois l'article vendu
  /// — affiché uniquement si l'utilisateur courant est bien l'acheteur.
  Widget _buildBuyerDeliveryButton(
    BuildContext context,
    WidgetRef ref,
    Product product,
    String? currentUserId,
  ) {
    final l10n = AppLocalizations.of(context)!;

    if (currentUserId == null) {
      return PrimaryButton(text: l10n.productAlreadySold, onPressed: null);
    }

    final receiptAsync = ref.watch(
      receiptForBuyerProvider((product.id, currentUserId)),
    );

    return receiptAsync.when(
      data: (receipt) {
        if (receipt == null) {
          return PrimaryButton(text: l10n.productAlreadySold, onPressed: null);
        }
        if (receipt.deliveryConfirmed) {
          return PrimaryButton(
            text: l10n.deliveryAlreadyConfirmed,
            icon: Icons.check_circle_outline,
            onPressed: null,
          );
        }
        return PrimaryButton(
          text: l10n.confirmDeliveryButton,
          icon: Icons.qr_code_scanner,
          onPressed: () => context.push('/delivery/scan-qr'),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stack) =>
          PrimaryButton(text: l10n.productAlreadySold, onPressed: null),
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
  /// Retourne une chaîne localisée comme "1 year ago", "Il y a 3 jours", etc.
  String _formatTimeSince(BuildContext context, DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? l10n.timeAgoYear : l10n.timeAgoYears(years);
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return l10n.timeAgoMonths(months);
    } else if (difference.inDays > 0) {
      return difference.inDays == 1
          ? l10n.timeAgoDay
          : l10n.timeAgoDays(difference.inDays);
    } else if (difference.inHours > 0) {
      return difference.inHours == 1
          ? l10n.timeAgoHour
          : l10n.timeAgoHours(difference.inHours);
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1
          ? l10n.timeAgoMinute
          : l10n.timeAgoMinutes(difference.inMinutes);
    } else {
      return l10n.timeAgoJustNow;
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
                AppLocalizations.of(context)!.noProductsAvailable,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            )
          // Affiche la grille de produits
          : ResponsiveProductGrid<Product>(
              padding: EdgeInsets.zero,
              itemsBuilder: (_) => products,
              itemBuilder: (context, product) {
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

  /// Partage la fiche produit via la fonctionnalité de partage centralisée
  /// (cf. `lib/features/share/`), qui génère le lien et ouvre le sheet natif.
  void _shareProduct(BuildContext context, Product product) {
    final l10n = AppLocalizations.of(context)!;
    ref
        .read(shareServiceProvider)
        .share(
          context,
          ShareableContent.product(
            id: product.id,
            title: product.title,
            subtitle: l10n.shareProductSubtitle(
              product.price.toStringAsFixed(0),
              product.condition.label,
            ),
          ),
        );
  }

  /// Marque le produit comme vendu
  Future<void> _handleMarkAsSold(
    BuildContext context,
    WidgetRef ref,
    String productId,
  ) async {
    try {
      await ref.read(productRepositoryProvider).markAsSold(productId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.productMarkedAsSold),
            backgroundColor: Colors.green,
          ),
        );
        // Rafraîchir les providers pour mettre à jour l'UI partout
        ref.invalidate(productByIdProvider(productId));
        ref.invalidate(paginatedProductsProvider);
        if (_product != null) {
          ref.invalidate(sellerProductsProvider(_product!.sellerId));
        }
        ref.invalidate(allProductsProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorGenericMsg(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Marque ou démarque le produit comme réservé — contrairement à
  /// [_handleMarkAsSold], réversible : le vendeur peut annuler la
  /// réservation depuis ce même menu si la vente ne se fait finalement pas.
  Future<void> _handleMarkAsReserved(
    BuildContext context,
    WidgetRef ref,
    String productId,
    bool reserve,
  ) async {
    try {
      final repository = ref.read(productRepositoryProvider);
      if (reserve) {
        await repository.markAsReserved(productId);
      } else {
        await repository.unmarkAsReserved(productId);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reserve
                  ? AppLocalizations.of(context)!.productMarkedAsReserved
                  : AppLocalizations.of(context)!.reservationCancelled,
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Rafraîchir les providers pour mettre à jour l'UI partout
        ref.invalidate(productByIdProvider(productId));
        ref.invalidate(paginatedProductsProvider);
        if (_product != null) {
          ref.invalidate(sellerProductsProvider(_product!.sellerId));
        }
        ref.invalidate(allProductsProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorGenericMsg(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Masque ou republie l'annonce — retirée des listes publiques (accueil,
  /// recherche, profil public) sans être vendue ni supprimée.
  Future<void> _handleToggleHidden(
    BuildContext context,
    WidgetRef ref,
    String productId,
    bool hide,
  ) async {
    try {
      final repository = ref.read(productRepositoryProvider);
      if (hide) {
        await repository.hideProduct(productId);
      } else {
        await repository.unhideProduct(productId);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hide
                  ? AppLocalizations.of(context)!.productHidden
                  : AppLocalizations.of(context)!.productUnhidden,
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Rafraîchir les providers pour mettre à jour l'UI partout
        ref.invalidate(productByIdProvider(productId));
        ref.invalidate(paginatedProductsProvider);
        if (_product != null) {
          ref.invalidate(sellerProductsProvider(_product!.sellerId));
        }
        ref.invalidate(allProductsProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorGenericMsg(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Supprime le produit après confirmation
  Future<void> _handleDeleteProduct(
    BuildContext context,
    WidgetRef ref,
    String productId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteProductConfirm),
        content: Text(
          AppLocalizations.of(context)!.deleteProductConfirmationMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.deleteProductBtn,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(productRepositoryProvider).deleteProduct(productId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.productDeletedSuccess,
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Rafraîchir les providers et quitter la page
          ref.invalidate(paginatedProductsProvider);
          if (_product != null) {
            ref.invalidate(sellerProductsProvider(_product!.sellerId));
          }
          ref.invalidate(allProductsProvider);
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.errorGenericMsg(e.toString()),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
