import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/utils/category_translator.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ablony/core/presentation/pages/selection_screen.dart';
import 'package:ablony/core/presentation/dynamic_ui/dynamic_selection_view.dart';
import 'package:ablony/shared/widgets/selection_tile.dart';
import 'package:ablony/shared/widgets/input.dart';
import 'package:ablony/features/product/presentation/providers/category_provider.dart';
import 'package:ablony/features/product/presentation/providers/product_provider.dart';
import 'package:ablony/features/product/presentation/providers/paginated_products_provider.dart';
import 'package:ablony/features/product/domain/entities/product_attribute.dart';
import 'package:ablony/features/product/domain/entities/entities.dart';
import 'package:ablony/features/auth/application/auth_providers.dart';
import 'package:ablony/features/sell/data/services/image_upload_service.dart';
import '../widgets/image_picker_grid.dart';
import '../../../../core/responsive/responsive.dart';

/// Bottom sheet plein écran pour créer une annonce.
///
/// Permet à l'utilisateur de :
/// - Ajouter 1-6 photos
/// - Saisir titre et description
/// - Sélectionner catégorie, état, prix
/// - Remplir les attributs dynamiques selon la catégorie
class SellBottomSheet extends ConsumerStatefulWidget {
  /// Produit initial pour le mode édition (optionnel)
  final Product? initialProduct;

  const SellBottomSheet({
    super.key,
    this.initialProduct,
  });

  /// Affiche le bottom sheet en plein écran
  static void show(BuildContext context, {Product? initialProduct}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SellBottomSheet(initialProduct: initialProduct),
    );
  }

  @override
  ConsumerState<SellBottomSheet> createState() => _SellBottomSheetState();
}

class _SellBottomSheetState extends ConsumerState<SellBottomSheet> {
  // ============================================================
  // CONTRÔLEURS DE FORMULAIRE
  // ============================================================

  /// Contrôleur pour le champ titre du produit
  final _titleController = TextEditingController();

  /// Contrôleur pour le champ description du produit
  final _descriptionController = TextEditingController();

  /// Contrôleur pour le champ prix (en FCFA)
  final _priceController = TextEditingController();

  // ============================================================
  // ÉTAT DU FORMULAIRE
  // ============================================================

  /// Liste des images (peut contenir des File ou des String URL en mode édition)
  List<dynamic> _selectedImages = [];

  /// Nom de la catégorie sélectionnée (pour affichage)
  String? _selectedCategory;

  /// ID de la catégorie finale sélectionnée (ex: "chemise_femme")
  /// Cet ID sera stocké dans le champ subcategoryId du Product
  String? _selectedCategoryId;

  /// ID de la catégorie parente (ex: "femme")
  /// Cet ID sera stocké dans le champ categoryId du Product
  String? _selectedParentCategoryId;

  /// Liste des attributs dynamiques de la catégorie sélectionnée
  /// (ex: Marque, Taille, Couleur pour les vêtements)
  List<ProductAttribute> _categoryAttributes = [];

  /// Valeurs des attributs remplis par l'utilisateur
  /// Map où key = ID de l'attribut, value = valeur sélectionnée
  /// Exemple: {'brand': 'Nike', 'size_haut': 'M', 'color': 'Bleu'}
  Map<String, dynamic> _attributeValues = {};

  /// Indique si la création du produit est en cours
  /// (upload images + enregistrement Firestore)
  bool _isPublishing = false;

  // ============================================================
  // CYCLE DE VIE
  // ============================================================

