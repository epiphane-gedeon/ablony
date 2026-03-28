import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../../shared/widgets/choice_card_widget.dart';
import '../../../../shared/widgets/selection_tile.dart';
import '../../../product/domain/entities/product.dart';

/// Page de paiement pour finaliser un achat
class PaymentPage extends ConsumerStatefulWidget {
  final Product product;

  const PaymentPage({super.key, required this.product});

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

  // Calcul des frais
  double get _protectionFees => widget.product.price * 0.05; // 5% de protection
  double get _shippingCost =>
      _selectedDeliveryOption == 'relay' ? 1000.0 : 1500.0; // FCFA
  double get _totalAmount =>
      widget.product.price + _protectionFees + _shippingCost;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.35; // 35% de la largeur de l'écran

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement'), centerTitle: true),
      body: Stack(
        children: [
          // Contenu avec scroll
          ListView(
            padding: const EdgeInsets.only(
              bottom: 100,
            ), // Espace pour le bouton
            children: [
              // Informations du produit
              Container(
                margin: EdgeInsets.all(screenWidth * 0.04),
                padding: EdgeInsets.all(screenWidth * 0.03),
                child: Row(
                  children: [
                    // Image du produit
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: widget.product.imageUrls.isNotEmpty
                          ? Image.network(
                              widget.product.imageUrls.first,
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

                    // Détails du produit
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.product.condition.label,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.product.price.toStringAsFixed(0)} FCFA',
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

              // Section Adresse
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
                      subTitle: 'à partir de ${1000.toStringAsFixed(0)} FCFA',
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
                      subTitle: '${1500.toStringAsFixed(0)} FCFA',
                      icon: Icons.home_outlined,
                      isSelected: _selectedDeliveryOption == 'home',
                      showSelectionCircle: true,
                      onTap: () {
                        setState(() {
                          _selectedDeliveryOption = 'home';
                          // Réinitialiser le point relais car non applicable
                          _selectedRelayPoint = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenWidth * 0.06),

              // Section Détails de la livraison
              if (_selectedDeliveryOption == 'relay')
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

              if (_selectedDeliveryOption == 'relay')
                SizedBox(height: screenWidth * 0.06),

              // Section Paiement
              SelectionTile(
                label: 'Paiement',
                value: _selectedPaymentMethod != null
                    ? _getPaymentMethodLabel(_selectedPaymentMethod!)
                    : null,
                placeholder: 'Sélectionne un mode de paiement',
                isRequired: true,
                onTap: () async {
                  final selectedMethod = await context.push(
                    '/payment-method/select',
                  );
                  if (selectedMethod != null && selectedMethod is String) {
                    setState(() {
                      _selectedPaymentMethod = selectedMethod;
                    });
                  }
                },
              ),

              SizedBox(height: screenWidth * 0.06),

              // Section Prix
              _buildSection(
                context,
                title: 'Prix',
                child: Column(
                  children: [
                    _buildPriceRow(
                      'Commande',
                      '${widget.product.price.toStringAsFixed(0)} FCFA',
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
                  ],
                ),
              ),

              SizedBox(height: screenWidth * 0.04),
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
                    text: 'Payer',
                    onPressed: () {
                      // TODO: Traiter le paiement
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Traitement du paiement...'),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: screenWidth * 0.02),

                  // Message de sécurité
                  Flexible(
                    child: Row(
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
                            'Tes informations de paiement sont chiffrées et sécurisées',
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
