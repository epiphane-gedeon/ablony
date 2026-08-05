import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ablony/shared/widgets/buttons/buttons.dart';
import 'package:ablony/shared/widgets/input.dart';
import 'package:ablony/shared/widgets/choice_card_widget.dart';
import 'package:ablony/l10n/app_localizations.dart';
import 'package:ablony/features/product/domain/entities/product.dart';
import 'package:ablony/features/auth/application/auth_providers.dart';
import 'package:ablony/features/messages/application/services/messaging_service.dart';
import 'package:ablony/features/messages/domain/models/participant_details.dart';
import 'package:ablony/features/messages/domain/models/product_details.dart'
    as msg;
import 'package:ablony/features/messages/domain/models/user_info.dart';
import 'package:ablony/features/product/presentation/providers/product_provider.dart';
import '../../../../core/responsive/responsive.dart';

/// Bottom sheet plein écran pour faire une offre.
/// Envoie l'offre au vendeur via le système de messagerie.
class MakeOfferBottomSheet extends ConsumerStatefulWidget {
  final Product product;

  const MakeOfferBottomSheet({super.key, required this.product});

  /// Affiche le bottom sheet en plein écran
  static Future<void> show(BuildContext context, Product product) {
    if (product.isSold) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cet article a déjà été vendu'),
          backgroundColor: Colors.red,
        ),
      );
      return Future.value();
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MakeOfferBottomSheet(product: product),
    );
  }

  @override
  ConsumerState<MakeOfferBottomSheet> createState() =>
      _MakeOfferBottomSheetState();
}

class _MakeOfferBottomSheetState extends ConsumerState<MakeOfferBottomSheet> {
  late TextEditingController _priceController;
  late double _currentAmount;
  final FocusNode _priceFocusNode = FocusNode();

  // -1: aucune, 0: -15%, 1: -30%, 2: Autre
  int _selectedSuggestionIndex = -1;
  String? _errorLabel;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currentAmount = widget.product.price;
    _priceController = TextEditingController(
      text: _formatAmount(_currentAmount),
    );

