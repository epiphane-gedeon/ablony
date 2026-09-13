import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../../shared/widgets/choice_card_widget.dart';
import '../../../../shared/widgets/selection_tile.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../product/domain/entities/product.dart';
import '../../../delivery/domain/models/delivery_choice.dart';
import '../../../delivery/domain/models/delivery_pricing.dart';
import '../../../relay_point/domain/models/relay_point.dart';
import '../../../../core/services/payment_service.dart';
import 'payment_web_view_page.dart';
import '../../../../core/responsive/responsive.dart';

/// Page de paiement pour finaliser un achat ou effectuer une recharge de portefeuille
class PaymentPage extends ConsumerStatefulWidget {
  final Product? product;
  final double?
  amount; // Utilisé pour la recharge de portefeuille si le produit est nul

  const PaymentPage({super.key, this.product, this.amount});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  // Options de livraison
  DeliveryMethod _deliveryMethod = DeliveryMethod.relay;

  // Sélections. Les objets entiers, et non leur libellé : la version
  // précédente ne gardait que le *nom* du point relais et une adresse déjà
  // mise en forme, si bien qu'il n'y avait rien à envoyer au serveur même si
  // on l'avait voulu.
  DeliveryAddress? _selectedAddress;
  RelayPoint? _selectedRelayPoint;
  String? _selectedPaymentMethod;
  String? _paymentPhoneNumber;

  bool _isProcessing = false;
  bool _isMixedPayment = false;
  double _walletContribution = 0.0;
  double _externalAmount = 0.0;

  // Calcul des frais. Affichés ici, imposés par le serveur : il recalcule le
  // total et refuse un écart. Un client qui fixe ses propres frais n'en paie
  // aucun.
  double get _protectionFees => widget.product != null
      ? widget.product!.price * DeliveryPricing.protectionRate
      : 0.0;
  double get _shippingCost => widget.product != null
      ? DeliveryPricing.shippingFeeFor(_deliveryMethod).toDouble()
      : 0.0;
  double get _totalAmount => widget.product != null
      ? widget.product!.price + _protectionFees + _shippingCost
      : (widget.amount ?? 0.0);

  /// Le choix de livraison, tel qu'il accompagnera le paiement.
  DeliveryChoice get _deliveryChoice => DeliveryChoice(
    method: _deliveryMethod,
    relayPoint: _selectedRelayPoint,
    address: _selectedAddress,
  );