  @override
  void initState() {
    super.initState();

    // Initialisation en mode édition
    if (widget.initialProduct != null) {
      final p = widget.initialProduct!;

      _titleController.text = p.title;
      _descriptionController.text = p.description;
      _priceController.text = p.price.toString();

      _selectedImages = List<dynamic>.from(p.imageUrls);
      _selectedCategoryId = p.subcategoryId;
      _selectedParentCategoryId = p.categoryId;

      // Copier les attributs
      _attributeValues = Map<String, dynamic>.from(p.attributes);

      // Charger les attributs et le nom de la catégorie
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeEditMode();
      });
    }
  }

  /// Charge les données nécessaires pour le mode édition (noms, attributs)
  Future<void> _initializeEditMode() async {
    if (_selectedCategoryId == null) return;

    try {
      final l10n = AppLocalizations.of(context)!;
      // 1. Récupérer le nom de la catégorie
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final subcat = await categoryRepo.getSubcategoryById(_selectedCategoryId!);

      setState(() {
        _selectedCategory = CategoryTranslator.translate(l10n, subcat.id, subcat.name);
      });

      // 2. Charger les attributs dynamiques
      if (subcat.attributes.isNotEmpty) {
        final attributesRequest = await categoryRepo.getAttributesByIds(subcat.attributes);
        setState(() {
          _categoryAttributes = attributesRequest;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du mode édition : $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      height: screenHeight, // Plein écran
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // AppBar
          _buildAppBar(context, theme, l10n),

          // Contenu scrollable
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grille de photos
                  ImagePickerGrid(
                    images: _selectedImages,
                    onImagesChanged: (newImages) {
                      setState(() => _selectedImages = newImages);
                    },
                  ),

                  const SizedBox(height: 8),

                  // Divider
                  Divider(
                    height: 1,
                    thickness: 8,
                    color: theme.dividerColor.withOpacity(0.1),
                  ),

                  const SizedBox(height: 16),

                  // Titre
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Input(
                      controller: _titleController,
                      label: l10n.productTitle,
                      placeholder: l10n.productTitleHint,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Divider
                  Divider(
                    height: 1,
                    color: theme.dividerColor.withOpacity(0.1),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Input(
                      controller: _descriptionController,
                      label: l10n.productDescription,
                      placeholder: l10n.productDescriptionHint,
                      maxLines: 5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Divider
                  Divider(
                    height: 1,
                    thickness: 8,
                    color: theme.dividerColor.withOpacity(0.1),
                  ),

                  // Catégorie
                  SelectionTile(
                    label: l10n.category,
                    value: _selectedCategory,
                    placeholder: l10n.selectCategory,
                    onTap: () => _showCategoryPicker(context, theme, l10n),
                    isRequired: true,
                  ),

                  // Dynamic attributes (only if category selected and has attributes)
                  if (_selectedCategoryId != null &&
                      _categoryAttributes.isNotEmpty) ...[
                    ..._categoryAttributes.map(
                      (attr) => _buildAttributeField(attr, theme, l10n),
                    ),
                  ],

                  // Prix avec devise multilingue
                  SelectionTile(
                    label: l10n.price,
                    value: _priceController.text.isEmpty
                        ? null
                        : '${_priceController.text} ${l10n.currency}',
                    placeholder: l10n.priceHint,
                    onTap: () => _showPricePicker(context, theme, l10n),
                    isRequired: true,
                  ),

                  const SizedBox(height: 32),

                  // TODO: Attributs dynamiques selon catégorie
                  const SizedBox(height: 80), // Espace pour le bouton
                ],
              ),
            ),
          ),

          // Bouton Publier (fixe en bas)
          _buildPublishButton(context, theme, l10n),
        ],
      ),
    );
  }

  /// Construit l'AppBar
  Widget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: EdgeInsets.only(
        top: context.layoutHeight() * 0.05,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              l10n.sellTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Pour centrer le titre
        ],
      ),
    );
  }

  /// Construit le bouton Publier avec spinner quand en cours de publication.
  ///
  /// États du bouton :
  /// - Désactivé (gris) si le formulaire est incomplet
  /// - Actif (bleu) si le formulaire est valide
  /// - En cours (spinner) pendant l'upload et l'enregistrement
  Widget _buildPublishButton(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.1), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            // Le bouton est actif uniquement si le formulaire est valide
            // et qu'on n'est pas déjà en train de publier
            onPressed: _canPublish() ? () => _handlePublish(l10n) : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isPublishing
                ? // Si en cours de publication : afficher un spinner
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : // Sinon : afficher le texte "Publier"
                  Text(
                    l10n.publish,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// Charge les attributs de la catégorie sélectionnée
  Future<void> _loadCategoryAttributes(String categoryId) async {
    try {
      // 1. Récupérer la sous-catégorie pour avoir ses IDs d'attributs
      final subcategory = await ref
          .read(categoryRepositoryProvider)
          .getSubcategoryById(categoryId);

      if (subcategory.attributes.isEmpty) {
        setState(() {
          _categoryAttributes = [];
        });
        return;
      }

      // 2. Récupérer les définitions des attributs
      final attributes = await ref
          .read(categoryRepositoryProvider)
          .getAttributesByIds(subcategory.attributes);

      setState(() {
        _categoryAttributes = attributes.where((a) => a.isActive).toList();
        // Trier par ordre si défini
        _categoryAttributes.sort(
          (a, b) => (a.order ?? 0).compareTo(b.order ?? 0),
        );
      });
    } catch (e) {
      debugPrint('Error loading attributes: $e');
      setState(() {
        _categoryAttributes = [];
      });
    }
  }

  /// Construit un champ d'attribut selon son type
  Widget _buildAttributeField(
    ProductAttribute attr,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    // Traduire le nom de l'attribut
    final translatedName = CategoryTranslator.translate(
      l10n,
      attr.name,
      attr.name,
    );

    // Traduire le help text
    final translatedHelpText = CategoryTranslator.translateHelpText(
      l10n,
      attr.id,
      attr.helpText,
    );

    switch (attr.type) {
      case AttributeType.select:
        // Récupérer et traduire la valeur sélectionnée si elle existe
        final rawValue = _attributeValues[attr.id];
        String? selectedValue;

        if (rawValue is int) {
          if (rawValue >= 0 && rawValue < attr.values.length) {
            selectedValue = attr.values[rawValue];
          }
        } else if (rawValue is String) {
          selectedValue = rawValue;
        }

        final displayValue = selectedValue != null
            ? CategoryTranslator.translateAttributeValue(l10n, selectedValue)
            : null;

        return SelectionTile(
          label: translatedName,
          value: displayValue,
          placeholder: translatedHelpText.isEmpty
              ? l10n.selectAttributePlaceholder(translatedName)
              : translatedHelpText,
          onTap: () => _showAttributePicker(attr, theme, l10n, translatedName),
          isRequired: attr.isRequired,
        );

      case AttributeType.text:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Input(
            label: translatedName,
            placeholder: translatedHelpText.isEmpty
                ? l10n.enterAttributePlaceholder(translatedName)
                : translatedHelpText,
            onChanged: (value) {
              setState(() {
                _attributeValues[attr.id] = value;
              });
            },
          ),
        );

      default:
        // Pour l'instant on gère Select et Text
        return const SizedBox.shrink();
    }
  }

  /// Affiche le picker pour un attribut de type select
  void _showAttributePicker(
    ProductAttribute attr,
    ThemeData theme,
    AppLocalizations l10n,
    String translatedName,
  ) {
    // Transformer les valeurs en objets utilisables par le sélecteur, en utilisant l'index comme ID
    final items = attr.values.asMap().entries.map((entry) {
      final translatedValue = CategoryTranslator.translateAttributeValue(
        l10n,
        entry.value,
      );
      return {
        'id': entry.key.toString(), // Utiliser l'index comme ID
        'name': translatedValue, // Afficher la valeur traduite
      };
    }).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SelectionScreen(
          title: translatedName,
          content: DynamicSelectionView(
            config: {
              'type': 'list',
              'dataSource': 'static',
              'itemKey': 'id',
              'itemLabel': 'name',
            },
            dataSources: {'static': (_) async => items},
            onResult: (item) {
              if (item != null) {
                setState(() {
                  // Stocker l'index (sous forme d'entier) dans la BDD
                  final index = int.tryParse(item['id'] as String);
                  _attributeValues[attr.id] = index ?? item['id'];
                });
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      ),
    );
  }

  /// Affiche le sélecteur de catégorie
  void _showCategoryPicker(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final categoryConfig = {
      'type': 'list',
      'dataSource': 'categories',
      'itemKey': 'id',
      'itemLabel': 'name',
      'itemIcon': 'iconUrl',
      'nextAction': 'navigate_recursive',
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'category_selection_root'),
        builder: (context) => SelectionScreen(
          title: l10n.category,
          content: DynamicSelectionView(
            config: categoryConfig,
            dataSources: {
              'categories': (_) async {
                final cats = await ref.read(categoriesProvider.future);
                return cats
                    .map(
                      (c) => {
                        'id': c.id,
                        'name': CategoryTranslator.translate(
                          l10n,
                          c.id,
                          c.name,
                        ),
                        'iconUrl': c.iconUrl,
                        'hasChildren': c.children.isNotEmpty,
                      },
                    )
                    .toList();
              },
              'subcategories': (parentId) async {
                if (parentId == null) return [];
                final subs = await ref.read(
                  subcategoriesProvider(parentId).future,
                );
                return subs
                    .map(
                      (s) => {
                        'id': s.id,
                        'name': CategoryTranslator.translate(
                          l10n,
                          s.id,
                          s.name,
                        ),
                        'iconUrl': s.iconUrl,
                        'hasChildren': s.children.isNotEmpty,
                      },
                    )
                    .toList();
              },
            },
            onResult: (item) async {
              if (item != null) {
                final categoryId = item['id'] as String;
                final categoryName = item['name'] as String;

                // Récupérer le parentId depuis Firestore
                String? parentId;
                try {
                  // Remontée récursive pour trouver la catégorie racine (niveau 1)
                  // Les filtres de l'accueil ("femme", "homme") s'appuient sur le categoryId de niveau 1
                  String currentSubId = categoryId;
                  bool foundRoot = false;
                  String? rootId;

                  while (!foundRoot) {
                    try {
                      final sub = await ref
                          .read(categoryRepositoryProvider)
                          .getSubcategoryById(currentSubId);

                      if (sub.parentId == 'femme' || sub.parentId == 'homme') {
                        rootId = sub.parentId;
                        foundRoot = true;
                      } else {
                        // On remonte d'un niveau
                        currentSubId = sub.parentId;
                      }
                    } catch (e) {
                      // Si getSubcategoryById échoue, on est probablement sur une racine
                      rootId = currentSubId;
                      foundRoot = true;
                    }
                  }

                  parentId = rootId;
                  debugPrint(
                    '✅ Root ParentId extracted from Firestore: $parentId',
                  );
                } catch (e) {
                  parentId = categoryId;
                  debugPrint(
                    'ℹ️ Fallback: Using categoryId as parentId: $parentId',
                  );
                }

                setState(() {
                  _selectedCategory = categoryName;
                  _selectedCategoryId = categoryId;
                  _selectedParentCategoryId = parentId;

                  _attributeValues.clear(); // Reset attributes
                  _categoryAttributes = []; // Clear previous attributes list
                });

                // Charger les attributs dynamiquement
                _loadCategoryAttributes(categoryId);

                // Close all selection screens until we reach the root
                Navigator.of(context).popUntil(
                  (route) =>
                      route.settings.name == 'category_selection_root' ||
                      route.isFirst,
                );
                // Close the root selection screen
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      ),
    );
  }

  /// Affiche le sélecteur de prix avec configuration JSON dynamique
  void _showPricePicker(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    // Configuration JSON pour l'écran de prix
    final priceConfig = {
      'fields': [
        {
          'key': 'price',
          'type': 'input',
          'props': {
            'label': l10n.indicateYourPrice,
            'placeholder': l10n.priceFormatPlaceholder,
            'inputType': 'number',
            'suffixIcon': 'euro',
            'autofocus': true,
          },
        },
      ],
      'action': {'label': l10n.validatePrice, 'returnKey': 'price'},
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SelectionScreen(
          title: l10n.price,
          content: DynamicSelectionView(
            config: priceConfig,
            initialData: _priceController.text.isNotEmpty
                ? {'price': _priceController.text}
                : null,
            onResult: (result) {
              if (result != null) {
                setState(() {
                  _priceController.text = result.toString();
                });
              }
            },
          ),
        ),
      ),
    );
  }

  /// Vérifie si on peut publier le produit.
  ///
  /// Validation :
  /// - Au moins 1 image
  /// - Titre rempli
  /// - Description remplie
  /// - Catégorie sélectionnée
  /// - Prix rempli
  /// - Tous les attributs obligatoires remplis
  bool _canPublish() {
    // Si en cours de publication, on ne peut pas republier
    if (_isPublishing) return false;

    // Vérifier les champs de base
    final basicFieldsComplete =
        _selectedImages.isNotEmpty &&
        _titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _selectedCategory != null &&
        _priceController.text.isNotEmpty;

    if (!basicFieldsComplete) return false;

    // Vérifier que tous les attributs obligatoires sont remplis
    for (final attr in _categoryAttributes) {
      if (attr.isRequired) {
        final value = _attributeValues[attr.id];
        if (value == null || (value is String && value.isEmpty)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Gère la publication du produit.
  ///
  /// Processus complet :
  /// 1. Récupérer l'utilisateur connecté
  /// 2. Uploader les images vers Firebase Storage
  /// 3. Créer l'objet Product avec toutes les données
  /// 4. Enregistrer dans Firestore via ProductRepository
  /// 5. Afficher un message de succès
  /// 6. Fermer le bottom sheet
  ///
  /// En cas d'erreur, affiche un message d'erreur localisé.
  Future<void> _handlePublish(AppLocalizations l10n) async {
    // On ne devrait pas arriver ici si _canPublish() retourne false
    // mais on vérifie quand même
    if (!_canPublish()) return;

    // Activer l'état "en cours de publication"
    // Cela va désactiver le bouton et afficher le spinner
    setState(() {
      _isPublishing = true;
    });

    try {
      // ============================================================
      // ÉTAPE 1 : RÉCUPÉRER L'UTILISATEUR CONNECTÉ
      // ============================================================

      // Récupérer l'utilisateur actuel depuis le provider
      final currentUserAsync = ref.read(currentUserProvider);

      // Vérifier que l'utilisateur est bien connecté
      if (!currentUserAsync.hasValue || currentUserAsync.value == null) {
        throw Exception('Utilisateur non connecté');
      }

      final currentUser = currentUserAsync.value!;

      final userId = currentUser.uid;

      // ============================================================
      // ÉTAPE 2 : UPLOADER LES IMAGES VERS FIREBASE STORAGE
      // ============================================================

      // Générer un ID temporaire unique pour le produit
      // (sera remplacé par l'ID Firestore après création)
      final tempProductId = DateTime.now().millisecondsSinceEpoch.toString();

      debugPrint('📸 Début upload images:');
      debugPrint('   - UserId: $userId');
      debugPrint('   - TempProductId: $tempProductId');
      debugPrint('   - Nombre d\'images: ${_selectedImages.length}');

      // Récupérer le service d'upload d'images
      final imageUploadService = ref.read(imageUploadServiceProvider);

      // Uploader uniquement les nouvelles images (XFile)
      // et conserver les URLs des images existantes (String)
      List<String> imageUrls = [];
      List<XFile> newImagesToUpload = [];

      for (var img in _selectedImages) {
        if (img is String) {
          imageUrls.add(img);
        } else if (img is XFile) {
          newImagesToUpload.add(img);
        }
      }

      if (newImagesToUpload.isNotEmpty) {
        try {
          final uploadedUrls = await imageUploadService.uploadProductImages(
            newImagesToUpload,
            userId,
            widget.initialProduct?.id ?? tempProductId,
          );
          imageUrls.addAll(uploadedUrls);
          debugPrint('✅ Upload terminé: ${uploadedUrls.length} nouvelles images');
        } catch (uploadError) {
          debugPrint('❌ Erreur upload: $uploadError');
          throw Exception(
            'Échec de l\'upload des images: ${uploadError.toString()}',
          );
        }
      }

      // ============================================================
      // ÉTAPE 3 : CRÉER L'OBJET PRODUCT
      // ============================================================

      // Parser le prix (convertir String → double)
      final price = double.tryParse(_priceController.text) ?? 0.0;

      // Récupérer l'état depuis les attributs dynamiques
      final conditionValue = _attributeValues['condition'];
      ProductCondition condition = ProductCondition.good;

      if (conditionValue is int) {
        if (conditionValue >= 0 &&
            conditionValue < ProductCondition.values.length) {
          condition = ProductCondition.values[conditionValue];
        }
      }

      // Créer l'objet Product avec toutes les informations
      final product = (widget.initialProduct ??
              Product(
                id: '',
                title: '',
                description: '',
                price: 0,
                imageUrls: [],
                condition: condition,
                sellerId: userId,
                categoryId: _selectedParentCategoryId!,
                subcategoryId: _selectedCategoryId!,
                attributes: {},
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ))
          .copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        imageUrls: imageUrls,
        condition: condition,
        categoryId: _selectedParentCategoryId!,
        subcategoryId: _selectedCategoryId!,
        attributes: _attributeValues,
        updatedAt: DateTime.now(),
      );

      // ============================================================
      // ÉTAPE 4 : ENREGISTRER DANS FIRESTORE
      // ============================================================
      final productRepository = ref.read(productRepositoryProvider);

      // Enregistrer dans Firestore
      if (widget.initialProduct != null) {
        await productRepository.updateProduct(product);
      } else {
        await productRepository.createProduct(product);
      }

      // ============================================================
      // ÉTAPE 5 : RAFRAÎCHIR LA LISTE DES PRODUITS
      // ============================================================

      // Invalider le provider pour recharger les produits sur Home
      ref.invalidate(paginatedProductsProvider);
      // Invalider la liste globale
      ref.invalidate(allProductsProvider);
      // Invalider la liste des annonces du vendeur
      ref.invalidate(sellerProductsProvider(userId));
      // ÉTAPE 6 : SUCCÈS - AFFICHER UN MESSAGE ET FERMER
      // ============================================================

      // Fermer le bottom sheet
      if (mounted) {
        Navigator.of(context).pop();

        // Afficher un message de succès multilingue
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productPublishedSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Naviguer vers la page d'accueil
        context.go('/home');
      }
    } catch (e, stackTrace) {
      // ============================================================
      // GESTION DES ERREURS
      // ============================================================

      // Logger l'erreur pour le debugging
      debugPrint('Erreur lors de la publication du produit: $e');
      debugPrint('Stack trace: $stackTrace');

      // Afficher un message d'erreur à l'utilisateur
      if (mounted) {
        // Utiliser le message de l'exception ou un message générique
        String errorMessage;
        if (e is AppException) {
          // Les AppExceptions ont des messages descriptifs
          errorMessage = e.message;
        } else {
          // Pour les autres erreurs, message générique multilingue
          errorMessage = l10n.productPublishError;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            // Action pour fermer le message d'erreur (bouton multilingue)
            action: SnackBarAction(
              label: l10n.ok,
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      // ============================================================
      // NETTOYAGE - DÉSACTIVER L'ÉTAT "EN COURS"
      // ============================================================

      // Réactiver le bouton (retirer le spinner)
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }
}