    // Écouter le focus pour sélectionner "Autre" automatiquement
    _priceFocusNode.addListener(() {
      if (_priceFocusNode.hasFocus) {
        setState(() {
          _selectedSuggestionIndex = 2; // Sélectionne "Autre"
        });
      }
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(
      0,
    ); // FCFA généralement sans décimales ou .00 inutile
  }

  void _selectSuggestion(int index) {
    setState(() {
      _selectedSuggestionIndex = index;
      if (index == 0) {
        _currentAmount = widget.product.price * 0.85;
      } else if (index == 1) {
        _currentAmount = widget.product.price * 0.70;
      }

      // Si on sélectionne une suggestion prédéfinie, on met à jour le champ et on enlève le focus
      if (index != 2) {
        _priceController.text = _formatAmount(_currentAmount);
        _priceFocusNode.unfocus();
      } else {
        // Si on clique sur "Autre", on donne le focus au champ pour inciter à la saisie
        _priceFocusNode.requestFocus();
      }

      _validateAmount(_currentAmount);
    });
  }

  void _updateAmount(double amount) {
    setState(() {
      _currentAmount = amount;
      // Force la sélection "Autre" si on tape
      if (_selectedSuggestionIndex != 2) {
        _selectedSuggestionIndex = 2;
      }
      _validateAmount(amount);
    });
  }

  void _validateAmount(double amount) {
    final minAllowed = widget.product.price * 0.60;

    if (amount < minAllowed) {
      _errorLabel = "limit_reached";
    } else {
      _errorLabel = null;
    }
  }

  Future<void> _submitOffer() async {
    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(authStateProvider).value;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Vérifier si l'article est déjà vendu en direct depuis Firestore
      final liveProduct = await ref.read(productRepositoryProvider).getProductById(widget.product.id);
      if (liveProduct.isSold) {
        throw Exception('Cet article a déjà été vendu');
      }

      // Récupérer les données complètes de l'utilisateur actuel (buyer)
      final authRepository = ref.read(authRepositoryProvider);
      final buyer = await authRepository.getUserById(currentUser.uid);
      final seller = await authRepository.getUserById(widget.product.sellerId);

      // Préparer les détails des participants
      final buyerDetails = ParticipantDetails(
        name: buyer.username,
        avatar: buyer.photoUrl,
      );

      final sellerDetails = ParticipantDetails(
        name: seller.username,
        avatar: seller.photoUrl,
      );

      // Préparer les infos utilisateur pour les messages système
      final buyerInfo = UserInfo(
        name: buyer.username,
        avatar: buyer.photoUrl,
        country: buyer.country.name,
        memberSince: buyer.createdAt,
      );

      final sellerInfo = UserInfo(
        name: seller.username,
        avatar: seller.photoUrl,
        country: seller.country.name,
        memberSince: seller.createdAt,
      );

      // Préparer les détails du produit
      final productDetails = msg.ProductDetails(
        title: widget.product.title,
        price: widget.product.price,
        image: widget.product.imageUrls.isNotEmpty
            ? widget.product.imageUrls.first
            : null,
        sellerId: seller.uid,
      );

      // Envoyer l'offre via le service de messagerie
      final messagingService = ref.read(messagingServiceProvider);
      final conversationId = await messagingService.sendInitialOffer(
        buyerId: buyer.uid,
        sellerId: seller.uid,
        buyerDetails: buyerDetails,
        sellerDetails: sellerDetails,
        buyerInfo: buyerInfo,
        sellerInfo: sellerInfo,
        productId: widget.product.id,
        productDetails: productDetails,
        offerAmount: _currentAmount,
      );

      if (mounted) {
        Navigator.pop(context);

        // Naviguer vers la conversation
        context.push('/chat/$conversationId');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offre envoyée avec succès !')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    // Calcul des frais : 5% + 500 FCFA de frais fixes
    final protectionFees = (_currentAmount * 0.05) + 500;
    final totalAmount = _currentAmount + protectionFees;

    // Résolution du message d'erreur
    String? displayError;
    if (_errorLabel == "limit_reached") {
      final minAllowed = widget.product.price * 0.60;
      displayError = l10n.offerLimitError(
        _formatAmount(minAllowed) + ' FCFA',
        40,
      );
    } else if (_errorLabel == "too_high") {
      displayError = "Ton offre ne peut pas être supérieure au prix original";
    }

    return Container(
      height: screenHeight,
      color: theme
          .scaffoldBackgroundColor, // Background direct, pas de round corner en haut pour full screen immersif type "Sell"
      child: Column(
        children: [
          // AppBar Custom (Match SellBottomSheet style)
          Container(
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
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    l10n.makeOfferTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(
                  width: 48,
                ), // Équilibre visuel pour le titre centré
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: bottomPadding + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Info Produit
                  Row(
                    children: [
                      if (widget.product.imageUrls.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            widget.product.imageUrls.first,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.title,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.itemPrice(
                                _formatAmount(widget.product.price) + ' FCFA',
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Suggestions (Switch to ChoiceCardWidget)
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceCardWidget(
                          title:
                              '${_formatAmount(widget.product.price * 0.85)} FCFA',
                          subTitle: l10n.reductionLabel(15),
                          isSelected: _selectedSuggestionIndex == 0,
                          onTap: () => _selectSuggestion(0),
                          height: 80, // Hauteur uniforme
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceCardWidget(
                          title:
                              '${_formatAmount(widget.product.price * 0.70)} FCFA',
                          subTitle: l10n.reductionLabel(30),
                          isSelected: _selectedSuggestionIndex == 1,
                          onTap: () => _selectSuggestion(1),
                          height: 80,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceCardWidget(
                          title: l10n.otherOffer,
                          subTitle: l10n.otherOfferHint,
                          isSelected: _selectedSuggestionIndex == 2,
                          onTap: () => _selectSuggestion(2),
                          height: 80,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Input Prix
                  Input(
                    type: InputType.number,
                    controller: _priceController,
                    focusNode: _priceFocusNode,
                    placeholder: "0",
                    suffixIcon: const Padding(
                      padding: EdgeInsets.all(14.0),
                      child: Text(
                        'FCFA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly, // FCFA souvent entiers
                    ],
                    onChanged: (value) {
                      final amount = double.tryParse(value) ?? 0;
                      _updateAmount(amount);
                    },
                    errorLabel: displayError,
                  ),

                  if (displayError == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatAmount(totalAmount)} FCFA (incl. Protection acheteurs)',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 48),

                  // Bouton Valider
                  PrimaryButton(
                    text: _currentAmount > 0
                        ? l10n.proposeButton(
                            _formatAmount(_currentAmount) + ' FCFA',
                          )
                        : l10n.proposeButtonSimple,
                    isLoading: _isSubmitting,
                    onPressed:
                        (displayError != null ||
                            _currentAmount <= 0 ||
                            _isSubmitting)
                        ? null
                        : _submitOffer,
                  ),

                  const SizedBox(height: 24),

                  // Offres restantes
                  Center(
                    child: Text(
                      l10n.suggestionsRemaining(25),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
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
}