  // Helper pour formater le nom de la méthode de paiement
  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'wallet':
        return 'Porte-monnaie';
      case 'tmoney':
        return 'T-Money';
      case 'flooz':
        return 'Flooz';
      case 'card':
        return 'Carte bancaire';
      default:
        return method;
    }
  }

  /// Gère l'exécution du paiement
  Future<void> _handlePaymentExecution() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      _showErrorSnackBar('Veuillez vous connecter pour procéder au paiement');
      return;
    }

    if (widget.product != null && widget.product!.isSold) {
      _showErrorSnackBar('Cet article a déjà été vendu');
      return;
    }

    // L'adresse n'est exigée que pour une remise à domicile. La version
    // précédente la réclamait aussi pour un retrait en point relais, où elle
    // ne sert à rien : on bloquait un achat sur une information inutile.
    if (widget.product != null && !_deliveryChoice.isComplete) {
      _showErrorSnackBar(
        _deliveryMethod == DeliveryMethod.relay
            ? 'Veuillez sélectionner un point relais'
            : 'Veuillez renseigner une adresse de livraison',
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final paymentService = ref.read(paymentServiceProvider);

      // Formater le numéro de téléphone pour GeniusPay (format international +228...)
      String? phone = _paymentPhoneNumber;
      if (phone != null && !phone.startsWith('+')) {
        phone = '+228${phone.replaceAll(' ', '')}'; // +228 = indicatif Togo
      }

      final responseData = await paymentService.initiatePayment(
        userId: user.uid,
        amount: _isMixedPayment ? _externalAmount : _totalAmount,
        paymentMethod: _selectedPaymentMethod!,
        phone: phone,
        name: user.displayName,
        email: user.email,
        description: widget.product != null
            ? 'Achat : ${widget.product!.title}'
            : 'Recharge portefeuille Ablony',
        type: widget.product != null ? 'purchase' : 'recharge',
        productId: widget.product?.id,
        sellerId: widget.product?.sellerId,
        productPrice: widget.product != null
            ? widget.product!.price.toDouble()
            : null,
        walletDeduction: _isMixedPayment ? _walletContribution : null,
        delivery: widget.product != null ? _deliveryChoice : null,
      );

      debugPrint('[Payment] responseData reçu: $responseData');

      // Si le paiement est déjà complété (ex: via le porte-monnaie à 100%)
      if (responseData['status'] == 'completed' ||
          responseData['completed'] == true) {
        setState(() => _isProcessing = false);
        _showSuccessDialog(
          transactionRef: responseData['reference'] as String?,
        );
        return;
      }

      final paymentUrl = responseData['paymentUrl'] as String?;
      final reference = responseData['reference'] as String?;

      debugPrint('[Payment] paymentUrl extrait: $paymentUrl');
      debugPrint('[Payment] reference extrait: $reference');

      if (!mounted) return;

      if (paymentUrl != null) {
        // Ouverture de la page de paiement (Hosted Checkout) dans la WebView in-app
        final paymentCompleted = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => PaymentWebViewPage(url: paymentUrl),
          ),
        );

        if (!mounted) return;

        if (paymentCompleted == true && reference != null) {
          // Confirmer le paiement côté serveur : débiter le wallet,
          // créditer le vendeur en pendingAmount, marquer le produit vendu
          try {
            debugPrint(
              '[Payment] Confirmation serveur pour la référence: $reference',
            );
            await paymentService.confirmPayment(reference: reference);
            if (!mounted) return;
            _showSuccessDialog(transactionRef: reference);
          } catch (confirmError) {
            debugPrint('[Payment] Erreur confirmation: $confirmError');
            if (!mounted) return;
            // Le paiement externe a réussi mais la finalisation a échoué
            _showErrorSnackBar(
              'Le paiement a été reçu mais la finalisation a échoué. '
              'Veuillez contacter le support avec la référence : $reference',
            );
          }
        } else {
          _showErrorSnackBar('Le paiement a échoué ou a été annulé');
        }
      } else {
        _showErrorSnackBar('Impossible d\'initier le paiement (URL manquante)');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString().replaceAll('Exception:', '').trim());
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog({String? transactionRef}) {
    // Invalider le provider pour forcer le rafraîchissement immédiat du solde utilisateur dans l'application
    ref.invalidate(currentUserProvider);

    final isPurchase = widget.product != null;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(isPurchase ? 'Achat réussi' : 'Paiement réussi'),
          ],
        ),
        content: Text(
          isPurchase
              ? 'Votre achat a été finalisé avec succès. L\'article est maintenant marqué comme vendu.'
              : 'Votre compte a été rechargé avec succès. Le solde de votre portefeuille a été mis à jour.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer le dialogue
              if (isPurchase) {
                // La notation du vendeur est proposée depuis le reçu,
                // après la confirmation de réception — pas ici : à ce stade
                // le colis n'est même pas encore déposé.
                if (transactionRef != null) {
                  context.go('/receipt/$transactionRef');
                } else {
                  context.go('/messages');
                }
              } else {
                context.go('/profile/wallet'); // Rediriger vers le wallet
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showUSSDPushSentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone_android, color: Colors.blue),
            SizedBox(width: 8),
            Text('Validation sur mobile'),
          ],
        ),
        content: const Text(
          'Une demande de validation a été envoyée sur votre mobile.\n\n'
          'Veuillez saisir votre code PIN secret sur votre téléphone pour valider l\'opération.\n\n'
          'Une fois confirmée, votre solde de portefeuille sera mis à jour.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/profile/wallet');
            },
            child: const Text('Retourner au portefeuille'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = context.layoutWidth();
    final imageSize = screenWidth * 0.35;

    final isRecharge = widget.product == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRecharge ? 'Recharger le portefeuille' : 'Paiement'),
        centerTitle: true,
      ),
      body: ContentContainer(
        applyPadding: false,
        maxWidth: ContentWidth.form,
        child: Stack(
          children: [
            // Contenu avec scroll
            ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                if (isRecharge)
                  // Informations de recharge
                  Container(
                    margin: EdgeInsets.all(screenWidth * 0.04),
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.15,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recharge du porte-monnaie',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Créditez votre portefeuille Ablony de façon sécurisée.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${widget.amount?.toStringAsFixed(0)} FCFA',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Informations du produit
                  Container(
                    margin: EdgeInsets.all(screenWidth * 0.04),
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: widget.product!.imageUrls.isNotEmpty
                              ? Image.network(
                                  widget.product!.imageUrls.first,
                                  width: imageSize,
                                  height: imageSize,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: imageSize,
                                      height: imageSize,
                                      color: Colors.grey[300],
                                      child: Icon(
                                        Icons.image,
                                        size: imageSize * 0.4,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  width: imageSize,
                                  height: imageSize,
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.image,
                                    size: imageSize * 0.4,
                                  ),
                                ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product!.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.product!.condition.label,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${widget.product!.price.toStringAsFixed(0)} FCFA',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Section Options de livraison
                  _buildSection(
                    context,
                    title: 'Options de livraison',
                    child: Column(
                      children: [
                        ChoiceCardWidget(
                          title: 'Retrait en point relais',
                          subTitle:
                              '${DeliveryPricing.relayFeeXof} FCFA — à récupérer avec une pièce d\'identité',
                          icon: Icons.location_on_outlined,
                          isSelected: _deliveryMethod == DeliveryMethod.relay,
                          showSelectionCircle: true,
                          onTap: () {
                            setState(() {
                              _deliveryMethod = DeliveryMethod.relay;
                            });
                          },
                        ),
                        SizedBox(height: screenWidth * 0.03),
                        ChoiceCardWidget(
                          title: 'Livraison à domicile',
                          subTitle:
                              '${DeliveryPricing.homeFeeXof} FCFA — remise à votre adresse',
                          icon: Icons.home_outlined,
                          isSelected: _deliveryMethod == DeliveryMethod.home,
                          showSelectionCircle: true,
                          onTap: () {
                            setState(() {
                              _deliveryMethod = DeliveryMethod.home;
                              _selectedRelayPoint = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.06),

                  // La destination dépend du mode : un point relais, ou une
                  // adresse. Demander les deux — ce que faisait l'écran —
                  // bloquait un retrait en point relais sur une adresse qui
                  // ne sert à personne.
                  if (_deliveryMethod == DeliveryMethod.relay)
                    SelectionTile(
                      label: 'Point relais',
                      value: _selectedRelayPoint?.name,
                      placeholder: 'Choisir un point relais',
                      isRequired: true,
                      onTap: () async {
                        final result = await context.push(
                          '/relay-point/select',
                        );
                        if (result != null && result is RelayPoint) {
                          // L'objet entier, et non son nom : c'est
                          // l'identifiant que le serveur attend.
                          setState(() => _selectedRelayPoint = result);
                        }
                      },
                    )
                  else
                    SelectionTile(
                      label: 'Adresse de livraison',
                      value: _selectedAddress?.summary,
                      placeholder: 'Ajouter l\'adresse de livraison',
                      isRequired: true,
                      onTap: () async {
                        final result = await context.push('/address/add');
                        if (result is DeliveryAddress) {
                          setState(() => _selectedAddress = result);
                        }
                      },
                    ),
                  SizedBox(height: screenWidth * 0.06),
                ],

                // Section Mode de Paiement (Toujours affichée)
                SelectionTile(
                  label: 'Mode de paiement',
                  value: _selectedPaymentMethod != null
                      ? _getPaymentMethodLabel(_selectedPaymentMethod!) +
                            (_paymentPhoneNumber != null
                                ? ' ($_paymentPhoneNumber)'
                                : '') +
                            (_isMixedPayment ? ' (+ Portefeuille)' : '')
                      : null,
                  placeholder: 'Sélectionne un mode de paiement',
                  isRequired: true,
                  onTap: () async {
                    final user = ref.read(currentUserProvider).value;
                    final wallet = user?.wallet;
                    final isRecharge = widget.product == null;

                    final result = await context.push(
                      '/payment-method/select',
                      extra: {'isRecharge': isRecharge},
                    );
                    if (result != null && result is Map<String, dynamic>) {
                      final selectedMethod = result['method'] as String?;
                      final phone = result['phoneNumber'] as String?;

                      if (selectedMethod == 'wallet' && wallet != null) {
                        final walletAvailable = wallet.availableAmountInXOF;
                        if (walletAvailable < _totalAmount) {
                          if (!mounted) return;
                          // Solde insuffisant pour payer la totalité
                          final diff = _totalAmount - walletAvailable;
                          final proceedWithMixed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Solde insuffisant'),
                              content: Text(
                                'Le solde de votre porte-monnaie (${walletAvailable.toStringAsFixed(0)} FCFA) '
                                'est insuffisant pour régler le total de ${_totalAmount.toStringAsFixed(0)} FCFA.\n\n'
                                'Voulez-vous payer la différence de ${diff.toStringAsFixed(0)} FCFA par un autre moyen de paiement ?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Payer la différence'),
                                ),
                              ],
                            ),
                          );

                          if (proceedWithMixed == true) {
                            if (!mounted) return;
                            // Sélectionner un autre moyen de paiement pour la différence
                            final mixedResult = await context.push(
                              '/payment-method/select',
                              extra: {
                                'isRecharge': true,
                              }, // true exclut l'option wallet
                            );
                            if (mixedResult != null &&
                                mixedResult is Map<String, dynamic>) {
                              setState(() {
                                _isMixedPayment = true;
                                _walletContribution = walletAvailable;
                                _externalAmount = diff;
                                _selectedPaymentMethod =
                                    mixedResult['method'] as String?;
                                _paymentPhoneNumber =
                                    mixedResult['phoneNumber'] as String?;
                              });
                            }
                          }
                        } else {
                          // Solde suffisant pour un paiement 100% wallet
                          setState(() {
                            _isMixedPayment = false;
                            _walletContribution = _totalAmount;
                            _externalAmount = 0.0;
                            _selectedPaymentMethod = 'wallet';
                            _paymentPhoneNumber = null;
                          });
                        }
                      } else {
                        // Paiement standard sans portefeuille
                        setState(() {
                          _isMixedPayment = false;
                          _walletContribution = 0.0;
                          _externalAmount = _totalAmount;
                          _selectedPaymentMethod = selectedMethod;
                          _paymentPhoneNumber = phone;
                        });
                      }
                    }
                  },
                ),
                SizedBox(height: screenWidth * 0.06),

                // Section Détails du Prix (Toujours affichée)
                _buildSection(
                  context,
                  title: 'Détail de la facture',
                  child: Column(
                    children: !isRecharge
                        ? [
                            _buildPriceRow(
                              'Commande',
                              '${widget.product!.price.toStringAsFixed(0)} FCFA',
                            ),
                            SizedBox(height: screenWidth * 0.03),
                            _buildPriceRow(
                              'Frais de Protection acheteurs',
                              '${_protectionFees.toStringAsFixed(0)} FCFA',
                              hasInfo: true,
                            ),
                            SizedBox(height: screenWidth * 0.03),
                            _buildPriceRow(
                              'Frais de port',
                              '${_shippingCost.toStringAsFixed(0)} FCFA',
                            ),
                            if (_isMixedPayment) ...[
                              SizedBox(height: screenWidth * 0.03),
                              _buildPriceRow(
                                'Déduit du porte-monnaie',
                                '-${_walletContribution.toStringAsFixed(0)} FCFA',
                              ),
                              SizedBox(height: screenWidth * 0.03),
                              _buildPriceRow(
                                'Reste à payer',
                                '${_externalAmount.toStringAsFixed(0)} FCFA',
                              ),
                            ],
                          ]
                        : [
                            _buildPriceRow(
                              'Montant de la recharge',
                              '${_totalAmount.toStringAsFixed(0)} FCFA',
                            ),
                          ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),

            // Bouton Payer fixé en bas
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isMixedPayment ? 'Reste à payer' : 'Total à payer',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _isMixedPayment
                              ? '${_externalAmount.toStringAsFixed(0)} FCFA'
                              : '${_totalAmount.toStringAsFixed(0)} FCFA',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenWidth * 0.03),

                    // Bouton Payer
                    PrimaryButton(
                      text: _selectedPaymentMethod == 'card'
                          ? 'Procéder au paiement par carte'
                          : (_selectedPaymentMethod == 'wallet' &&
                                !_isMixedPayment)
                          ? 'Payer avec le porte-monnaie'
                          : 'Valider le paiement',
                      isLoading: _isProcessing,
                      onPressed: _selectedPaymentMethod == null || _isProcessing
                          ? null
                          : _handlePaymentExecution,
                    ),
                    SizedBox(height: screenWidth * 0.02),

                    // Message de sécurité
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outlined,
                          size: screenWidth * 0.04,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Flexible(
                          child: Text(
                            'Vos informations sont cryptées et sécurisées par GeniusPay',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                              fontSize: screenWidth * 0.028,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final screenWidth = context.layoutWidth();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: screenWidth * 0.03),
          child,
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String price, {bool hasInfo = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 15)),
            if (hasInfo) ...[
              const SizedBox(width: 4),
              const Icon(Icons.info_outline, size: 16, color: Colors.grey),
            ],
          ],
        ),
        Text(
          price,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
