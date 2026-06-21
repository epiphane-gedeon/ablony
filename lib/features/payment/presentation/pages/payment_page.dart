import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../../shared/widgets/choice_card_widget.dart';
import '../../../../shared/widgets/selection_tile.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../product/domain/entities/product.dart';
import '../../../../core/services/payment_service.dart';
import 'payment_web_view_page.dart';

/// Page de paiement pour finaliser un achat ou effectuer une recharge de portefeuille
class PaymentPage extends ConsumerStatefulWidget {
  final Product? product;
  final double? amount; // Utilisé pour la recharge de portefeuille si le produit est nul

  const PaymentPage({super.key, this.product, this.amount});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  // Options de livraison
  String _selectedDeliveryOption = 'relay'; // 'relay' ou 'home'

  // Sélections
  String? _selectedAddress;
  String? _selectedRelayPoint;
  String? _selectedPaymentMethod;
  String? _paymentPhoneNumber;

  bool _isProcessing = false;

  // Calcul des frais
  double get _protectionFees =>
      widget.product != null ? widget.product!.price * 0.05 : 0.0; // 5% de protection
  double get _shippingCost => widget.product != null
      ? (_selectedDeliveryOption == 'relay' ? 1000.0 : 1500.0) // FCFA
      : 0.0;
  double get _totalAmount => widget.product != null
      ? widget.product!.price + _protectionFees + _shippingCost
      : (widget.amount ?? 0.0);

  // Helper pour formater le nom de la méthode de paiement
  String _getPaymentMethodLabel(String method) {
    switch (method) {
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
        amount: _totalAmount,
        paymentMethod: _selectedPaymentMethod!,
        phone: phone,
        name: user.displayName,
        email: user.email,
        description: widget.product != null 
            ? 'Achat : ${widget.product!.title}'
            : 'Recharge portefeuille Ablony',
      );

      debugPrint('[Payment] responseData reçu: $responseData');

      final paymentUrl = responseData['paymentUrl'] as String?;

      debugPrint('[Payment] paymentUrl extrait: $paymentUrl');

      if (!mounted) return;

      if (paymentUrl != null) {
        // Ouverture de la page de paiement (Hosted Checkout) dans la WebView in-app
        final paymentCompleted = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => PaymentWebViewPage(url: paymentUrl),
          ),
        );

        if (!mounted) return;

        if (paymentCompleted == true) {
          _showSuccessDialog();
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Paiement réussi'),
          ],
        ),
        content: const Text(
          'Votre compte a été rechargé avec succès. '
          'Le solde de votre portefeuille a été mis à jour.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer le dialogue
              context.go('/profile/wallet'); // Rediriger vers le wallet
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.35;

    final isRecharge = widget.product == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRecharge ? 'Recharger le portefeuille' : 'Paiement'),
        centerTitle: true,
      ),
      body: Stack(
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
                    color: theme.colorScheme.primaryContainer.withOpacity(0.15),
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
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                                child: Icon(Icons.image, size: imageSize * 0.4),
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

                // Section Adresse de livraison
                SelectionTile(
                  label: 'Adresse',
                  value: _selectedAddress,
                  placeholder: 'Ajouter l\'adresse de livraison',
                  isRequired: true,
                  onTap: () async {
                    final result = await context.push('/address/add');
                    if (result != null) {
                      setState(() {
                        _selectedAddress = result.toString();
                      });
                    }
                  },
                ),
                SizedBox(height: screenWidth * 0.06),

                // Section Options de livraison
                _buildSection(
                  context,
                  title: 'Options de livraison',
                  child: Column(
                    children: [
                      ChoiceCardWidget(
                        title: 'Envoi en point relais',
                        subTitle: 'à partir de 1 000 FCFA',
                        icon: Icons.location_on_outlined,
                        isSelected: _selectedDeliveryOption == 'relay',
                        showSelectionCircle: true,
                        onTap: () {
                          setState(() {
                            _selectedDeliveryOption = 'relay';
                          });
                        },
                      ),
                      SizedBox(height: screenWidth * 0.03),
                      ChoiceCardWidget(
                        title: 'Envoi à domicile',
                        subTitle: '1 500 FCFA',
                        icon: Icons.home_outlined,
                        isSelected: _selectedDeliveryOption == 'home',
                        showSelectionCircle: true,
                        onTap: () {
                          setState(() {
                            _selectedDeliveryOption = 'home';
                            _selectedRelayPoint = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenWidth * 0.06),

                // Section Détails de la livraison (point relais)
                if (_selectedDeliveryOption == 'relay') ...[
                  SelectionTile(
                    label: 'Détails de la livraison',
                    value: _selectedRelayPoint,
                    placeholder: 'Choisir un point relais',
                    isRequired: true,
                    onTap: () async {
                      final result = await context.push('/relay-point/select');
                      if (result != null && result is Map) {
                        setState(() {
                          _selectedRelayPoint = result['name'] as String?;
                        });
                      }
                    },
                  ),
                  SizedBox(height: screenWidth * 0.06),
                ],
              ],

              // Section Mode de Paiement (Toujours affichée)
              SelectionTile(
                label: 'Mode de paiement',
                value: _selectedPaymentMethod != null
                    ? _getPaymentMethodLabel(_selectedPaymentMethod!) +
                        (_paymentPhoneNumber != null
                            ? ' ($_paymentPhoneNumber)'
                            : '')
                    : null,
                placeholder: 'Sélectionne un mode de paiement',
                isRequired: true,
                onTap: () async {
                  final result = await context.push('/payment-method/select');
                  if (result != null && result is Map<String, dynamic>) {
                    setState(() {
                      _selectedPaymentMethod = result['method'] as String?;
                      _paymentPhoneNumber = result['phoneNumber'] as String?;
                    });
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
                        'Total à payer',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_totalAmount.toStringAsFixed(0)} FCFA',
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
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
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
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
