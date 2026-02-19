import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../../shared/widgets/choice_card_widget.dart';
import '../../../../shared/widgets/selection_option.dart';

/// Page de paiement pour finaliser un achat
class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  // Options de livraison
  String _selectedDeliveryOption = 'relay'; // 'relay' ou 'home'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.25; // 25% de la largeur de l'écran

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
                      child: Container(
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
                          const Text(
                            'Tricot noir',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'S',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '2,00 €',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '1,00 €',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Section Adresse
              _buildSection(
                context,
                title: 'Adresse',
                child: SelectionOption(
                  label: 'Ajouter l\'adresse de livraison',
                  trailingIcon: SelectionOptionIcon.plus,
                  onTap: () {
                    // TODO: Naviguer vers la page d'ajout d'adresse
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ajout d\'adresse à venir')),
                    );
                  },
                ),
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
                      subTitle: 'à partir de 3,28 €',
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
                      subTitle: '4,59 €',
                      icon: Icons.home_outlined,
                      isSelected: _selectedDeliveryOption == 'home',
                      showSelectionCircle: true,
                      onTap: () {
                        setState(() {
                          _selectedDeliveryOption = 'home';
                        });
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenWidth * 0.06),

              // Section Détails de la livraison
              if (_selectedDeliveryOption == 'relay')
                _buildSection(
                  context,
                  title: 'Détails de la livraison',
                  child: SelectionOption(
                    label: 'Choisir un point relais',
                    trailingIcon: SelectionOptionIcon.plus,
                    onTap: () {
                      // TODO: Naviguer vers la sélection de point relais
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sélection du point relais à venir'),
                        ),
                      );
                    },
                  ),
                ),

              if (_selectedDeliveryOption == 'relay')
                SizedBox(height: screenWidth * 0.06),

              // Section Paiement
              _buildSection(
                context,
                title: 'Paiement',
                child: SelectionOption(
                  label: 'Sélectionne un mode de paiement',
                  trailingIcon: SelectionOptionIcon.plus,
                  onTap: () {
                    // TODO: Naviguer vers la sélection du mode de paiement
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sélection du mode de paiement à venir'),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: screenWidth * 0.06),

              // Section Prix
              _buildSection(
                context,
                title: 'Prix',
                child: Column(
                  children: [
                    _buildPriceRow('Commande', '2,00 €'),
                    SizedBox(height: screenWidth * 0.03),
                    _buildPriceRow(
                      'Frais de Protection acheteurs',
                      '0,80 €',
                      hasInfo: true,
                    ),
                    SizedBox(height: screenWidth * 0.03),
                    _buildPriceRow('Frais de port', '3,28 €'),
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
                        '6,08 €',
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
